#!/bin/sh
# 概要: team-dev-kit の最小ブートストラップ・インストーラ。
#       チーム開発の skill(振る舞い指示)と秘密情報ガードレール(pre-commit / PreToolUse フック)を、
#       既定では「対象プロジェクト配下」だけに配置する。--global を明示したときのみ skill を $HOME 配下に置く。
#       これにより他プロジェクトへ干渉しないのが default になる。
#
# 使い方:
#   # 対象リポジトリの中で（プロジェクトローカル導入）
#   curl -fsSL https://raw.githubusercontent.com/aRaikoFunakami/team-dev-kit/main/bootstrap.sh | sh
#
#   # skill を $HOME 配下に入れて全プロジェクトで使う（明示的グローバル）
#   curl -fsSL https://raw.githubusercontent.com/aRaikoFunakami/team-dev-kit/main/bootstrap.sh | sh -s -- --global
#
# フラグ:
#   --global        skill / egress スクリプト / PreToolUse フックを ~/.claude 配下へ（既定はプロジェクト配下）
#   --dry-run       変更内容だけ表示して書き込まない
#   --force         既存の config / skill を上書きする
#   --ref <ref>     取得する git ref（既定: main）
#   --repo <slug>   取得元リポジトリ（既定: aRaikoFunakami/team-dev-kit）
#   --src <path>    clone せずローカルの team-dev-kit チェックアウトから取得（開発/検証用）
#   -h | --help
set -eu

REPO="aRaikoFunakami/team-dev-kit"
REF="main"
SRC=""
GLOBAL=0
DRY=0
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --global)  GLOBAL=1 ;;
    --dry-run) DRY=1 ;;
    --force)   FORCE=1 ;;
    --ref)     REF="${2:?--ref needs a value}"; shift ;;
    --repo)    REPO="${2:?--repo needs a value}"; shift ;;
    --src)     SRC="${2:?--src needs a value}"; shift ;;
    -h|--help)
      sed -n '2,30p' "$0" 2>/dev/null || echo "team-dev-kit bootstrap"
      exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
  shift
done

say() { printf '%s\n' "$*"; }
act() { [ "$DRY" -eq 1 ] && printf '  [dry-run] %s\n' "$*" || printf '  %s\n' "$*"; }
die() { printf '✋ %s\n' "$*" >&2; exit 1; }

# --- 取得元の用意 -------------------------------------------------------------
# SRC 未指定なら shallow clone して temp に取得。プラグイン本体は plugins/team-dev-kit/。
CLEANUP=""
if [ -n "$SRC" ]; then
  [ -d "$SRC/plugins/team-dev-kit" ] || die "--src に plugins/team-dev-kit がありません: $SRC"
  PLUGIN="$SRC/plugins/team-dev-kit"
else
  command -v git >/dev/null 2>&1 || die "git が必要です。"
  TMP=$(mktemp -d 2>/dev/null || mktemp -d -t tdk)
  CLEANUP="$TMP"
  say "== fetch $REPO@$REF =="
  git clone --depth 1 --branch "$REF" "https://github.com/$REPO.git" "$TMP" >/dev/null 2>&1 \
    || die "clone 失敗: https://github.com/$REPO.git@$REF"
  PLUGIN="$TMP/plugins/team-dev-kit"
fi
cleanup() { [ -n "$CLEANUP" ] && rm -rf "$CLEANUP"; return 0; }
trap cleanup EXIT INT TERM

# --- 配置先の決定 -------------------------------------------------------------
# B層（ガードレール本体）は常にプロジェクト配下（リポジトリに commit されないと意味がない）。
# skill / egress は default=プロジェクト配下、--global=~/.claude 配下。
TARGET=$(pwd)
PROJECT_IS_GIT=0
if git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  PROJECT_IS_GIT=1
  TARGET=$(git -C "$TARGET" rev-parse --show-toplevel)
fi

