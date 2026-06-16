#!/bin/sh
# 概要: team-dev-kit インストーラ。チーム開発の契約(AGENTS.md)・手続き(skills)・秘密情報ガードレール
#       (pre-commit / PreToolUse フック)を、対象プロジェクトに冪等に導入する。
#       新規プロジェクト=素の書き込み、既存プロジェクト=非破壊マージ を自動判別する。
#       同梱 assets/ を対象リポジトリのルート（カレントディレクトリ）にコピーする。
# 使い方: cd <target-repo> && /path/to/install.sh [--dry-run] [--force]
#         curl 経由は bootstrap.sh を参照。
# フラグ: --dry-run 変更内容だけ表示し書き込まない / --force 既存ファイルを上書き / --help
set -eu

FORCE=0
DRY=0
for a in "$@"; do
  case "$a" in
    --force) FORCE=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help)
      echo "team-dev-kit installer"
      echo "usage: cd <target-repo> && install.sh [--dry-run] [--force]"
      exit 0 ;;
    *) echo "unknown flag: $a" >&2; exit 2 ;;
  esac
done

# assets はこのスクリプトと同じ場所の assets/
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ASSETS="$SCRIPT_DIR/assets"
[ -d "$ASSETS" ] || { echo "✋ assets/ が見つかりません: $ASSETS" >&2; exit 1; }

# 対象はカレントディレクトリ（リポジトリルート想定）
TARGET=$(pwd)
say() { printf '%s\n' "$*"; }
act() { [ "$DRY" -eq 1 ] && printf '  [dry-run] %s\n' "$*" || printf '  %s\n' "$*"; }

# --- preflight ---------------------------------------------------------------
say "== team-dev-kit install =="
say "target: $TARGET"
[ "$DRY" -eq 1 ] && say "(dry-run: 変更しません)"

if ! git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "✋ ここは git リポジトリではありません。先に git init してください。" >&2
  exit 1
fi

MISSING=""
command -v gitleaks  >/dev/null 2>&1 || MISSING="$MISSING gitleaks"
command -v python3   >/dev/null 2>&1 || MISSING="$MISSING python3"
if [ -n "$MISSING" ]; then
  say ""
  say "⚠ 依存が未インストール:$MISSING"
  say "   gitleaks: brew install gitleaks   python3: brew install python"
  say "   （フックは導入されますが、未インストールだとコミット/発行時に停止します）"
fi

# --- helpers -----------------------------------------------------------------
# copy_file <src-rel> [exec]   既存はスキップ（--force で上書き）
copy_file() {
  rel="$1"; ex="${2:-}"
  src="$ASSETS/$rel"; dst="$TARGET/$rel"
  if [ -e "$dst" ] && [ "$FORCE" -eq 0 ]; then
    act "skip (exists): $rel"
    return
  fi
  if [ "$DRY" -eq 1 ]; then act "copy: $rel${ex:+ (+x)}"; return; fi
  mkdir -p "$(dirname -- "$dst")"
  cp "$src" "$dst"
  [ -n "$ex" ] && chmod +x "$dst"
  act "copy: $rel${ex:+ (+x)}"
}

