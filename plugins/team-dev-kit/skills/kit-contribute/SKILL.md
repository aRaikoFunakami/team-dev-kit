---
name: kit-contribute
description: 消費プロジェクトでローカルに改善した team-dev-kit の framework ファイル(.team-dev-kit/contract.md・base.gitleaks.toml・.githooks/pre-commit)を、上流 team-dev-kit リポジトリへ draft PR として還元する。.team-dev-kit.lock との差分で候補を抽出し、kit を fork/branch して反映する。config はプロジェクト固有のため対象外。`/kit-contribute` が明示的に呼ばれたときのみ起動。自然言語の依頼・関連語(還元/貢献/反映/contribute 等)では自動起動しない。
---

# kit-contribute

framework への改善を kit へ PR で還元する。プロジェクト間の直コピーは禁止。kit 経由でのみ伝播させる。

## 厳守

明示 `/kit-contribute` のときだけ実行する。fork・push・PR(外部公開・不可逆)を伴うため、push/PR 直前に必ずユーザー確認を取る。

## 対象

- **framework のみ**: lock の sha と異なる(ローカル改変された)`.team-dev-kit/contract.md`・`base.gitleaks.toml`・`.githooks/pre-commit`
- **config は対象外**: AGENTS.md の固有節・`.gitleaks.toml` の allowlist 等はプロジェクト固有。還元しない

## 手順

1. **候補抽出**(dry)
   ```sh
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/kit-sync.py" contribute
   ```
   改変された framework を diff 付きで表示。候補が無ければ終了。

2. **何を還元するか確認**: 候補と diff をユーザーに見せ、上流に出すものを選ぶ。プロジェクト都合の改変は出さない。

3. **ステージング**
   ```sh
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/kit-sync.py" contribute --staging /tmp/kit-contrib --apply
   ```
   `/tmp/kit-contrib/framework/<file>` に kit のレイアウトで並ぶ。

4. **kit を fork/branch**(github-workflow 規約)。**push 前にユーザー確認**。write 権があれば clone+branch、無ければ `gh repo fork aRaikoFunakami/team-dev-kit --clone`。

5. **反映 & コミット**: staging の `framework/*` を kit の `plugins/team-dev-kit/framework/` へ複製。`type(scope): subject` で 1 論点。version は bump しない(リリース時にメンテナが上げる)。

6. **draft PR**(不可逆。直前確認)。本文に「なぜ全プロジェクトに有益か」「どのプロジェクト由来か」を書く。`gh pr create --draft`。

7. マージ後の伝播を案内: メンテナが version bump → 各プロジェクトは `/plugin update` + `/kit-update` で取り込む。

## 出力

候補一覧・選定理由・PR の URL・伝播手順を簡潔に報告する。
