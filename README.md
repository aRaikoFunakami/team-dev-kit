# team-dev-kit

チーム開発の **決まりごと（ルール・ワークフロー）と人為ミス排除のガードレール** を、
Claude Code を前提に多数のリポジトリへ配り、更新し、現場の改善を吸い上げる kit。

狙い:

- **オンボーディングの即時化** — ルールを知らない初心者が clone 直後からルール通りに開発を始められる
- **人為ミスの排除** — 秘密情報・個人情報の漏洩を、人間の `git commit`（pre-commit）と Claude の外部発行（PreToolUse フック）の二経路で機械的に止める

## アーキテクチャ: 2 平面

実行境界が違うので 1 つの配布物にせず 2 平面に分ける。

### Plane A — Claude ランタイム資産（plugin + marketplace）
`plugins/team-dev-kit/` を Claude Code プラグインとして配る。skill・PreToolUse フックを含む。
配布/更新は `/plugin` がネイティブに行う（バージョン管理つき）。リポジトリツリーにはコピーしない。

- 業務 skill（条件発火）: `git-commit`, `github-workflow`, `doc-writing`, `ticket-*`
- kit-* skill（**`/kit-*` 明示発火のみ**・M2 以降）: `kit-init`, `kit-update`, `kit-contribute`, `kit-doctor`
- フック（自動・ガードレール）: PreToolUse egress（gh 発行前の秘密情報スキャン）

### Plane B — リポジトリに commit すべきファイル（テンプレ同期 + lockfile）
`templates/` 配下。これらは **人間や GitHub に効かせる必要**があり plugin では配れない。

Plane B はさらに 2 種に分かれる（設定するもの／そのまま使うものの分離）:

- **framework（共通・編集禁止）** — `/kit-update` が**置換**する:
  - `.team-dev-kit/contract.md` — チーム共通契約
  - `.team-dev-kit/base.gitleaks.toml` — スキャンルール
  - `.githooks/pre-commit` — 人間の `git commit` を止める（Claude フックは人間の端末に届かない）
- **config（プロジェクトが書く・install-once）** — kit は再配置しない:
  - `AGENTS.md` — `@.team-dev-kit/contract.md` を import + プロジェクト固有節
  - `.gitleaks.toml` — `.team-dev-kit/base.gitleaks.toml` を extend + プロジェクト固有 allowlist
  - `.github/*` — Issue/PR テンプレ

glue は読み手で使い分ける: agent 向け契約は `@import`、gitleaks は `[extend].path`。これで framework は誰も触らず置換で更新でき、config は kit が触らない。

provenance は消費側に commit する `.team-dev-kit.lock`（version + framework hash + config 一覧）。framework は drift 検出・置換、config は install-once 判定に使う。

## ライフサイクル

| フェーズ | Plane A | Plane B | ゲート |
|---------|---------|---------|--------|
| 導入 | `.claude/settings.json` に marketplace+plugin を commit → clone で自動有効 | `/kit-init` で配置 + lock | PR |
| 運用 | skill 自動発火・egress フック | git pre-commit が秘密情報を止める | PR テンプレ |
| 更新 | `/plugin update` | `/kit-update`（framework を置換・config は不可侵） | PR |
| 還元 | — | `/kit-contribute`（差分検出 → kit へ PR） | PR |

更新も還元も **PR が唯一のレビュー境界**。プロジェクト間の直コピーは禁止。

## 導入（M1 出荷後）

消費プロジェクトの `.claude/settings.json`（commit する）:
```json
{
  "extraKnownMarketplaces": {
    "team-dev-kit": { "source": { "source": "github", "repo": "aRaikoFunakami/team-dev-kit" } }
  },
  "enabledPlugins": { "team-dev-kit@team-dev-kit": true }
}
```
clone → trust → skill が自動で有効。続いて `/kit-init` で Plane B を配置。

開発中はローカル marketplace で検証:
```
/plugin marketplace add ./team-dev-kit
/plugin install team-dev-kit@team-dev-kit
```

## ステータス

M0〜M5 実装済（plugin・lockfile・kit-init/update/contribute/doctor、framework/config 分離、@import、gitleaks overlay→base）。
検証: `sh tests/smoke.sh`（29 アサーション全通過）。
残: marketplace 公開（rollout 判断）、Claude Code 上での `/plugin` 実機確認。詳細は `AGENTS.md`。
