# Issue 起票ガイド・テンプレート（旧・人間運用版）

> 🕰️ **これは team-dev-kit 導入前のサンプルです。**
> いまはこのガイドを `ticket-*` skill 群が保持し、会話や開発計画から下書きを
> 自動生成・発行します。人がテンプレを探してコピペする必要はありません。
> 現役の挙動:
> [`ticket-template`](../../kit/skills/ticket-template/SKILL.md)（手書き足場）/
> [`ticket-draft`](../../kit/skills/ticket-draft/SKILL.md)（AI 生成）/
> [`ticket-publish`](../../kit/skills/ticket-publish/SKILL.md)（Issue 発行）/
> [`ticket-pr-publish`](../../kit/skills/ticket-pr-publish/SKILL.md)（PR 発行）。

---

人間運用の頃は、起票のたびに「種別を選ぶ → テンプレを探す →
コピペして埋める → ラベルを付けて発行する」を手作業でやっていた。
ここではその手順と、各種別テンプレの中身を残す。

## 起票の流れ（手作業版）

1. **種別を決める** — `bug` / `docs` / `feature` のいずれか。
2. **対応テンプレをコピーする** — 実体は `.github/ISSUE_TEMPLATE/`。
   - bug → `.github/ISSUE_TEMPLATE/bug.md`
   - docs → `.github/ISSUE_TEMPLATE/docs.md`
   - feature → `.github/ISSUE_TEMPLATE/feature.md`
3. **本文を埋める** — `title:` の `scope` プレースホルダを実際の scope に置き換え、
   受け入れ条件・対象ファイル等を記述する。**実装者が追加質問なしで着手できる粒度**にする。
4. **ラベルを確認する** — テンプレ由来の `bug` / `documentation` / `feature` が
   リポジトリに存在するか `gh label list` で確認。無ければ作る。
5. **発行する** —

   ```bash
   gh issue create --title "<title>" --label "<labels>" --body-file <path>
   ```

## 起票の品質ルール

- 挙動を変える変更には必ず Issue を立てる（規模ではなく性質で判断 → [02-github-workflow.md](02-github-workflow.md)）。
- 本文には **確定事実だけ**を書く。未確定の節は推測で埋めず `（未確定）` と明示する。
- 機密情報・個人情報（トークン/鍵/メール/個人名等）を本文に転記しない（→ [05-secret-handling.md](05-secret-handling.md)）。
- typo・文言微修正など挙動不変かつ些細なものは Issue 不要。PR 本文を記録とする。

## テンプレートの構成

`.github/ISSUE_TEMPLATE/` 配下に種別ごとのテンプレを置き、frontmatter で
`title:` のプレースホルダと `labels:` を持たせる。発行時にこの frontmatter から
title / label を拾う運用だった。種別の使い分け:

| 種別 | 用途 | 既定ラベル |
|---|---|---|
| bug | 不具合報告（再現手順・期待/実際の挙動） | `bug` |
| feature | 機能追加・変更（背景・受け入れ条件） | `feature` |
| docs | ドキュメント追加・修正 | `documentation` |

> テンプレ本体は現役でも同じ場所（`.github/ISSUE_TEMPLATE/`）で使われており、
> 編集してよいファイルです。team-dev-kit はテンプレを廃止したのではなく、
> 「種別選択 → コピー → 本文生成 → 発行」の手作業を skill に移しただけです。

## 発行は取り消しが難しい操作

人間運用でも、起票は外部公開・取り消し困難な操作だった。発行前に
title にプレースホルダが残っていないか、必須節が空でないかを必ず確認してから
`gh issue create` を叩く。現役では `ticket-publish` が明示同意ゲートでこれを担保する。
