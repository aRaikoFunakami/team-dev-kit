#!/bin/sh
# 概要: team-dev-kit のスモークテスト。manifest 妥当性・egress フック・kit-sync の
#       init/doctor/update(3-way)/contribute を scratch リポジトリで一気通貫に検証する。
#       real リポジトリは汚さない(update テストは kit を複製して version を上げる)。
# 使い方: sh tests/smoke.sh   (kit リポジトリのルートから)
# 終了: 全合格で 0、いずれか失敗で 1。
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PLUGIN="$ROOT/plugins/team-dev-kit"
SYNC="$PLUGIN/scripts/kit-sync.py"
EG="$PLUGIN/scripts/egress-scan.sh"
TMPL="$PLUGIN/templates"
pass=0; fail=0
ok()  { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
ng()  { fail=$((fail+1)); printf '  NG   %s\n' "$1"; }
chk() { if eval "$2"; then ok "$1"; else ng "$1"; fi; }

echo "== 1. manifest JSON 妥当性 =="
for f in "$ROOT/.claude-plugin/marketplace.json" "$PLUGIN/.claude-plugin/plugin.json" "$PLUGIN/hooks/hooks.json"; do
  chk "valid: ${f#$ROOT/}" "python3 -c 'import json,sys;json.load(open(sys.argv[1]))' '$f' >/dev/null 2>&1"
done

echo "== 2. egress フック =="
P=$(mktemp -d); cp "$TMPL/.gitleaks.toml" "$P/.gitleaks.toml"
# 検体は tests/fixtures/(意図的に PII を含むため .gitleaks.toml の allowlist で除外済)
FIX="$ROOT/tests/fixtures"
egress() { rc=0; CLAUDE_PROJECT_DIR="$P" sh "$EG" <"$1" >/dev/null 2>&1 || rc=$?; echo "$rc"; }
rc_pii=$(egress "$FIX/egress-pii.json"); rc_clean=$(egress "$FIX/egress-clean.json"); rc_skip=$(egress "$FIX/egress-skip.json")
chk "PII を block(exit2)"   "[ $rc_pii = 2 ]"
chk "clean を素通り(exit0)" "[ $rc_clean = 0 ]"
chk "非gh を素通り(exit0)"  "[ $rc_skip = 0 ]"

echo "== 3. init (fresh) =="
T=$(mktemp -d); mkdir -p "$T/f"; (cd "$T/f" && git init -q)
python3 "$SYNC" init --target "$T/f" >/dev/null
hp_f=$(git -C "$T/f" config --local core.hooksPath || true)
chk "lock 生成" "[ -f '$T/f/.team-dev-kit.lock' ]"
chk "pre-commit 実行可" "[ -x '$T/f/.githooks/pre-commit' ]"
chk "hooksPath=.githooks" "[ '$hp_f' = .githooks ]"
chk "AGENTS.md に block" "grep -q 'team-dev-kit:start' '$T/f/AGENTS.md'"

echo "== 4. doctor (clean) =="
chk "doctor exit0" "python3 '$SYNC' doctor --target '$T/f' >/dev/null"

echo "== 5. init (existing, 非破壊) =="
mkdir -p "$T/e"; (cd "$T/e" && git init -q && git config core.hooksPath .husky)
printf '# 既存契約\n\n## 社内ルール\n- foo\n' > "$T/e/AGENTS.md"
python3 "$SYNC" init --target "$T/e" >/dev/null
hp_e=$(git -C "$T/e" config --local core.hooksPath || true)
chk "既存 AGENTS 節を温存" "grep -q '社内ルール' '$T/e/AGENTS.md'"
chk "block を追記" "grep -q 'team-dev-kit:start' '$T/e/AGENTS.md'"
chk "hooksPath 非上書き(.husky)" "[ '$hp_e' = .husky ]"

echo "== 6. drift 検出 =="
printf '\n# local\n' >> "$T/f/.gitleaks.toml"
chk "drift を検出" "python3 '$SYNC' doctor --target '$T/f' | grep -q 'DRIFTED'"

echo "== 7. update (3-way) =="
KN=$(mktemp -d)/kit; cp -R "$ROOT" "$KN"; rm -rf "$KN/.git"
python3 -c "import json;p='$KN/plugins/team-dev-kit/.claude-plugin/plugin.json';d=json.load(open(p));d['version']='0.2.0';json.dump(d,open(p,'w'))"
printf '\n# v2 rule\n' >> "$KN/plugins/team-dev-kit/templates/.gitleaks.toml"
printf '\nKIT2\n' >> "$KN/plugins/team-dev-kit/templates/.github/PULL_REQUEST_TEMPLATE.md"
U=$(mktemp -d); mkdir -p "$U/c"; (cd "$U/c" && git init -q)
python3 "$SYNC" init --target "$U/c" >/dev/null
printf '\nLOCAL\n' >> "$U/c/.github/PULL_REQUEST_TEMPLATE.md"   # 衝突誘発
python3 "$KN/plugins/team-dev-kit/scripts/kit-sync.py" update --target "$U/c" --ancestor-dir "$TMPL" >/dev/null 2>&1 || true
chk "clean 取込(.gitleaks に v2 rule)" "grep -q 'v2 rule' '$U/c/.gitleaks.toml'"
chk "衝突マーカー(PR テンプレ)" "grep -q '<<<<<<<' '$U/c/.github/PULL_REQUEST_TEMPLATE.md'"
chk "lock が 0.2.0" "grep -q '0.2.0' '$U/c/.team-dev-kit.lock'"

echo "== 8. contribute =="
C=$(mktemp -d); mkdir -p "$C/c"; (cd "$C/c" && git init -q)
python3 "$SYNC" init --target "$C/c" >/dev/null
chk "改変なし→候補なし" "python3 '$SYNC' contribute --target '$C/c' | grep -q '候補なし'"
printf '\n# improve\n' >> "$C/c/.githooks/pre-commit"
ST=$(mktemp -d)
python3 "$SYNC" contribute --target "$C/c" --staging "$ST" --apply >/dev/null
chk "改善を staging" "grep -q 'improve' '$ST/templates/.githooks/pre-commit'"

echo ""
echo "== 結果: pass=$pass fail=$fail =="
[ "$fail" -eq 0 ]
