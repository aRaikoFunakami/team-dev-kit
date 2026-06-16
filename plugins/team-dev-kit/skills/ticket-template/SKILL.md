---
name: ticket-template
description: Issue テンプレを種別選択して .issue_drafts/ にコピーし、人が手書きするための空の下書きを用意する
argument-hint: "[bug|docs|feature（任意）]"
---

<!--
概要: 手書き用チケット下書きの足場(scaffold)作成 skill。
.github/ISSUE_TEMPLATE/ の該当テンプレを verbatim でコピーするだけ。本文の AI 生成はしない。
人がパスをクリックしてゼロから手で書く。会話から本文を生成したい場合は /ticket-draft（N=1 でも可）を使う。
発行は別 skill /ticket-publish。job 境界は「人が書く(本 skill) / AI が書く(ticket-draft) / GitHub へ発行する(ticket-publish, ticket-pr-publish)」。
本 skill はローカルにファイルを作るだけ（GitHub へは登録しない）なので自動起動を許容する。
-->

GitHub Issue の **手書き用** 下書きを用意する。テンプレを `.issue_drafts/` にコピーするだけで、本文は生成しない。手順を厳守する。

1. **種別の決定**
   - `$ARGUMENTS` に `bug` / `docs` / `feature` が渡されていればそれを使う。
   - 無ければ `AskUserQuestion` で種別を聞く。選択肢は **bug / docs / feature** の3つ。

2. **テンプレの特定**（実体は `.github/ISSUE_TEMPLATE/`）
   - bug → `.github/ISSUE_TEMPLATE/bug.md`
   - docs → `.github/ISSUE_TEMPLATE/docs.md`
   - feature → `.github/ISSUE_TEMPLATE/feature.md`

3. **保存先の決定**
   - `date +%Y%m%d-%H%M%S` を Bash で取得し、`.issue_drafts/<type>-<timestamp>.md`
     （例 `.issue_drafts/feature-20260613-141500.md`）とする。`.issue_drafts/` が無ければ作る。

4. **コピー（verbatim）**
   - テンプレ全文を **そのまま** 保存先へコピーする。frontmatter（`title` / `labels` 等）も本文の
     見出し・コメントも改変しない。`title:` のプレースホルダ（`fix(scope): ` 等）も残したまま渡す。
   - **本文の生成・補完はしない。** 会話内容を本文へ書き込まない（転記しないので機密情報の混入リスクが構造的に無い）。

5. **出力**
   - エディタでは開かない。`pwd` 等で絶対パスを得て、作成ファイルの **絶対フルパス** を表示する
     （Claude Code 上でクリックすれば開ける）。
   - 「クリックで開いて手で記入 → `title` の `scope` を埋め受け入れ条件等を記述 → `/ticket-publish @<path>` で発行」と案内する。

注意:
- これは手書き用の足場。本文を AI に書かせたい（会話/計画から起こしたい）なら `/ticket-draft` を使う（1件でも N 件でも可）。
- 既存の同名ファイルは上書きしない（timestamp で衝突回避済み）。
- 不要な節はユーザーが手で削ってよい（テンプレ側コメントの方針どおり）。
