# legacy-manual-rules — AI を使わなかった頃のルールドキュメント（サンプル）

> ⚠️ **このディレクトリは「昔の姿」を残すためのサンプルです。現役のルールではありません。**
>
> team-dev-kit を導入する前、チーム開発の最低限のルールは
> **人間が読んで覚えて守る** ドキュメントとして配られていました。
> ここに置いてあるのは、その頃に各チームが持っていたであろう
> ルールドキュメントを再現したサンプルです。
>
> いまは同じルールが Claude Code の **Skill** と **Hook** に畳み込まれ、
> 人が覚えなくても自動で適用されます。
> **普段の開発でこのディレクトリを読む必要はありません。**
> 「何を自動化したのか」を知りたい人向けの資料です。

---

## なぜこれを残すのか

team-dev-kit の本質は、

- 昔は **人が読んで守っていたルール** を
- Skill / Hook に移し替えて **AI が自動で守る** ようにした

という移し替えです。各 Skill の冒頭コメントにも
「旧 instructions 配下の◯◯を移植したもの」と書かれています。
つまり、現在の機能から逆算すれば、移植元になった
**人間向けルールドキュメントが何本あったか** が分かります。

このディレクトリは、その「移植元」を逆引きして再現したものです。
team-dev-kit を入れていないチームが、最低限これだけは
ドキュメント化して人手で運用していたはず、という想定のサンプルです。

## 逆引き表（機能 → 昔必要だったルールドキュメント）

| 昔のルールドキュメント（このディレクトリ） | いまこれを自動化している Skill / Hook | README の対応箇所 |
|---|---|---|
| [01-commit-convention.md](01-commit-convention.md) コミット規約 | `git-commit` skill | 「コミット作成」 |
| [02-github-workflow.md](02-github-workflow.md) ブランチ運用・Issue/PR 運用 | `github-workflow` skill | 「GitHub 操作（Issue / PR）」 |
| [03-issue-authoring.md](03-issue-authoring.md) Issue 起票ガイド・テンプレート | `ticket-template` / `ticket-draft` / `ticket-publish` / `ticket-pr-publish` skill | 「チケット作成」 |
| [04-design-doc-style.md](04-design-doc-style.md) 設計ドキュメント記述ルール | `doc-writing` skill | 「設計ドキュメント作成」 |
| [05-secret-handling.md](05-secret-handling.md) 秘密情報取り扱いルール | pre-commit hook / PreToolUse hook + gitleaks（二重ガード） | 「秘密情報の漏洩防止」 |

**コアは 5 本**です。README の「何が自動でやってくれるのか」に並ぶ
4 ジャンル（コミット / GitHub 操作 / 設計ドキュメント / チケット）＋
秘密情報ガードに、ちょうど対応します。

現場の粒度ではこれをさらに分割していたはずで、たとえば
02 を「ブランチ運用」と「PR/Issue 運用」に、03 を種別ごとに割ると
**7〜8 本**になります。team-dev-kit はその散らばったドキュメント群を
Skill + Hook 1 セットに集約しました。

## このディレクトリと現役ドキュメントの違い

| | このディレクトリ（legacy） | 現役 |
|---|---|---|
| 読み手 | 人間（覚えて守る） | Claude Code（自動で適用） |
| 守られ方 | 各自の注意力・レビュー指摘 | Skill 提案 / Hook によるブロック |
| 実体 | Markdown を読む | `plugins/team-dev-kit/skills/*` と `hooks/` |
| いま見るべきか | いいえ（資料・サンプル） | はい（[`../../README.md`](../../README.md)） |
