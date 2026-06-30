---
name: ticket-pr-publish
description: 現在の feature ブランチから issue 番号を拾い Closes # 付きの PR を gh で作成する（GitHub への登録・取り消し困難）。明示的に /ticket-pr-publish が呼ばれたときのみ起動し、自然言語の依頼では自動起動しない
argument-hint: "[#<issue-number> など番号上書き（任意）]"
---

<!--
概要: PR 作成 skill。
現在のブランチ名 feature/<n>-... 等から issue 番号を抽出し、gh pr create で発行する。
通常 PR は base=default ブランチに Closes #<n> を入れて Issue⇄PR の双方向リンクを保証する。
束ねフローの Task ブランチ（feature/<name>-<issue>-<desc>）のときは base=アンブレラ・本文は Refs #<n>
に切り替える（早期 close 回避。close は最終 PR が集約。→ github-workflow skill）。
運用規約は github-workflow skill、コミット規約は git-commit skill を参照。
発行は外部公開・取り消し困難なので、明示的に /ticket-pr-publish が呼ばれたときのみ起動し
（自然言語の「PR 作って」等では自動起動しない）、加えて発行前に必ず明示同意を取る（二重ガード）。
-->

現在のブランチの変更を GitHub Pull Request として作成する。手順を厳守する。

1. **issue 番号の決定**
   - `$ARGUMENTS` に番号（`#123` または `123`）が渡されていればそれを使う。
   - 無ければ現在のブランチ名を取得し、`feature/<n>-...` / `bugfix/<n>-...` / `hotfix/<n>-...` / `docs/<n>-...` の先頭から issue 番号 `<n>` を抽出する。
   - 抽出できない（番号を含まないブランチ名）場合は推測せず、ユーザーに issue 番号を確認する。
   - 現在のブランチが default ブランチ（通常 `main`、旧 repo は `master`）の場合は中止し、feature ブランチで実行するよう促す。
   - **束ねフロー（Task=N）の Task ブランチ判定:** ブランチ名が `feature/<name>-<issue>-<desc>` 形で、かつ同名アンブレラ
     `feature/<name>` が存在する（`git ls-remote --heads origin "feature/<name>"` / `git branch --list 'feature/<name>'`）場合は
     **Task ブランチ**とみなす。`<issue>` は `<name>` 直後の数値セグメント。Task ブランチのときは base と本文を
     後述の Task PR ルールに切り替える（→ github-workflow skill「束ねる場合」）。

2. **base ブランチの決定**
   - base は default ブランチを既定とする。`gh repo view --json defaultBranchRef -q .defaultBranchRef.name` で取得し決め打ちしない（`main` / `master` どちらでも正しく動く）。
   - **Task ブランチ（手順 1 で判定）のときは base をアンブレラ `feature/<name>` にする**（default ではない）。
     束ねた feature は最終 PR（アンブレラ → default）で着地するため、Task PR の base はアンブレラに向ける。
   - closing keyword はマージ先が default ブランチのときのみ発火する。base が default 以外になる場合はその旨を警告し、マージ後に Development サイドバーから手動で Issue を紐付ける必要があると伝える。

3. **コミットの push**
   - ローカルブランチが未 push、または origin より先行している場合は `git push -u origin <branch>` する。
   - push 対象の差分が無い（コミットしていない）場合は中止し、先にコミットするよう促す。

4. **PR 本文の生成**
   - `.github/PULL_REQUEST_TEMPLATE.md` があればその節構造に沿う。無ければ Related Issue / 変更概要 / テスト / チェックの節で組む。
   - 通常の PR（base=default）では、本文の先頭付近に **必ず** `Closes #<n>` を入れる（`Fixes` / `Resolves` でも可）。これが Issue⇄PR 双方向リンクの生成条件。
   - **Task PR（base がアンブレラ＝非 default）のときは `Closes` を使わず `Refs #<n>` を入れる。** closing keyword は default 着地でのみ発火するため、Task PR で `Closes` を書くと誤発火・統合 E2E ゲート前の早期 close を招く。Issue の close は最終 PR（アンブレラ → default）が `Closes #..` を集約して行う（→ github-workflow skill）。
   - 変更概要は `git log "$BASE"..HEAD` と `git diff "$BASE"...HEAD`（`$BASE` は上記で取得した default ブランチ）を確認して会話/コミットから組む。捏造しない。
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
