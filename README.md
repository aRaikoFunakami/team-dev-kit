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

- `.githooks/pre-commit` + `.gitleaks.toml` — 人間の `git commit` を止める（Claude フックは人間の端末に届かない）
- `.github/` — Issue/PR テンプレ（GitHub 機能）
- `AGENTS.md` — commit された契約。`<!-- team-dev-kit:start/end -->` の managed-block だけ同期し、プロジェクト固有節は温存
- `docs/secret-scan.md` — スキャン設計

provenance は消費側に commit する `.team-dev-kit.lock`（kit version + 管理ファイル hash）。これで 3-way 更新と改善検出ができる。

## ライフサイクル

| フェーズ | Plane A | Plane B | ゲート |
|---------|---------|---------|--------|
| 導入 | `.claude/settings.json` に marketplace+plugin を commit → clone で自動有効 | `/kit-init` で配置 + lock | PR |
| 運用 | skill 自動発火・egress フック | git pre-commit が秘密情報を止める | PR テンプレ |
| 更新 | `/plugin update` | `/kit-update`（3-way merge） | PR |
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

M0 構造+manifest（済）。M1 plugin 出荷 → M2 kit-init+lock → M3 kit-update → M4 kit-contribute。
詳細は `AGENTS.md`。
