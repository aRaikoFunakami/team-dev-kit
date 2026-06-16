---
name: kit-contribute
description: 消費プロジェクトでローカルに改善した team-dev-kit のテンプレ(pre-commit・.gitleaks.toml・.github テンプレ等)を、上流 team-dev-kit リポジトリへ draft PR として還元する。.team-dev-kit.lock との差分で貢献候補を抽出し、kit を fork/branch して反映する。`/kit-contribute` が明示的に呼ばれたときのみ起動。自然言語の依頼・関連語(還元/貢献/反映/contribute 等)では自動起動しない。
---

# kit-contribute

現場の改善を kit へ PR で還元する。プロジェクト間の直コピーは禁止。kit 経由でのみ伝播させる。

## 厳守

明示 `/kit-contribute` のときだけ実行する。fork・push・PR(外部公開・不可逆)を伴うため、push/PR の直前に必ずユーザー確認を取る。

## 手順

1. **候補抽出**(dry)
   ```sh
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/kit-sync.py" contribute
   ```
   - lock と異なる(ローカル改変)かつ kit 現行とも異なるファイルを候補として diff 付きで表示
   - `手動レビュー` に出た AGENTS.md(managed-block)は契約変更。本当に上流の契約を変えるべきか吟味する
   - 候補が無ければ終了

2. **どれを還元するか確認**: 候補とその diff をユーザーに見せ、上流に出すものを選ぶ。プロジェクト固有の事情による改変は還元しない。

3. **ステージング**
   ```sh
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/kit-sync.py" contribute --staging /tmp/kit-contrib --apply
   ```
   `/tmp/kit-contrib/templates/<rel>` に還元ファイルが並ぶ。

4. **kit を fork/branch**(github-workflow 規約)。**push 前にユーザー確認**。
   - write 権があれば: kit を clone し feature ブランチ
   - 無ければ: `gh repo fork aRaikoFunakami/team-dev-kit --clone` し feature ブランチ
   - `git config core.hooksPath .githooks` は kit 側にもあるので、commit 時に pre-commit(秘密情報スキャン)が走る

5. **反映 & コミット**: staging の `templates/*` を kit の `plugins/team-dev-kit/templates/` へ複製。`type(scope): subject` で 1 論点コミット(例 `feat(pre-commit): 大容量ファイルを警告`)。version は **bump しない**(リリース時にメンテナが上げる)。

6. **draft PR**(不可逆。直前確認)。本文に「なぜこの改善が全プロジェクトに有益か」「どのプロジェクト由来か」を書く。`gh pr create --draft`。

7. マージ後の伝播を案内する: メンテナが version を bump → 各プロジェクトは `/plugin update` + `/kit-update` で取り込む。

## 出力

候補一覧・選定理由・作成した PR の URL・マージ後の伝播手順を簡潔に報告する。
