<!-- team-dev-kit:start — このブロックは /kit-update が管理する。内側を手で編集しない。プロジェクト固有の記述はブロックの外に書く。 -->
# AGENTS.md — チーム開発の契約

このリポジトリで AI エージェントと人間が作業するための **契約**。迷ったらこのファイルを最優先する。
ベンダー中立の標準ファイル名（`AGENTS.md`）を使う。Claude Code は `CLAUDE.md` から、他エージェントは各自の設定から本ファイルを参照する。

導入元: [team-dev-kit](https://github.com/aRaikoFunakami/team-dev-kit)。更新は `/kit-update`、改善の還元は `/kit-contribute`。

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
| **kit-init / update / contribute / doctor** | kit のライフサイクル操作（`/kit-*` 明示発火のみ） |

## 3. 参考ドキュメント

- 秘密情報・個人情報スキャン（pre-commit / PreToolUse フックの仕組み・allowlist の足し方）は
  → [docs/secret-scan.md](docs/secret-scan.md)
<!-- team-dev-kit:end -->

<!-- ここから下はプロジェクト固有。/kit-update はこの領域に触れない。 -->
## プロジェクト固有の規約

（プロジェクト概要・起動方法・固有ルールをここに追記する）
