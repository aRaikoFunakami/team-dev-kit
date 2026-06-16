---
name: github-workflow
description: GitHub を操作するとき（Issue の起票・閲覧、PR 作成・レビュー、ブランチ運用）に起動する。gh コマンド必須、Issue の要否は「挙動を変えるか」で判断、branch + PR は常に必須（master 直接 push 禁止）、PR 本文に Closes #N で Issue を紐付ける、closing keyword は default ブランチでのみ発火、といった本リポジトリの GitHub 運用契約を与える。「Issue 作って」「PR 出して」「ブランチ切って」等で発火。
---

<!--
概要: GitHub 運用契約 skill。Issue 要否・branch/PR 規約・closing keyword を与える。
旧 instructions 配下の GitHub 運用契約を移植したもの。GitHub 操作のたびに参照する。
-->

# GitHub 運用ルール

本リポジトリにおける GitHub の運用契約を定める。迷ったら AGENTS.md の方針を優先する。

## リポジトリ

- **URL:** `https://github.com/aRaikoFunakami/test.git`
- **default ブランチ:** `master`（PR のマージ先。closing keyword の発火条件に関わる）

## ツール

- GitHub 操作（接続・起票・閲覧・PR 等）には必ず `gh` コマンドを使用する。
- ブラウザ操作や Web UI を前提とした手順を記述・依頼しない。

## Issue ベース開発

- 挙動を変える変更（バグ修正・機能追加・ロジック/API 変更）は **Issue の内容に基づいて** 実施する。
- Issue 起票時は、**AI が単独で実装・完結できるレベルまで** 詳細な技術仕様を記述する。
  - 対象ファイル・モジュール、変更方針、受け入れ条件（テスト/検証方法）を含める。
  - 曖昧な要望のままで起票しない。実装者が追加質問なしで着手できる粒度にする。

### Issue の要否（挙動を変えるか）

Issue を起こすかは変更の**性質**で決める。規模（数行か否か）ではない。

| 変更の性質 | Issue | branch + PR |
|------------|-------|-------------|
| 挙動不変かつ些細（typo・誤字・文言の微修正・コメント・整形など） | 不要 | 必須（番号なしブランチ可、`Closes` なし、PR 本文が記録） |
| 挙動変更（バグ・ロジック・API 変更、hotfix を含む）、または実質的な doc/規約変更 | 必要（`/ticket-draft` で AI 生成可） | 必須（`Closes #N` で紐付け） |

- 線引きは「**挙動を変えるか**」。数行の hotfix でも挙動を変えるなら Issue を作る。
- **branch + PR は変更の性質によらず常に必須**（`master` 直接 commit/push 禁止は後述のとおり維持）。
  Issue を省けるのは「挙動不変かつ些細」のときだけで、PR による記録は省略しない。
- **doc 変更でも、ワークフロー規約・設計方針など実質的な内容は Issue 対象**。Issue 不要なのは
  typo・誤字・文言の微修正など些細なものに限る。
- 挙動不変で Issue を省く場合のブランチは番号なしを許可する（例 `docs/readme-wording`、
  `hotfix/fix-typo`）。PR 本文に変更理由を書き、記録とする。

### Issue 前の着手（許可と条件）

Issue 作成前に着手してよい（会話・探索で方針を詰めてから起票する流れを許可する）。
Issue⇄PR の紐付けは PR 作成時に成立する（commit に Issue 番号は不要）ため、着手が先でも問題ない。
ただし次を守る:

1. 着手時に **feature ブランチを切る**（`master` へ直接 commit しない）。
2. 挙動変更で Issue が必要な場合は **PR 作成前までに Issue を作成**し `Closes #N` で紐付ける。
3. 挙動変更で緊急（hotfix）なら起票を後回しにしてよいが、**マージまでに Issue を作成**する。

## ブランチ運用

### 禁止事項

1. **default ブランチ（`master`）で直接作業しないこと** — 必ず feature ブランチを作成してから作業する。
2. **default ブランチへ直接 push しないこと** — 変更は必ず PR 経由でマージする。

### ブランチ命名規則

| 種別 | 形式 |
|------|------|
| Feature | `feature/<issue-number>-<short-description>` |
| Bugfix | `bugfix/<issue-number>-<short-description>` |
| Hotfix | `hotfix/<issue-number>-<short-description>` |
| Documentation | `docs/<issue-number>-<short-description>` |

- 作業開始前に、現在のブランチが default ブランチ（`master`）でないことを確認する。該当する場合は上記命名規則で feature ブランチを作成してから着手する。

### Issue 番号の後付け

Issue より先に着手してブランチを切ると、ブランチ名の番号が未確定になる。

- **原則として、Issue 採番後すみやかにブランチを命名規則 `<type>/<issue-number>-...` へ rename する。**
  PR 前ならレビュアーも PR も無く低摩擦（未 push なら `git branch -m <new>`、push 済みなら
  新ブランチを push し旧ブランチを削除）。これでブランチ名が Issue を自己説明し、命名規則・追跡性を保てる。
- rename が現実的でない例外時のみ、フォールバックとして `/ticket-pr-publish` に `#<issue-number>` を
  引数で渡して紐付ける（ブランチ名は規則から外れたまま残る点に注意）。

## PR 運用

PR は Issue と双方向に辿れる状態を必須とする。「Issue → PR → Commit」「Commit → PR → Issue」の両方向を GitHub 上に残すことが目的。

### Issue との紐付け（必須）

- PR は必ず対応する Issue に紐付ける。**PR 本文**に closing keyword を 1 行入れる:

  ```
  Closes #<issue-number>
  ```

  `Fixes #<n>` / `Resolves #<n>` でも可。

- **紐付けは PR 本文に書く。** ブランチ名や commit メッセージでは Issue⇄PR の双方向リンクは作られない。
  - ブランチ名 `feature/<n>-...` に番号を含めても GitHub はリンクを生成しない（人間が読むためのラベル）。
  - commit メッセージの `#<n>` は Issue を参照（mention）するだけで、その PR は Issue の linked pull request として表示されない。

### default ブランチ制約

- closing keyword はマージ先が **default ブランチ（`master`）** のときのみ発火する。
- default 以外のブランチを base にした PR では keyword は無視されリンクが生成されない。その場合は GitHub の Development サイドバーから手動で Issue を紐付ける。

### 作成例

```
gh pr create \
  --base master \
  --title "<type(scope): subject>" \
  --body "Closes #<issue-number>

<変更概要 / なぜ>"
```

- `--base` は default ブランチ（`master`）を指定する。
- タイトルは `type(scope): subject` 形式（→ git-commit skill）に揃える。
- PR テンプレート（`.github/PULL_REQUEST_TEMPLATE.md`）がある場合はその構造に沿い、`Closes #` を必ず埋める。

### 根拠

GitHub 公式ドキュメント [Linking a pull request to an issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue) による。closing keyword は `close/closes/closed`, `fix/fixes/fixed`, `resolve/resolves/resolved`。default ブランチ以外を対象とした PR では keyword は無視される。
