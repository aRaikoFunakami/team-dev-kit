#!/bin/sh
# 概要: team-dev-kit スモークテスト。唯一の導線である bootstrap.sh を scratch リポジトリで一気通貫に検証する。
#       プロジェクトローカル導入・glue 注入(@import / [extend])・秘密ガード L1(pre-commit)/L3(egress)・
#       冪等性・--force・--global・既存 config への非破壊注入・settings.json fail-safe を確認する。
#       real リポジトリは汚さない(すべて mktemp の scratch で実行)。
# 使い方: sh tests/smoke.sh   (kit リポジトリのルートから)。全合格で 0、失敗で 1。
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BS="$ROOT/bootstrap.sh"
FIX="$ROOT/tests/fixtures"
pass=0; fail=0
ok() { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
ng() { fail=$((fail+1)); printf '  NG   %s\n' "$1"; }
chk() { if eval "$2"; then ok "$1"; else ng "$1"; fi; }

# scratch git repo を作る
newrepo() { d=$(mktemp -d); (cd "$d" && git init -q && git config user.email t@t && git config user.name t); echo "$d"; }
# bootstrap をローカルソース(ROOT)から対象 repo に対して実行
run_bs() { ( cd "$1"; shift; sh "$BS" --src "$ROOT" "$@" ); }

echo "== 0. bootstrap 構文 / 撤去物の不在 =="
chk "sh -n bootstrap.sh"        "sh -n '$BS'"
chk "bootstrap.sh は実行可能"   "[ -x '$BS' ]"
chk "kit-sync.py は撤去済み"    "[ ! -e '$ROOT/kit/scripts/kit-sync.py' ]"
chk "plugin.json は撤去済み"    "[ ! -e '$ROOT/kit/.claude-plugin/plugin.json' ]"
chk "marketplace.json は撤去済み" "[ ! -e '$ROOT/.claude-plugin/marketplace.json' ]"
chk "hooks/ は撤去済み"          "[ ! -e '$ROOT/kit/hooks' ]"
chk "kit-* skill は撤去済み"     "[ -z \"\$(ls '$ROOT/kit/skills' | grep '^kit-' || true)\" ]"

echo "== 1. fresh 導入(project-local) =="
T=$(newrepo)
run_bs "$T" >/dev/null
hp=$(git -C "$T" config --local core.hooksPath || true)
chk "skill: git-commit"            "[ -f '$T/.claude/skills/git-commit/SKILL.md' ]"
chk "skill: 7個(業務のみ)"          "[ \$(ls '$T/.claude/skills' | wc -l) -eq 7 ]"
chk "kit-* skill は配られない"      "[ -z \"\$(ls '$T/.claude/skills' | grep '^kit-' || true)\" ]"
chk "egress: .team-dev-kit/egress-scan.sh(+x)" "[ -x '$T/.team-dev-kit/egress-scan.sh' ]"
chk "settings.json に PreToolUse"  "grep -q 'egress-scan.sh' '$T/.claude/settings.json'"
chk "framework: contract.md"       "[ -f '$T/.team-dev-kit/contract.md' ]"
chk "framework: base.gitleaks"     "[ -f '$T/.team-dev-kit/base.gitleaks.toml' ]"
chk "framework: pre-commit(+x)"    "[ -x '$T/.githooks/pre-commit' ]"
chk "config: AGENTS.md"            "[ -f '$T/AGENTS.md' ]"
chk "config: .gitleaks.toml"       "[ -f '$T/.gitleaks.toml' ]"
chk "config: .github テンプレ"     "[ -f '$T/.github/PULL_REQUEST_TEMPLATE.md' ]"
chk "hooksPath=.githooks"          "[ '$hp' = .githooks ]"
chk "@import 連鎖(AGENTS→contract)" "grep -q '@.team-dev-kit/contract.md' '$T/AGENTS.md'"
chk "overlay extends base"         "grep -q '.team-dev-kit/base.gitleaks.toml' '$T/.gitleaks.toml'"

echo "== 2. L1 pre-commit(base 継承で秘密を block) =="
cp "$FIX/gitleaks-sample.txt" "$T/leak.txt"
git -C "$T" add leak.txt
before=$(git -C "$T" rev-list --count HEAD 2>/dev/null || echo 0)
rc=0; git -C "$T" commit -q -m "leak" >/dev/null 2>&1 || rc=$?
after=$(git -C "$T" rev-list --count HEAD 2>/dev/null || echo 0)
chk "commit が pre-commit で停止"  "[ '$rc' != 0 ] && [ '$before' = '$after' ]"
git -C "$T" reset -q HEAD leak.txt 2>/dev/null || true; rm -f "$T/leak.txt"

echo "== 3. L3 egress(installed egress-scan.sh) =="
egress() { rc=0; CLAUDE_PROJECT_DIR="$T" sh "$T/.team-dev-kit/egress-scan.sh" <"$1" >/dev/null 2>&1 || rc=$?; echo "$rc"; }
chk "PII を block(exit2)"          "[ \$(egress '$FIX/egress-pii.json') = 2 ]"
chk "clean を素通り(exit0)"        "[ \$(egress '$FIX/egress-clean.json') = 0 ]"
chk "非gh を素通り(exit0)"         "[ \$(egress '$FIX/egress-skip.json') = 0 ]"
chk "comment 経路の PII を block"  "[ \$(egress '$FIX/egress-comment-pii.json') = 2 ]"
chk "gh api 変更系を block(DENY)"  "[ \$(egress '$FIX/egress-api-post.json') = 2 ]"
chk "壊れた入力JSONを block(fail-closed)" "[ \$(egress '$FIX/egress-badjson.json') = 2 ]"

echo "== 4. 冪等性(再実行で skip/keep・重複なし) =="
out=$(run_bs "$T" 2>&1)
chk "skill は skip"               "printf '%s' \"\$out\" | grep -q 'skip (exists): git-commit'"
chk "glue は keep(重複注入なし)"   "printf '%s' \"\$out\" | grep -q 'keep (glue present)'"
chk "@import は1回だけ"           "[ \$(grep -c '@.team-dev-kit/contract.md' '$T/AGENTS.md') -eq 1 ]"
chk "[extend] は1回だけ"          "[ \$(grep -c '^\\[extend\\]' '$T/.gitleaks.toml') -eq 1 ]"

echo "== 5. --force(framework 置換 / config 温存) =="
printf '\n# LOCAL EDIT\n' >> "$T/.team-dev-kit/contract.md"   # framework をローカル改変
printf '\n## 固有追記\n'   >> "$T/AGENTS.md"                  # config をローカル改変
run_bs "$T" --force >/dev/null
chk "framework は --force で置換(編集消える)" "! grep -q 'LOCAL EDIT' '$T/.team-dev-kit/contract.md'"
chk "config は --force でも温存"              "grep -q '固有追記' '$T/AGENTS.md'"

echo "== 6. 既存の独自 config への glue 非破壊注入 =="
E=$(newrepo)
printf '# MyProject\n- tests first\n' > "$E/AGENTS.md"
printf 'title = "mine"\n[[rules]]\nid="x"\nregex='"'''"'MYTOK-[0-9]+'"'''"'\n' > "$E/.gitleaks.toml"
(cd "$E" && git add -A && git commit -q -m init)
run_bs "$E" >/dev/null
chk "AGENTS: ユーザ内容を保持"     "grep -q 'tests first' '$E/AGENTS.md'"
chk "AGENTS: @import を注入"       "grep -q '@.team-dev-kit/contract.md' '$E/AGENTS.md'"
chk "gitleaks: ユーザrule を保持"  "grep -q 'MYTOK' '$E/.gitleaks.toml'"
chk "gitleaks: [extend] を注入"    "grep -q 'base.gitleaks.toml' '$E/.gitleaks.toml'"
# TOML 妥当性: tomllib は py3.11+。古い環境では gitleaks の設定ロードで代替する。
if python3 -c 'import tomllib' 2>/dev/null; then
  chk "gitleaks: TOML 妥当(tomllib)"   "python3 -c 'import tomllib;tomllib.load(open(\"$E/.gitleaks.toml\",\"rb\"))'"
else
  chk "gitleaks: 設定ロード可"          "gitleaks detect --no-git --source '$E/AGENTS.md' --no-banner -c '$E/.gitleaks.toml' >/dev/null 2>&1 || [ \$? -ne 2 ]"
fi
# 注入後に base 由来の秘密が実際に止まる
cp "$FIX/gitleaks-sample.txt" "$E/leak.txt"; git -C "$E" add leak.txt
rcb=0; git -C "$E" commit -q -m leak >/dev/null 2>&1 || rcb=$?
chk "注入後 pre-commit が秘密を block" "[ '$rcb' != 0 ]"
git -C "$E" reset -q HEAD leak.txt 2>/dev/null || true; rm -f "$E/leak.txt"
# 既存の別 [extend] は自動編集せず警告
X=$(newrepo)
printf '[extend]\npath="./other.toml"\n' > "$X/.gitleaks.toml"
(cd "$X" && git add -A && git commit -q -m i)
xout=$(run_bs "$X" 2>&1)
chk "別 [extend] は警告のみ"        "printf '%s' \"\$xout\" | grep -q '既存 \\[extend\\] あり'"
chk "別 [extend] を二重化しない"    "[ \$(grep -c '^\\[extend\\]' '$X/.gitleaks.toml') -eq 1 ]"

echo "== 7. settings.json fail-safe(壊れていても完走) =="
B=$(newrepo); mkdir -p "$B/.claude"; printf '{bad json' > "$B/.claude/settings.json"
rc=0; bout=$(run_bs "$B" 2>&1) || rc=$?
chk "壊れた settings でも exit0 完走" "[ '$rc' = 0 ]"
chk "完了バナーに到達"               "printf '%s' \"\$bout\" | grep -q 'bootstrap 完了'"
chk "解析不能を警告しスキップ"       "printf '%s' \"\$bout\" | grep -q '解析できません'"
chk "壊れた settings を上書きしない"  "grep -q '{bad json' '$B/.claude/settings.json'"
chk "guardrails は配置される"        "[ -x '$B/.githooks/pre-commit' ]"

echo "== 8. --global(skill は \$HOME 配下・B層は repo) =="
FH=$(mktemp -d); G=$(newrepo)
HOME="$FH" run_bs "$G" --global >/dev/null
chk "global: skill は \$HOME/.claude/skills" "[ -f '$FH/.claude/skills/git-commit/SKILL.md' ]"
chk "global: egress も \$HOME 配下"          "[ -x '$FH/.claude/team-dev-kit/egress-scan.sh' ]"
chk "global: B層(pre-commit)は repo 配下"    "[ -x '$G/.githooks/pre-commit' ]"

echo "== 9. Issue #19 統合フロー doc 反映(kit ソース静的検証) =="
GW="$ROOT/kit/skills/github-workflow/SKILL.md"
TD="$ROOT/kit/skills/ticket-draft/SKILL.md"
PP="$ROOT/kit/skills/ticket-pr-publish/SKILL.md"
TPL="$ROOT/kit/config-starters/github/ISSUE_TEMPLATE"
# 概念/構造を pin する（言い換えで割れる literal や、他所にも出る単独キーワードは避ける）
chk "GW: 統合点セクション見出し"      "grep -q '## feature と統合点' '$GW'"
chk "GW: アンブレラ命名 feature/<name>" "grep -q 'feature/<name>' '$GW'"
chk "GW: Task 命名は - 区切り"        "grep -q 'feature/<name>-<issue-number>-<short-description>' '$GW'"
chk "GW: D/F 衝突回避の注記"          "grep -q 'D/F conflict' '$GW'"
chk "GW: Task PR は Refs #"           "grep -q 'Refs #' '$GW'"
chk "GW: 最終PRに Closes 集約"        "grep -q '集約' '$GW' && grep -q 'Closes' '$GW'"
chk "GW: E2E はプロジェクト規約へ委譲" "grep -q '各プロジェクト規約' '$GW'"
chk "TD: 検証単位の確定手順 2'"       "grep -q '検証単位（feature）の確定' '$TD'"
chk "TD: feature グルーピング"        "grep -q 'グルーピング' '$TD'"
# ticket-pr-publish が束ねフロー対応（Task PR は Refs/base=アンブレラ）
chk "PP: Task ブランチ判定"           "grep -q 'Task ブランチ' '$PP'"
chk "PP: Task PR は Refs #<n>"        "grep -q 'Refs #<n>' '$PP'"
# Issue テンプレ 3 種に検証単位節（github-workflow が bugfix/hotfix も束ね可と明記する整合）
chk "FT: feature 検証単位節"          "grep -q '## 検証単位 (feature)' '$TPL/feature.md'"
chk "FT: bug 検証単位節"              "grep -q '## 検証単位 (feature)' '$TPL/bug.md'"
chk "FT: docs 検証単位節"             "grep -q '## 検証単位 (feature)' '$TPL/docs.md'"

echo ""
echo "== 結果: pass=$pass fail=$fail =="
[ "$fail" -eq 0 ]