if [ "$GLOBAL" -eq 1 ]; then
  SKILL_DEST="$HOME/.claude/skills"
  EGRESS_DEST="$HOME/.claude/team-dev-kit/egress-scan.sh"
  SETTINGS_DEST="$HOME/.claude/settings.json"
  EGRESS_CMD_PATH="$HOME/.claude/team-dev-kit/egress-scan.sh"
else
  [ "$PROJECT_IS_GIT" -eq 1 ] || die "ここは git リポジトリではありません。先に git init するか、全プロジェクト用なら --global を付けてください。"
  SKILL_DEST="$TARGET/.claude/skills"
  EGRESS_DEST="$TARGET/.team-dev-kit/egress-scan.sh"
  SETTINGS_DEST="$TARGET/.claude/settings.json"
  # フック実行時に CLAUDE_PROJECT_DIR が指す先からの相対で解決する
  EGRESS_CMD_PATH='$CLAUDE_PROJECT_DIR/.team-dev-kit/egress-scan.sh'
fi

say "== team-dev-kit bootstrap =="
say "mode:   $([ "$GLOBAL" -eq 1 ] && echo 'global (~/.claude)' || echo 'project-local')"
say "target: $TARGET"
[ "$DRY" -eq 1 ] && say "(dry-run: 変更しません)"

# --- 依存チェック（致命ではない） --------------------------------------------
MISSING=""
command -v gitleaks >/dev/null 2>&1 || MISSING="$MISSING gitleaks"
command -v python3  >/dev/null 2>&1 || MISSING="$MISSING python3"
if [ -n "$MISSING" ]; then
  say "⚠ 依存が未インストール:$MISSING（brew install gitleaks / python3。フックは入るが未導入だと commit/発行時に停止します）"
fi

