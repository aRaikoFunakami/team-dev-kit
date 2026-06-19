# GitHub 運用ルール（旧・人間運用版）

> 🕰️ **これは team-dev-kit 導入前のサンプルです。**
> いまはこの運用契約を `github-workflow` skill が保持し、「取りかかって」「PR 出して」と
> 言うだけでブランチ作成・Issue/PR 紐付け・直 push 禁止が自動で守られます。
> 現役の挙動は [`kit/skills/github-workflow/SKILL.md`](../../kit/skills/github-workflow/SKILL.md) を参照。
>
> 現場ではこのドキュメントを「ブランチ運用」と「Issue/PR 運用」の 2 本に
> 分けて持っていたチームも多いはずです。

---

本リポジトリにおける GitHub の運用契約を定める。迷ったら `AGENTS.md` の方針を優先する。

## ツール

- GitHub 操作（接続・起票・閲覧・PR 等）には必ず `gh` コマンドを使う。
- ブラウザ操作や Web UI を前提とした手順を記述・依頼しない。

## default ブランチの扱い

- 本文では default ブランチを `main` と表記する。
- 歴史的経緯: 古いリポジトリは `master`、GitHub で新規作成したリポジトリは `main`。現場には両方ある。
- **実際の default ブランチは必ず動的判定する:**

  ```bash
  gh repo view --json defaultBranchRef -q .defaultBranchRef.name
  ```

  `master` のリポジトリでも本ルールはそのまま機能する。

## Issue ベース開発

- 挙動を変える変更（バグ修正・機能追加・ロジック/API 変更）は **Issue の内容に基づいて** 実施する。
- Issue 起票時は、実装者が追加質問なしで着手できる粒度まで技術仕様を書く
  （対象ファイル・変更方針・受け入れ条件を含む）。曖昧な要望のまま起票しない。
  → 書き方は [03-issue-authoring.md](03-issue-authoring.md)。

### Issue の要否（規模ではなく性質で決める）

| 変更の性質 | Issue | branch + PR |
|---|---|---|
| 挙動不変かつ些細（typo・文言微修正・コメント・整形） | 不要 | 必須（番号なしブランチ可、`Closes` なし、PR 本文が記録） |
| 挙動変更（バグ・ロジック・API、hotfix 含む）、実質的な doc/規約変更 | 必要 | 必須（`Closes #N` で紐付け） |

- 線引きは「**挙動を変えるか**」。数行の hotfix でも挙動を変えるなら Issue を作る。
- **branch + PR は性質によらず常に必須。** default ブランチへの直接 commit/push は禁止。
  Issue を省けるのは「挙動不変かつ些細」のときだけで、PR による記録は省略しない。

### Issue 前の着手（許可と条件）

会話・探索で方針を詰めてから起票してよい。ただし:

1. 着手時に **feature ブランチを切る**（default ブランチへ直接 commit しない）。
2. 挙動変更で Issue が必要なら **PR 作成前までに Issue を作成**し `Closes #N` で紐付ける。
3. 緊急 hotfix は起票を後回しにしてよいが、**マージまでに Issue を作成**する。

## ブランチ運用

### 禁止事項

1. **default ブランチ（`main`）で直接作業しない。** 必ず feature ブランチを作ってから着手する。
2. **default ブランチへ直接 push しない。** 変更は必ず PR 経由でマージする。

### 命名規則

| 種別 | 形式 |
|---|---|
| Feature | `feature/<issue-number>-<short-description>` |
| Bugfix | `bugfix/<issue-number>-<short-description>` |
| Hotfix | `hotfix/<issue-number>-<short-description>` |
| Documentation | `docs/<issue-number>-<short-description>` |

- 着手前に、現在のブランチが default ブランチでないことを確認する。

### Issue 番号の後付け

Issue より先に着手すると番号が未確定になる。原則、採番後すみやかに
`<type>/<issue-number>-...` へ rename する（未 push なら `git branch -m <new>`、
push 済みなら新ブランチを push し旧を削除）。

## PR 運用

PR は Issue と双方向に辿れる状態を必須とする。

### Issue との紐付け（必須）

- **PR 本文**に closing keyword を 1 行入れる:

  ```
  Closes #<issue-number>
  ```

  `Fixes #<n>` / `Resolves #<n>` でも可。

- **紐付けは PR 本文に書く。** ブランチ名や commit メッセージでは双方向リンクは作られない。
  - ブランチ名 `feature/<n>-...` の番号は人間が読むラベルにすぎない。
  - commit の `#<n>` は Issue を mention するだけで linked PR にはならない。

### default ブランチ制約

- closing keyword はマージ先が **default ブランチ** のときのみ発火する。
- default 以外を base にした PR では keyword は無視される。その場合は GitHub の
  Development サイドバーから手動で Issue を紐付ける。

### 作成例

```bash
BASE="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)"
gh pr create \
  --base "$BASE" \
  --title "<type(scope): subject>" \
  --body "Closes #<issue-number>

<変更概要 / なぜ>"
```

- `--base` は決め打ちせず動的取得する（`main` / `master` どちらでも動く）。
- タイトルは `type(scope): subject` 形式に揃える（→ [01-commit-convention.md](01-commit-convention.md)）。

### 根拠

GitHub 公式 [Linking a pull request to an issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue)。
closing keyword は `close/closes/closed`, `fix/fixes/fixed`, `resolve/resolves/resolved`。
default ブランチ以外を対象とした PR では keyword は無視される。
