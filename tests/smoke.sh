#!/bin/sh
# 概要: team-dev-kit(v2: framework/config 分離)のスモークテスト。manifest・egress フック・
#       kit-sync の init/doctor/update/contribute を scratch リポジトリで一気通貫に検証する。
#       framework=置換管理・config=install-once・gitleaks overlay→base 継承・@import 連鎖を確認。
#       real リポジトリは汚さない(update テストは kit を複製して version を上げる)。
# 使い方: sh tests/smoke.sh   (kit リポジトリのルートから)。全合格で 0、失敗で 1。
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PLUGIN="$ROOT/plugins/team-dev-kit"
SYNC="$PLUGIN/scripts/kit-sync.py"
EG="$PLUGIN/scripts/egress-scan.sh"
FIX="$ROOT/tests/fixtures"
pass=0; fail=0
ok() { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
ng() { fail=$((fail+1)); printf '  NG   %s\n' "$1"; }
chk() { if eval "$2"; then ok "$1"; else ng "$1"; fi; }

echo "== 1. manifest JSON 妥当性 =="
for f in "$ROOT/.claude-plugin/marketplace.json" "$PLUGIN/.claude-plugin/plugin.json" "$PLUGIN/hooks/hooks.json"; do
  chk "valid: ${f#$ROOT/}" "python3 -c 'import json,sys;json.load(open(sys.argv[1]))' '$f' >/dev/null 2>&1"
done

echo "== 2. init (fresh) =="
T=$(mktemp -d); mkdir -p "$T/f"; (cd "$T/f" && git init -q)
python3 "$SYNC" init --target "$T/f" >/dev/null
hp=$(git -C "$T/f" config --local core.hooksPath || true)
chk "framework: contract.md"      "[ -f '$T/f/.team-dev-kit/contract.md' ]"
chk "framework: base.gitleaks"    "[ -f '$T/f/.team-dev-kit/base.gitleaks.toml' ]"
chk "framework: pre-commit(+x)"   "[ -x '$T/f/.githooks/pre-commit' ]"
chk "config: AGENTS.md"           "[ -f '$T/f/AGENTS.md' ]"
chk "config: .gitleaks.toml"      "[ -f '$T/f/.gitleaks.toml' ]"
chk "config: .github テンプレ"    "[ -f '$T/f/.github/PULL_REQUEST_TEMPLATE.md' ]"
chk "lock 生成"                   "[ -f '$T/f/.team-dev-kit.lock' ]"
chk "hooksPath=.githooks"         "[ '$hp' = .githooks ]"
chk "@import 連鎖(AGENTS→contract)" "grep -q '@.team-dev-kit/contract.md' '$T/f/AGENTS.md'"
chk "overlay extends base"        "grep -q '.team-dev-kit/base.gitleaks.toml' '$T/f/.gitleaks.toml'"

echo "== 3. doctor (clean) =="
chk "doctor exit0" "python3 '$SYNC' doctor --target '$T/f' >/dev/null"

echo "== 4. gitleaks overlay -> base 継承 =="
S=$(mktemp -d); cp "$FIX/gitleaks-sample.txt" "$S/x.txt"   # 検体: base 検出される私的IP + base allowlist 済の例示IP
n_leak=0
( cd "$T/f" && gitleaks detect --no-git --source "$S" --no-banner --redact -c "$T/f/.gitleaks.toml" ) >/dev/null 2>&1 || n_leak=$?
chk "base ルール継承で 1 件検出(exit1)" "[ '$n_leak' = 1 ]"

echo "== 5. egress フック(overlay 経由) =="
egress() { rc=0; CLAUDE_PROJECT_DIR="$T/f" sh "$EG" <"$1" >/dev/null 2>&1 || rc=$?; echo "$rc"; }
rc_pii=$(egress "$FIX/egress-pii.json"); rc_clean=$(egress "$FIX/egress-clean.json"); rc_skip=$(egress "$FIX/egress-skip.json")
chk "PII を block(exit2)"   "[ $rc_pii = 2 ]"
chk "clean を素通り(exit0)" "[ $rc_clean = 0 ]"
chk "非gh を素通り(exit0)"  "[ $rc_skip = 0 ]"

echo "== 6. config install-once(再 init で非 clobber) =="
printf '\n## 固有追記\n' >> "$T/f/AGENTS.md"
python3 "$SYNC" init --target "$T/f" >/dev/null
chk "AGENTS.md のローカル追記を保持" "grep -q '固有追記' '$T/f/AGENTS.md'"

echo "== 7. framework drift 検出 =="
printf '\n# local edit\n' >> "$T/f/.team-dev-kit/contract.md"
chk "doctor が framework DRIFTED 報告" "python3 '$SYNC' doctor --target '$T/f' | grep -q 'DRIFTED'"

echo "== 8. update(framework 置換 / config 不可侵 / drift skip) =="
KN=$(mktemp -d)/kit; cp -R "$ROOT" "$KN"; rm -rf "$KN/.git"
python3 -c "import json;p='$KN/plugins/team-dev-kit/.claude-plugin/plugin.json';d=json.load(open(p));d['version']='0.4.0';json.dump(d,open(p,'w'))"
printf '\n# v0.4.0 added contract line\n' >> "$KN/plugins/team-dev-kit/framework/contract.md"
SK="$KN/plugins/team-dev-kit/scripts/kit-sync.py"
# 8a: クリーン更新(framework 未編集)
U=$(mktemp -d); mkdir -p "$U/c"; (cd "$U/c" && git init -q); python3 "$SYNC" init --target "$U/c" >/dev/null
printf '\n## 固有\n' >> "$U/c/AGENTS.md"
python3 "$SK" update --target "$U/c" >/dev/null 2>&1
chk "framework 置換(新 contract 行)"  "grep -q 'v0.4.0 added contract line' '$U/c/.team-dev-kit/contract.md'"
chk "config(AGENTS 固有節)を温存"     "grep -q '固有' '$U/c/AGENTS.md'"
chk "lock が 0.4.0"                   "grep -q '0.4.0' '$U/c/.team-dev-kit.lock'"
# 8b: framework をローカル編集 → update は drift skip(置換しない)
U2=$(mktemp -d); mkdir -p "$U2/c"; (cd "$U2/c" && git init -q); python3 "$SYNC" init --target "$U2/c" >/dev/null
printf '\n# my local change\n' >> "$U2/c/.team-dev-kit/contract.md"
python3 "$SK" update --target "$U2/c" >/dev/null 2>&1
chk "drift skip でローカル編集保持"   "grep -q 'my local change' '$U2/c/.team-dev-kit/contract.md'"
chk "drift skip で kit 行は入らない"  "! grep -q 'v0.4.0 added contract line' '$U2/c/.team-dev-kit/contract.md'"
# 8c: --force で破棄置換
python3 "$SK" update --target "$U2/c" --force >/dev/null 2>&1
chk "--force で kit 行に置換"         "grep -q 'v0.4.0 added contract line' '$U2/c/.team-dev-kit/contract.md'"

echo "== 9. contribute(framework のみ) =="
C=$(mktemp -d); mkdir -p "$C/c"; (cd "$C/c" && git init -q); python3 "$SYNC" init --target "$C/c" >/dev/null
chk "改変なし→候補なし" "python3 '$SYNC' contribute --target '$C/c' | grep -q '候補なし'"
printf '\n# improve hook\n' >> "$C/c/.githooks/pre-commit"
printf '\n## 固有(config は対象外)\n' >> "$C/c/AGENTS.md"
ST=$(mktemp -d)
python3 "$SYNC" contribute --target "$C/c" --staging "$ST" --apply >/dev/null
chk "framework 改善を staging(framework/)" "grep -q 'improve hook' '$ST/framework/pre-commit'"
chk "config(AGENTS)は還元対象外"           "[ ! -f '$ST/config-starters/AGENTS.md' ] && [ ! -f '$ST/AGENTS.md' ]"

echo ""
echo "== 結果: pass=$pass fail=$fail =="
[ "$fail" -eq 0 ]
