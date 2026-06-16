---
name: ticket-pr-publish
description: 現在の feature ブランチから issue 番号を拾い Closes # 付きの PR を gh で作成する（GitHub への登録・取り消し困難）。明示的に /ticket-pr-publish が呼ばれたときのみ起動し、自然言語の依頼では自動起動しない
argument-hint: "[#<issue-number> など番号上書き（任意）]"
---

<!--
概要: PR 作成 skill。
現在のブランチ名 feature/<n>-... 等から issue 番号を抽出し、
PR 本文に Closes #<n> を必ず入れて gh pr create で発行する。base は default ブランチ。
Issue⇄PR の双方向リンクは PR 本文の closing keyword でのみ生成されるため、本 skill がそれを保証する。
運用規約は github-workflow skill、コミット規約は git-commit skill を参照。
発行は外部公開・取り消し困難なので、明示的に /ticket-pr-publish が呼ばれたときのみ起動し
（自然言語の「PR 作って」等では自動起動しない）、加えて発行前に必ず明示同意を取る（二重ガード）。
-->

現在のブランチの変更を GitHub Pull Request として作成する。手順を厳守する。

1. **issue 番号の決定**
   - `$ARGUMENTS` に番号（`#123` または `123`）が渡されていればそれを使う。
   - 無ければ現在のブランチ名を取得し、`feature/<n>-...` / `bugfix/<n>-...` / `hotfix/<n>-...` / `docs/<n>-...` の先頭から issue 番号 `<n>` を抽出する。
   - 抽出できない（番号を含まないブランチ名）場合は推測せず、ユーザーに issue 番号を確認する。
   - 現在のブランチが default ブランチ（`master`）の場合は中止し、feature ブランチで実行するよう促す。

2. **base ブランチの決定**
   - base は default ブランチ（`master`）を既定とする。`gh repo view --json defaultBranchRef -q .defaultBranchRef.name` で確認する。
   - closing keyword はマージ先が default ブランチのときのみ発火する。base が default 以外になる場合はその旨を警告し、マージ後に Development サイドバーから手動で Issue を紐付ける必要があると伝える。

3. **コミットの push**
   - ローカルブランチが未 push、または origin より先行している場合は `git push -u origin <branch>` する。
   - push 対象の差分が無い（コミットしていない）場合は中止し、先にコミットするよう促す。

4. **PR 本文の生成**
   - `.github/PULL_REQUEST_TEMPLATE.md` があればその節構造に沿う。無ければ Related Issue / 変更概要 / テスト / チェックの節で組む。
   - 本文の先頭付近に **必ず** `Closes #<n>` を入れる（`Fixes` / `Resolves` でも可）。これが Issue⇄PR 双方向リンクの生成条件。
   - 変更概要は `git log master..HEAD` と `git diff master...HEAD` を確認して会話/コミットから組む。捏造しない。
   - 本文は `/tmp/ticket-pr-publish-body-<branch>.txt` に書き出す。

5. **PR タイトルの決定**
   - `type(scope): subject` 形式（→ git-commit skill）に揃える。代表コミットの subject を流用してよい。

6. **発行前チェック（必須・ここは通常文で確認）**
   - 抽出した issue 番号・base ブランチ・タイトル・発行先リポジトリをユーザーに提示する。
   - base が default ブランチか（keyword 発火条件を満たすか）を明示する。
   - これは外部公開・取り消し困難な操作なので、明示の同意を得てから実行する。

7. **発行（同意後）**
   - リポジトリは cwd の origin を自動利用（`-R` は付けない）:
     ```
     gh pr create --base <default-branch> --title "<title>" --body-file /tmp/ticket-pr-publish-body-<branch>.txt
     ```
   - 非対話で発行される。

8. **出力と検証**
   - 出力された PR URL を表示する。
   - `gh pr view <number> --json closingIssuesReferences -q '.closingIssuesReferences[].number'` で、対象 issue 番号が紐付いたことを確認して報告する。

注意:
- gh 未認証なら `gh auth status` で確認し、ユーザーに `gh auth login` を促す。
- 一括作成・自動マージはしない（誤操作リスク回避、`ticket-publish` の方針に合わせる）。マージはユーザーが行う。
- 既存スキル `ticket-template` / `ticket-publish` / `ticket-draft` の挙動は変更しない。