# --- 1. skills（skill 単位でスキップ） --------------------------------------
say ""
say "1) skills -> .claude/skills/"
for d in "$ASSETS"/.claude/skills/*/; do
  name=$(basename "$d")
  dst="$TARGET/.claude/skills/$name"
  if [ -e "$dst" ] && [ "$FORCE" -eq 0 ]; then act "skip (exists): $name"; continue; fi
  if [ "$DRY" -eq 1 ]; then act "copy skill: $name"; continue; fi
  mkdir -p "$TARGET/.claude/skills"
  rm -rf "$dst"; cp -R "$d" "$dst"
  act "copy skill: $name"
done

# --- 2. 秘密情報ガードレール ------------------------------------------------
say ""
say "2) secret-scan guardrails"
copy_file ".githooks/pre-commit" x
copy_file "scripts/egress-scan.sh" x
copy_file ".gitleaks.toml"

# git core.hooksPath（pre-commit を有効化する per-repo 設定）
CUR=$(git -C "$TARGET" config --local core.hooksPath 2>/dev/null || true)
if [ -z "$CUR" ]; then
  if [ "$DRY" -eq 1 ]; then act "git config core.hooksPath .githooks"; else
    git -C "$TARGET" config --local core.hooksPath .githooks
    act "git config core.hooksPath .githooks"
  fi
elif [ "$CUR" = ".githooks" ]; then
  act "core.hooksPath = .githooks (already)"
else
  say "  ⚠ core.hooksPath は既に '$CUR'。上書きしません。"
  say "    手動対応: $CUR にある既存フックから .githooks/pre-commit を呼ぶか、husky 等に統合してください。"
fi

# --- 3. GitHub テンプレ + 設計ドキュメント ----------------------------------
say ""
say "3) github templates + docs"
copy_file ".github/ISSUE_TEMPLATE/bug.md"
copy_file ".github/ISSUE_TEMPLATE/docs.md"
copy_file ".github/ISSUE_TEMPLATE/feature.md"
copy_file ".github/ISSUE_TEMPLATE/config.yml"
copy_file ".github/PULL_REQUEST_TEMPLATE.md"
copy_file "docs/secret-scan.md"

# --- 4. AGENTS.md（契約。既存は壊さない） -----------------------------------
say ""
say "4) AGENTS.md contract"
if [ ! -e "$TARGET/AGENTS.md" ]; then
  copy_file "AGENTS.md"
else
  if [ "$DRY" -eq 1 ]; then act "write AGENTS.kit-sample.md (既存 AGENTS.md は保持)"; else
    cp "$ASSETS/AGENTS.md" "$TARGET/AGENTS.kit-sample.md"
    act "既存 AGENTS.md 検出 -> 雛形を AGENTS.kit-sample.md に出力。手動マージしてください。"
  fi
fi

# --- 5. .claude/settings.json（フック設定。マージ） -------------------------
say ""
say "5) .claude/settings.json (hooks)"
FRAG="$ASSETS/.claude/settings.json"
DST="$TARGET/.claude/settings.json"
if [ ! -e "$DST" ]; then
  copy_file ".claude/settings.json"
elif command -v python3 >/dev/null 2>&1; then
  if [ "$DRY" -eq 1 ]; then act "merge hooks into existing settings.json"; else
    python3 - "$DST" "$FRAG" <<'PY'
import json, sys
dst, frag = sys.argv[1], sys.argv[2]
with open(dst, encoding="utf-8") as f: cur = json.load(f)
with open(frag, encoding="utf-8") as f: add = json.load(f)
cur.setdefault("hooks", {})
for event, entries in add.get("hooks", {}).items():
    lst = cur["hooks"].setdefault(event, [])
    # 既存 command と重複しないものだけ追加（冪等）
    existing = {h.get("command") for e in lst for h in e.get("hooks", [])}
    for e in entries:
        cmds = {h.get("command") for h in e.get("hooks", [])}
        if cmds & existing:
            continue
        lst.append(e)
with open(dst, "w", encoding="utf-8") as f:
    json.dump(cur, f, ensure_ascii=False, indent=2); f.write("\n")
print("  merged hooks into existing settings.json")
PY
  fi
else
  say "  ⚠ python3 が無いため settings.json をマージできません。"
  say "    手動で hooks.PreToolUse に egress-scan.sh を追加してください（雛形: $FRAG）。"
fi

# --- done --------------------------------------------------------------------
say ""
if [ "$DRY" -eq 1 ]; then
  say "✅ dry-run 完了。実際に導入するには --dry-run を外して再実行してください。"
else
  say "✅ team-dev-kit 導入完了。"
  say "   次の一歩: AGENTS.md を読み、git commit を試す（pre-commit が走ることを確認）。"
fi
