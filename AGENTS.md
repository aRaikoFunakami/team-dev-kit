# AGENTS.md — team-dev-kit 開発の契約

team-dev-kit リポジトリ自身の開発契約。kit は自分のルールを dogfood する。

## このリポジトリの構造

- `.claude-plugin/marketplace.json` — マーケットプレイス定義（このリポジトリ = marketplace）
- `plugins/team-dev-kit/` — Plane A（Claude ランタイム資産）+ 配布物の真実
  - `skills/` — 業務 skill（条件発火）+ kit-* skill（`/kit-*` 明示発火のみ）
  - `hooks/hooks.json` — PreToolUse egress フック（自動・ガードレール）
  - `scripts/` — `egress-scan.sh`, `kit-sync.py`（同期エンジン）
  - `framework/` — **B1: consumer に commit・編集禁止**。`contract.md`, `base.gitleaks.toml`, `pre-commit`。`/kit-update` が置換
  - `config-starters/` — **B2: init で1回だけ配置・kit 触禁止**。`AGENTS.md`(@import), `gitleaks.toml`(extend), `github/*`
- `docs/secret-scan.md` — スキャン設計（**配布対象外**。kit repo 内のみ）
- `dev/` — 開発参照（`legacy-install.sh`）
- `tests/` — `smoke.sh` + `fixtures/`

## 契約

- 変更は 1 ステップずつ。`type(scope): subject` の 1 コミット 1 論点
- 挙動を変える変更は feature ブランチ + PR。`main` へ直接 push しない
- plugin の挙動を変えたら `plugins/team-dev-kit/.claude-plugin/plugin.json` と `marketplace.json` の `version` を semver で bump する
- **framework/** を変えたら consumer は `/kit-update` で置換取り込み（編集されない前提）。**config-starters/** は install-once（kit は再配置しない）
- consumer 側の glue: `AGENTS.md` が `@.team-dev-kit/contract.md` を import、`.gitleaks.toml` が `.team-dev-kit/base.gitleaks.toml` を extend
- 秘密情報スキャンの設計は `docs/secret-scan.md`

## サンドボックス

実装したスキルとHook等は ./sandbox-team-dev-kit で実際にテストすることで有効性を確かめること

