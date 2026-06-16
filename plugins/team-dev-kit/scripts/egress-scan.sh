#!/bin/sh
# 概要: Claude Code PreToolUse フック(L3)。Bash で `gh issue create` / `gh pr create` を実行する直前に、
#       実際にアップロードされる本文だけ（--title / --body の値、--body-file の中身）を gitleaks で走査し、
#       秘密情報・個人情報を含む場合は exit 2 で実行を拒否する。
#       gitignore された下書きは git 履歴を通らず pre-commit(L1) では捕捉できないため、この経路を塞ぐ唯一の層。
# 設計: instructions/secret-scan.md。設定は .gitleaks.toml を共有する。
# 注意: コマンド行全体は走査しない。cwd や --body-file の絶対パスにはローカルのホームパス
#       （実ユーザー名）が当然含まれるが、それらはアップロードされないため対象外にする（誤検知回避）。
#       --body 系の指定が無い gh create（テンプレ/コミットから本文生成）は本文を特定できず素通りする。
#       その経路のコミット内容は L1(pre-commit) が守る。
set -eu

root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
config="$root/.gitleaks.toml"
scandir="$(mktemp -d)"
input_json="$(mktemp)"
trap 'rm -rf "$scandir" "$input_json"' EXIT

# フック入力(PreToolUse JSON)を退避する。scandir には走査対象だけを置きたいので別ファイルにする
# （入力 JSON はコマンド行=ローカルパスを含み、走査すると誤検知するため scandir に入れない）。
cat > "$input_json"

# 入力 JSON を解析し、走査対象（アップロード本文）だけを scandir/payload.txt に書き出す。
# 対象なら "SCAN"、それ以外は "SKIP" を返す。プログラムは heredoc(stdin)、データは argv で渡す。
decision="$(python3 - "$scandir" "$input_json" <<'PY'
import sys, os, json, re, shlex

scandir = sys.argv[1]
try:
    with open(sys.argv[2], encoding="utf-8") as f:
        d = json.load(f)
except Exception:
    print("SKIP"); sys.exit(0)

if d.get("tool_name") != "Bash":
    print("SKIP"); sys.exit(0)

cmd = d.get("tool_input", {}).get("command", "")
# gh issue create / gh pr create のみ対象
if not re.search(r"\bgh\b.*\b(issue|pr)\b.*\bcreate\b", cmd):
    print("SKIP"); sys.exit(0)

# gh create と判定した後で解析に失敗したら、本文を取りこぼして素通りさせない（fail-closed）。
# crude な split にフォールバックすると --body の値を落として走査漏れ＝流出につながるため拒否する。
try:
    toks = shlex.split(cmd)
except Exception:
    print("DENY"); sys.exit(0)

pieces = []

def add_file(path):
    if os.path.isfile(path):
        try:
            pieces.append(open(path, encoding="utf-8", errors="replace").read())
        except Exception:
            pass

i = 0
n = len(toks)
while i < n:
    t = toks[i]
    if t in ("--title", "-t", "--body", "-b"):
        if i + 1 < n:
            pieces.append(toks[i + 1]); i += 2; continue
    elif t.startswith("--title=") or t.startswith("--body="):
        pieces.append(t.split("=", 1)[1])
    elif t in ("--body-file", "-F"):
        if i + 1 < n:
            add_file(toks[i + 1]); i += 2; continue
    elif t.startswith("--body-file="):
        add_file(t.split("=", 1)[1])
    i += 1

if not pieces:
    print("SKIP"); sys.exit(0)

with open(os.path.join(scandir, "payload.txt"), "w", encoding="utf-8") as w:
    w.write("\n".join(pieces))
print("SCAN")
PY
)"

if [ "$decision" = "DENY" ]; then
  echo "✋ gh コマンドの本文を解析できませんでした（クォート不整合など）。安全側に倒して送信を拒否します。" >&2
  echo "   コマンドを修正して再実行してください。" >&2
  exit 2
fi

[ "$decision" = "SCAN" ] || exit 0

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "✋ gitleaks 未インストールのためアップロード前スキャンができません。brew install gitleaks 後に再実行してください。" >&2
  exit 2
fi

if ! gitleaks detect --no-git --source "$scandir" --no-banner --redact -c "$config"; then
  echo "" >&2
  echo "✋ アップロード予定の本文に秘密情報または個人情報の疑いを検出しました。送信を拒否します。" >&2
  echo "   対応: Issue/PR の本文や下書きから該当箇所を削除・マスキング・匿名化してください。" >&2
  echo "   誤検知の場合: .gitleaks.toml の [allowlist] に例示値を追加してください。" >&2
  exit 2
fi

exit 0
