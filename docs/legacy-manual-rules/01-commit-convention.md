# コミット規約（旧・人間運用版）

> 🕰️ **これは team-dev-kit 導入前のサンプルです。**
> いまはこの規約を `git-commit` skill が保持し、「コミットして」と言うだけで
> 自動的に正しい形を提案します。人が暗記する必要はありません。
> 現役の挙動は [`kit/skills/git-commit/SKILL.md`](../../kit/skills/git-commit/SKILL.md) を参照。

---

## 原則

コミットログはコミット作成者のためではなく、将来 `git log` を読む開発者と
ChangeLog 作成者のために残す。

コミットメッセージは「何を変更したか」ではなく、
**コミット後に成立する仕様・振る舞い**を記述する。

メッセージを書く前に、必ず `git diff` と最近のコミット履歴を確認し、
既存プロジェクトのスタイルに合わせること。

Issue との紐付けはコミットメッセージではなく **PR 本文の closing keyword**
（`Closes #<n>` 等）で行う。コミットメッセージに `#<n>` を書いても
Issue⇄PR の双方向リンクは生成されない（→ [02-github-workflow.md](02-github-workflow.md)）。

## フォーマット

```
type(scope): subject
```

### type

`feat` | `fix` | `refactor` | `perf` | `test` | `docs` | `chore` | `ci` | `build` | `revert`

### scope

影響範囲が特定できる名前を使う。例: `core` / `api` / `auth` / `ui` / `web` / `android` / `ios` / `config` / `infra`

### subject

- 1 行で書く
- 72 文字以内を推奨
- コミット後に成立する仕様・振る舞いを書く
- ChangeLog にそのまま掲載できる内容にする

良い例:

```
fix(auth): allow passwords longer than 20 characters
fix(auth): refresh expired access tokens automatically
feat(cache): cache OpenAPI schema for offline startup
perf(search): avoid duplicate database queries
```

悪い例:

```
fix(auth): fix login bug
feat(api): change user endpoint
refactor(core): cleanup code
fix(ui): fix issue
```

### 本文

必要な場合のみ書く。diff を見れば分かる実装内容は書かない。書くのは次のみ。

- なぜ変更が必要だったか
- 重要な設計判断
- 運用上の注意
- 互換性への影響
- セキュリティ上の影響

### テスト

テスト結果を書く場合は実際に実行したコマンドを記載する。未実行なら理由を書く。

```
Tests:
- npm test
- not run (reason: documentation change only)
```

### BREAKING CHANGE

互換性を壊す変更や移行が必要な変更は必ず明記する。

```
feat(config): require explicit database pool size

BREAKING CHANGE:
DATABASE_POOL_SIZE is now required.
Deployments without this variable will fail during startup.
```

## 禁止事項

- 1 コミットに複数の論点を含める
- 未実行のテストを実行済みと記載する
- API キー・トークン・個人情報・顧客情報を書く（→ [05-secret-handling.md](05-secret-handling.md)）
- 脆弱性の再現手順を書く
- diff の要約だけを書く
- `fix bug` / `update` / `improve` / `cleanup` のような抽象的な説明だけで終わらせる

## 最終チェック

- [ ] subject は変更作業ではなく結果を書いているか
- [ ] subject だけで変更目的が理解できるか
- [ ] 1 コミット 1 論点になっているか
- [ ] 本文は diff の説明になっていないか
- [ ] テスト結果は事実のみを書いているか
- [ ] BREAKING CHANGE があれば記載しているか
