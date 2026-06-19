---
name: ticket-publish
description: .issue_drafts/ の下書きファイルを gh で GitHub Issue として発行する（GitHub への登録・取り消し困難）。明示的に /ticket-publish が呼ばれたときのみ起動し、自然言語の依頼では自動起動しない
argument-hint: "@.issue_drafts/<file>.md"
---

<!--
概要: チケット下書き発行 skill（ローカル下書き → GitHub Issue 登録）。
引数で渡された下書き .md の frontmatter から title/labels を取り、
本文を body にして gh issue create で発行する。リポジトリは cwd の origin を使う。
下書きは /ticket-template（手書き）または /ticket-draft（AI 生成）で作る。
外部公開・取り消し困難なため、明示的に /ticket-publish が呼ばれたときのみ起動する
（自然言語の「issue 作って」等では自動起動しない）。加えて発行前に明示同意ゲートを置き二重ガードとする。
-->

引数 `$ARGUMENTS` の下書きファイルを GitHub Issue として発行する。手順を厳守する。

1. 対象パスを `$ARGUMENTS` から取得する。先頭の `@` は除去する。
   - 空なら `.issue_drafts/*.md` の最新更新ファイルを候補として提示し、確認を取る。
2. ファイルを読む。frontmatter（先頭 `---` から次の `---` まで）から抽出:
   - `title:` の値（クォート除去）
   - `labels:` の値（カンマ区切りならそのまま）
3. frontmatter を除いた残り全文を body とする。`/tmp/ticket-body-<basename>.txt` に書き出す。
4. **発行前チェック（必須・ここは通常文で確認）**:
   - title に `scope` や `<issue-number>` 等のプレースホルダが残っていないか。
   - body の必須節（受け入れ条件・対象ファイル等）が空でないか。
   - 抽出した title / labels と発行先リポジトリ名をユーザーに提示し、発行してよいか確認する。
     これは外部公開・取り消し困難な操作なので、明示の同意を得てから実行する。
5. 同意後に実行（リポジトリは cwd の origin を自動利用、`-R` は付けない）:
   ```
   gh issue create --title "<title>" --label "<labels>" --body-file /tmp/ticket-body-<basename>.txt
   ```
   `--title --label --body-file` を揃えるので非対話で発行される。
6. 出力された Issue URL を表示する。
7. **発行確定後の後始末（下書き削除）**:
   - Issue URL が返り発行が確定したことを確認してから行う。発行前・発行失敗時は削除しない。
   - GitHub が source of truth になったため、ローカル下書きは不要。削除対象パス（発行した下書きと
     `/tmp/ticket-body-<basename>.txt`）をユーザーに提示し、削除してよいか確認する。
   - 同意後に削除する。`.issue_drafts/` ディレクトリ自体は残す（次の下書き用）。
   - 発行後に下書きファイル名へ発行番号を追記したい場合は、削除前にその旨を選べる（任意）。

注意:
- gh 未認証なら `gh auth status` で確認し、ユーザーに `gh auth login` を促す。
- labels が空 / 存在しないラベルだと gh がエラーになる。発行前に `gh label list` で確認し、
  テンプレ由来の bug/documentation/feature が無ければ `gh label create <name>` で作ってから発行する。