# --- helpers -----------------------------------------------------------------
# copy_file <src-abs> <dst-abs> [exec]   framework/skill/egress: 既存は --force で上書き
copy_file() {
  src="$1"; dst="$2"; ex="${3:-}"
  rel=${dst#"$TARGET"/}
  if [ -e "$dst" ] && [ "$FORCE" -eq 0 ]; then act "skip (exists): $rel"; return; fi
  if [ "$DRY" -eq 1 ]; then act "write: $rel${ex:+ (+x)}"; return; fi
  mkdir -p "$(dirname -- "$dst")"
  cp "$src" "$dst"
  [ -n "$ex" ] && chmod +x "$dst"
  act "write: $rel${ex:+ (+x)}"
}

# copy_config <src-abs> <dst-abs>   config: install-once。既存は常に残す（--force でも上書きしない）。
# プロジェクト所有のファイル（AGENTS.md 等）の手編集を更新（再実行）で壊さないため。
copy_config() {
  src="$1"; dst="$2"
  rel=${dst#"$TARGET"/}
  if [ -e "$dst" ]; then act "keep (config exists): $rel"; return; fi
  if [ "$DRY" -eq 1 ]; then act "write: $rel"; return; fi
  mkdir -p "$(dirname -- "$dst")"
  cp "$src" "$dst"
  act "write: $rel"
}

# ensure_glue <agents|gitleaks> <src-abs> <dst-abs>
#   config を install-once しつつ、既存ファイルには team-dev-kit を繋ぐ glue を冪等注入する:
#     - AGENTS.md   : `@.team-dev-kit/contract.md`（共通契約 import）
#     - .gitleaks.toml: `[extend] path=".team-dev-kit/base.gitleaks.toml"`（base 検出ルール継承）
#   glue が無いまま既存ファイルを温存すると、秘密ガードや共通契約が黙って効かなくなるため必須。
ensure_glue() {
  kind="$1"; src="$2"; dst="$3"
  rel=${dst#"$TARGET"/}
  if [ ! -e "$dst" ]; then copy_config "$src" "$dst"; return; fi
  # 既存あり → glue の有無を判定し、無ければ注入
  if command -v python3 >/dev/null 2>&1; then
    DRY="$DRY" KIND="$kind" REL="$rel" python3 - "$dst" <<'PY'
import os, sys, re
dst = sys.argv[1]; kind = os.environ["KIND"]; rel = os.environ["REL"]
dry = os.environ.get("DRY") == "1"
text = open(dst, encoding="utf-8").read()
def act(msg): print(("  [dry-run] " if dry else "  ") + msg)
if kind == "agents":
    if "@.team-dev-kit/contract.md" in text:
        act(f"keep (glue present): {rel}"); sys.exit(0)
    block = ("<!-- team-dev-kit: 共通契約を import（この行は編集しない） -->\n"
             "@.team-dev-kit/contract.md\n\n")
    if not dry:
        open(dst, "w", encoding="utf-8").write(block + text)
    act(f"inject @import glue (既存 AGENTS.md は保持): {rel}")
elif kind == "gitleaks":
    if "base.gitleaks.toml" in text:
        act(f"keep (glue present): {rel}"); sys.exit(0)
    if re.search(r'(?m)^\s*\[extend\]', text):
        act(f"⚠ 既存 [extend] あり・base 未継承: {rel} → 手動で path=\".team-dev-kit/base.gitleaks.toml\" を追加してください")
        sys.exit(0)
    # 末尾に append する（先頭 prepend だと後続のルート鍵が [extend] テーブルに吸収され TOML が壊れるため）。
    block = ('\n# team-dev-kit: base 検出ルールを継承（この3行は編集しない）\n'
             '[extend]\n'
             'path = ".team-dev-kit/base.gitleaks.toml"\n')
    if not dry:
        open(dst, "w", encoding="utf-8").write((text if text.endswith("\n") else text + "\n") + block)
    act(f"inject [extend] base glue (既存ルールは保持): {rel}")
PY
  else
    say "  ⚠ python3 が無いため $rel に glue を注入できません。手動で確認してください。"
  fi
}

# --- 1. skill（業務 skill のみ・plugin の skills/ を動的列挙） ----------------
# kit-* skill は ${CLAUDE_PLUGIN_ROOT} 依存（plugin 専用）なので除外する。
# 固定リストにすると plugin への skill 追加を黙って取りこぼすため走査で拾う。
say ""
say "1) skills -> $SKILL_DEST"
copied_any=0
for s in "$PLUGIN"/skills/*/; do
  [ -d "$s" ] || continue
  name=$(basename "$s")
  case "$name" in kit-*) continue ;; esac   # plugin 専用 skill は配らない
  [ -f "$s/SKILL.md" ] || { act "skip (no SKILL.md): $name"; continue; }
  copied_any=1
  d="$SKILL_DEST/$name"
  if [ -e "$d" ] && [ "$FORCE" -eq 0 ]; then act "skip (exists): $name"; continue; fi
  if [ "$DRY" -eq 1 ]; then act "copy skill: $name"; continue; fi
  mkdir -p "$SKILL_DEST"; rm -rf "$d"; cp -R "$s" "$d"
  act "copy skill: $name"
done
[ "$copied_any" -eq 0 ] && say "  ⚠ 配布対象の業務 skill が見つかりません: $PLUGIN/skills/"

# --- 2. egress スクリプト + PreToolUse フック --------------------------------
say ""
say "2) egress guard (PreToolUse)"
copy_file "$PLUGIN/scripts/egress-scan.sh" "$EGRESS_DEST" x

# settings.json に PreToolUse フックを冪等マージ
if [ "$DRY" -eq 1 ]; then
  act "merge PreToolUse hook -> ${SETTINGS_DEST#"$TARGET"/}"
elif command -v python3 >/dev/null 2>&1; then
  mkdir -p "$(dirname -- "$SETTINGS_DEST")"
  CMD="$EGRESS_CMD_PATH" python3 - "$SETTINGS_DEST" <<'PY'
import json, os, sys
dst = sys.argv[1]
cmd = os.environ["CMD"]
cur = {}
if os.path.exists(dst) and os.path.getsize(dst) > 0:
    try:
        with open(dst, encoding="utf-8") as f:
            cur = json.load(f)
        if not isinstance(cur, dict):
            raise ValueError("top-level is not an object")
    except Exception as e:
        # 既存 settings.json が壊れている/空 → 上書きで壊さず、フック追記だけ安全にスキップ。
        # 導入を途中で止めない（fail-safe）。
        print(f"  ⚠ {dst} を解析できません（{e}）。PreToolUse フックの追記をスキップします。")
        print(f"    手動で hooks.PreToolUse に command を追加してください: {cmd}")
        sys.exit(0)
hooks = cur.setdefault("hooks", {})
pre = hooks.setdefault("PreToolUse", [])
if not isinstance(pre, list):
    print(f"  ⚠ hooks.PreToolUse が配列ではありません。追記をスキップします。手動追加: {cmd}")
    sys.exit(0)
existing = {h.get("command") for e in pre if isinstance(e, dict) for h in e.get("hooks", []) if isinstance(h, dict)}
if cmd not in existing:
    pre.append({"matcher": "Bash", "hooks": [{"type": "command", "command": cmd}]})
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(cur, f, ensure_ascii=False, indent=2); f.write("\n")
    print("  merged PreToolUse egress hook")
else:
    print("  PreToolUse egress hook already present")
PY
else
  say "  ⚠ python3 が無いため settings.json をマージできません。手動で PreToolUse に $EGRESS_CMD_PATH を追加してください。"
fi

# --- 3. B層: framework（共通・編集禁止） + config（プロジェクト所有） --------
# B層は常にプロジェクト配下。--global でも commit ガードレールはリポジトリに置く。
if [ "$PROJECT_IS_GIT" -eq 1 ]; then
  say ""
  say "3) guardrails -> $TARGET (framework + config)"
  copy_file "$PLUGIN/framework/contract.md"        "$TARGET/.team-dev-kit/contract.md"
  copy_file "$PLUGIN/framework/base.gitleaks.toml" "$TARGET/.team-dev-kit/base.gitleaks.toml"
  copy_file "$PLUGIN/framework/pre-commit"         "$TARGET/.githooks/pre-commit" x
  ensure_glue agents   "$PLUGIN/config-starters/AGENTS.md"     "$TARGET/AGENTS.md"
  ensure_glue gitleaks "$PLUGIN/config-starters/gitleaks.toml" "$TARGET/.gitleaks.toml"
  for f in "$PLUGIN"/config-starters/github/ISSUE_TEMPLATE/*; do
    [ -e "$f" ] && copy_config "$f" "$TARGET/.github/ISSUE_TEMPLATE/$(basename "$f")"
  done
  copy_config "$PLUGIN/config-starters/github/PULL_REQUEST_TEMPLATE.md" "$TARGET/.github/PULL_REQUEST_TEMPLATE.md"

  # core.hooksPath（pre-commit を有効化する per-repo 設定）
  CUR=$(git -C "$TARGET" config --local core.hooksPath 2>/dev/null || true)
  if [ -z "$CUR" ]; then
    if [ "$DRY" -eq 1 ]; then act "git config core.hooksPath .githooks"; else
      git -C "$TARGET" config --local core.hooksPath .githooks; act "git config core.hooksPath .githooks"; fi
  elif [ "$CUR" = ".githooks" ]; then
    act "core.hooksPath = .githooks (already)"
  else
    say "  ⚠ core.hooksPath は既に '$CUR'。上書きしません。.githooks/pre-commit を手動統合してください。"
  fi
elif [ "$GLOBAL" -eq 1 ]; then
  say ""
  say "3) guardrails: skip（git リポジトリ外。commit ガードレールは各 repo で --global なしで実行してください）"
fi

# --- done --------------------------------------------------------------------
say ""
if [ "$DRY" -eq 1 ]; then
  say "✅ dry-run 完了。実際に導入するには --dry-run を外して再実行してください。"
else
  say "✅ team-dev-kit bootstrap 完了。"
  if [ "$GLOBAL" -eq 1 ]; then
    say "   skill は $SKILL_DEST に入りました（全プロジェクトで有効）。"
  else
    say "   このプロジェクト配下のみに導入しました（他プロジェクトに影響しません）。"
    say "   次の一歩: 配置ファイルを feature ブランチで commit → PR。git commit で pre-commit が走ることを確認。"
  fi
fi
