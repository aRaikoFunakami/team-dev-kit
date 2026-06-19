# AGENTS.md — team-dev-kit 開発の契約

team-dev-kit リポジトリ自身の開発契約。kit は自分のルールを dogfood する。

## このリポジトリの構造

- `bootstrap.sh` — **唯一の導入/更新導線**。consumer の repo で `curl | sh` し、skill・ガードレール・glue を配置する
- `plugins/team-dev-kit/` — 配布物の真実（bootstrap が読むソースツリー）
  - `skills/` — 業務 skill（条件発火）。consumer の `.claude/skills/` へコピーされる
  - `scripts/egress-scan.sh` — PreToolUse egress フック本体（consumer の `.team-dev-kit/` へコピー）
  - `framework/` — **B1: consumer に commit・編集禁止**。`contract.md`, `base.gitleaks.toml`, `pre-commit`。bootstrap 再実行（`--force`）が置換
  - `config-starters/` — **B2: 1回だけ配置・以後 kit 触禁止**。`AGENTS.md`(@import), `gitleaks.toml`(extend), `github/*`
- `docs/secret-scan.md` — スキャン設計（**配布対象外**。kit repo 内のみ）
- `tests/` — `smoke.sh`（bootstrap の E2E）+ `fixtures/`

## 契約

- 変更は 1 ステップずつ。`type(scope): subject` の 1 コミット 1 論点
- 挙動を変える変更は feature ブランチ + PR。`main` へ直接 push しない
- **framework/** を変えたら consumer は bootstrap 再実行（`--force`）で置換取り込み（編集されない前提）。**config-starters/** は install-once（既存があれば glue のみ注入し再配置しない）
- consumer 側の glue: `AGENTS.md` が `@.team-dev-kit/contract.md` を import、`.gitleaks.toml` が `.team-dev-kit/base.gitleaks.toml` を extend。既存ファイルがある場合 bootstrap が glue を冪等注入する
- 業務 skill を追加/削除したら `bootstrap.sh` の配布対象（`skills/` 走査・`kit-*` 除外）と `tests/smoke.sh` の本数アサーションを確認する
- 秘密情報スキャンの設計は `docs/secret-scan.md`

## サンドボックス

実装したスキルとHook等は ./sandbox-team-dev-kit で実際にテストすることで有効性を確かめること

