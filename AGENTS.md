# AGENTS.md — team-dev-kit 開発の契約

team-dev-kit リポジトリ自身の開発契約。kit は自分のルールを dogfood する。

## このリポジトリの構造

- `.claude-plugin/marketplace.json` — マーケットプレイス定義（このリポジトリ = marketplace）
- `plugins/team-dev-kit/` — Plane A（Claude ランタイム資産）
  - `skills/` — 業務 skill（条件発火）+ kit-* skill（明示発火のみ。M2 以降で追加）
  - `hooks/hooks.json` — PreToolUse egress フック（自動・ガードレール）
  - `scripts/` — egress-scan.sh ほか。同期エンジンは M2 で追加
- `templates/` — Plane B（消費プロジェクトに commit される真実のファイル）
  - `AGENTS.md`（managed-block）, `.githooks/pre-commit`, `.gitleaks.toml`, `.github/`, `docs/`
- `dev/` — 開発参照（`legacy-install.sh` = M2 同期エンジンの元ネタ）
- `tests/` — smoke テスト（M2 以降）

## 契約

- 変更は 1 ステップずつ。`type(scope): subject` の 1 コミット 1 論点
- 挙動を変える変更は feature ブランチ + PR。`main` へ直接 push しない
- plugin の挙動を変えたら `plugins/team-dev-kit/.claude-plugin/plugin.json` の `version` を semver で bump する
- Plane B のファイルを変えたら、消費側は `/kit-update` で 3-way merge して取り込む前提で書く（managed-block マーカーを壊さない）
- 秘密情報スキャンの設計は `templates/docs/secret-scan.md`

## マイルストーン

M0 構造+manifest（済） → M1 plugin 出荷 → M2 kit-init+lock → M3 kit-update(3-way) → M4 kit-contribute。
