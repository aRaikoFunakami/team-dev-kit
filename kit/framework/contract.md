# チーム開発の契約（team-dev-kit 管理）

このファイルは team-dev-kit が配布・更新する **共通契約**。プロジェクトは編集しない
（編集しても bootstrap 再実行で置換される。改善は本体リポジトリへ Issue / PR で還元する）。
プロジェクト固有の規約は、このファイルを取り込む `AGENTS.md` 側に書く。

## 1. 常時守る契約（最重要）

- 変更は **1ステップずつ** 入れて、直後に必ず検証（tests/metrics）する
- 長時間処理（SSE/WS 等）は **自動で終わる** こと（timeout / close / スコープ制限）を最優先する
- コミットは **1コミット＝1論点**、メッセージは `type(scope): subject` を厳守する
- 作成・更新したファイルの先頭にファイル概要コメントを記載し、更新時は常にアップデートする
- 挙動を変える変更は Issue に基づき、`master`/`main` へ直接 commit/push せず必ず feature ブランチ + PR を経由する

## 2. skill（必要なときに自動で読まれる手続き的ルール）

| skill | いつ起動するか |
|-------|----------------|
| **git-commit** | コミットメッセージを作成・生成するとき（条件発火） |
| **github-workflow** | GitHub を操作するとき（条件発火） |
| **doc-writing** | 設計ドキュメント・技術文書を作成・更新するとき（条件発火） |
| **ticket-template / draft / publish / pr-publish** | チケット下書きの作成・発行・PR 化（条件発火） |

> 導入・更新は `bootstrap.sh`（curl 再実行）で行う。skill は `.claude/skills/` に配置され自動で読まれる。

## 3. 秘密情報・個人情報スキャン

- 人間の `git commit` は `.githooks/pre-commit`（gitleaks）が、Claude の `gh` 発行前は PreToolUse フックが走査する
- 検出ルールは `.team-dev-kit/base.gitleaks.toml`（編集しない）。プロジェクト固有の allowlist は `.gitleaks.toml` に足す
- 仕組みと運用の詳細: https://github.com/aRaikoFunakami/team-dev-kit/blob/main/docs/secret-scan.md
