---
name: git-commit
description: コミットメッセージを作成・生成するときに起動する。type(scope): subject 形式、1コミット1論点、subject は「コミット後に成立する振る舞い」を書く、本文は理由・設計判断・互換性/セキュリティ影響のみ、BREAKING CHANGE の明記といった本リポジトリのコミット規約を与える。「コミットして」「commit message を書いて」等で発火。
---

<!--
概要: コミットメッセージ規約 skill。type(scope): subject 形式と本文ルールを与える。
旧 instructions 配下のコミット規約を移植したもの。コミット作成のたびに参照する。
-->

# コミットメッセージルール

## 原則

コミットログはコミット作成者のためではなく、将来 git log を読む開発者と ChangeLog 作成者のために残す。

コミットメッセージは「何を変更したか」ではなく、「コミット後に成立する仕様・振る舞い」を記述する。

コミットメッセージを生成する前に、必ず git diff と最近のコミット履歴を確認し、既存プロジェクトのスタイルに合わせること。

Issue との紐付けはコミットメッセージではなく PR 本文の closing keyword（`Closes #<n>` 等）で行う。コミットメッセージに `#<n>` を書いても Issue⇄PR の双方向リンクは生成されない（→ github-workflow skill）。

## フォーマット

```
type(scope): subject
```

### type

feat | fix | refactor | perf | test | docs | chore | ci | build | revert

### scope

影響範囲が特定できる名前を使用する。

例: core / api / auth / ui / web / android / ios / config / infra

### subject

必須:

- 1行で書く
- 72文字以内を推奨
- コミット後に成立する仕様・振る舞いを書く
- ChangeLog にそのまま掲載できる内容にする

良い例:

```
fix(auth): allow passwords longer than 20 characters
fix(auth): refresh expired access tokens automatically
feat(cache): cache OpenAPI schema for offline startup
perf(search): avoid duplicate database queries
fix(ui): keep dialog position after window resize
feat(config): support environment-specific settings
```

悪い例:

```
fix(auth): fix login bug
fix(auth): update authentication logic
feat(api): change user endpoint
perf(search): improve performance
refactor(core): improve parser
refactor(core): cleanup code
chore(config): update settings
fix(ui): fix issue
```

### 本文

本文は必要な場合のみ書く。diff を見れば分かる実装内容は書かない。以下のような情報のみを書く。

- なぜ変更が必要だったか
- 重要な設計判断
- 運用上の注意
- 互換性への影響
- セキュリティ上の影響

良い例:

```
fix(auth): refresh expired access tokens automatically

Users were frequently logged out after long periods
of inactivity because expired access tokens were not
refreshed before API requests.
```

悪い例:

```
fix(auth): refresh expired access tokens automatically
- added TokenService
- added RefreshRequest
- updated AuthClient
```

### テスト

テスト結果を書く場合は実際に実行したコマンドを記載する。

```
Tests:
- npm test
- pnpm lint
```

未実行の場合:

```
Tests:
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

- 1コミットに複数の論点を含める
- 未実行のテストを実行済みと記載する
- APIキー、トークン、個人情報、顧客情報を書く
- 脆弱性の再現手順を書く
- AIへの指示やプロンプトを書く
- AIとの会話内容を書く
- 「AIが生成した」と記載する
- diff の要約だけを書く
- fix bug、update、improve、cleanup のような抽象的な説明だけで終わらせる

## 最終チェック

- subject は変更作業ではなく結果を書いているか
- subject だけで変更目的が理解できるか
- 1コミット1論点になっているか
- 本文は diff の説明になっていないか
- テスト結果は事実のみを書いているか
- BREAKING CHANGE があれば記載しているか
