# team-dev-kit アーキテクチャ

チーム開発の **決まりごと（ルール・ワークフロー）と人為ミス排除のガードレール** を、Claude Code を前提に
多数のリポジトリへ配り、更新し、現場の改善を吸い上げる kit。本ドキュメントは設計全体像・コンポーネント・
データフローをまとめる。

## 1. 設計の狙い

- **オンボーディングの即時化** — ルールを知らない初心者が clone 直後からルール通りに開発を始められる
- **人為ミスの排除** — 秘密情報・個人情報の漏洩を、人間の `git commit`（pre-commit）と Claude の外部発行
  （PreToolUse フック）の二経路で機械的に止める

## 2. いちばん大事な考え方: 2 つのレイヤー (Plane A / Plane B)

この kit が配るものは、大きく **2 つのレイヤー（層）** に分かれている。

- **Plane A** = Claude（AI）に渡す道具のレイヤー
- **Plane B** = リポジトリに置いて人間と GitHub に効かせるレイヤー

なぜ 2 つに分けるか。「誰に効かせるか」「どう配って、どう新しくするか」がまったく違うから。
ひとつの箱にまとめると、片方を直したいだけなのに両方を壊しかねない。だから最初から別々にしている。

| | Plane A（Claude ランタイム資産） | Plane B（リポジトリ commit ファイル） |
|---|---|---|
| 配布 | plugin marketplace | `git commit` |
| 更新 | `/plugin update`（ネイティブ） | `/kit-update`（framework 置換）/ install-once（config） |
| 配置先 | plugin 配下（リポジトリツリー外） | `.team-dev-kit/`, `.githooks/`, `AGENTS.md`, `.gitleaks.toml`, `.github/` |
| 効かせる相手 | Claude | 人間の `git commit`・GitHub |
| 中身 | skill・PreToolUse フック・同期エンジン・テンプレ原本 | framework（共通・編集禁止）・config（プロジェクト所有） |

**もう少しかみくだくと**: Plane A は Claude に「やり方」を教える道具なので、リポジトリの履歴に残さず、
すぐ使える状態で届けたい。Plane B は人間の commit や GitHub への投稿をその場で止める番人なので、
リポジトリに置いて clone した人みんなに残らないと意味がない。役割が逆向きなので一緒にできない。

### Plane B はさらに 2 種類: framework と config

Plane B の中身も「全員で共有して触らないもの（framework）」と「各プロジェクトが自由に書くもの（config）」に
分かれる。これも理由は同じで、勝手に上書きしてよいか／ダメかが正反対だから。

| | framework（共通・編集禁止） | config（プロジェクトが書く・install-once） |
|---|---|---|
| 所有 | kit | プロジェクト（消費側） |
| 編集 | 禁止（契約違反） | 期待・推奨 |
| 更新 | `/kit-update` が**置換**（3-way merge なし） | kit は再配置しない（新規 starter のみ追加） |
| 還元 | `/kit-contribute` で kit へ PR | 還元しない（プロジェクト固有） |
| 例 | `contract.md`, `base.gitleaks.toml`, `pre-commit` | `AGENTS.md`, `.gitleaks.toml`, `.github/*` |

この 2 種類を裏でつなぐ仕組み（**glue＝のりづけ役**）は、読む相手によって 2 通り使い分ける:

- **`@import`**（agent 向け契約）: `AGENTS.md` が `@.team-dev-kit/contract.md` を取り込む
- **`[extend].path`**（gitleaks）: `.gitleaks.toml` が `.team-dev-kit/base.gitleaks.toml` を extend

これで framework は誰も触らず置換で更新でき、config は kit が触らない。

## 3. アーキテクチャダイアグラム

```mermaid
graph TB
    subgraph KIT["team-dev-kit リポジトリ (upstream)"]
        subgraph PA["Plane A — plugins/team-dev-kit/ (plugin)"]
            SK["skills/<br/>業務skill: git-commit, github-workflow,<br/>doc-writing, ticket-*<br/>kit-* skill: init/update/contribute/doctor"]
            HK["hooks/hooks.json<br/>PreToolUse: egress-scan.sh"]
            SC["scripts/<br/>kit-sync.py (同期エンジン)<br/>egress-scan.sh (発行ゲート)"]
            FW["framework/ (原本・共通)<br/>contract.md<br/>base.gitleaks.toml<br/>pre-commit"]
            CS["config-starters/ (原本・雛形)<br/>AGENTS.md, gitleaks.toml, github/*"]
        end
        MP[".claude-plugin/marketplace.json"]
    end

    subgraph CONSUMER["消費リポジトリ (consumer)"]
        subgraph PBfw["Plane B — framework (編集禁止)"]
            CFW[".team-dev-kit/contract.md<br/>.team-dev-kit/base.gitleaks.toml<br/>.githooks/pre-commit"]
        end
        subgraph PBcfg["Plane B — config (プロジェクト所有)"]
            CCFG["AGENTS.md  @import→ contract.md<br/>.gitleaks.toml [extend]→ base<br/>.github/ISSUE_TEMPLATE/*, PR template"]
        end
        LOCK[".team-dev-kit.lock<br/>version + framework hash + config 一覧"]
        SETTINGS[".claude/settings.json<br/>marketplace + enabledPlugins"]
    end

    MP -.->|/plugin install| SETTINGS
    PA -.->|Claude にロード| CONSUMER
    FW ==>|/kit-init 配置 ・ /kit-update 置換| CFW
    CS ==>|/kit-init で1回だけ配置| CCFG
    SC -->|hash 記録/照合| LOCK
    CFW -.->|drift 検出| LOCK
    CCFG -.->|install-once 判定| LOCK
    CFW -->|/kit-contribute 差分| FW

    HUMAN["👤 人間"] -->|git commit| GATE1
    GATE1["L1: .githooks/pre-commit<br/>gitleaks protect --staged"] -->|clean| GITHIST["git 履歴"]
    GATE1 -.->|秘密検出 exit1| BLOCK1["❌ commit 拒否"]

    CLAUDE["🤖 Claude"] -->|gh issue/pr create| GATE3
    GATE3["L3: PreToolUse egress-scan.sh<br/>gitleaks detect (--title/--body)"] -->|clean| GH["GitHub Issue/PR"]
    GATE3 -.->|秘密検出 exit2| BLOCK3["❌ 発行拒否"]
```

## 4. コンポーネント

### 4.1 Plane A — plugin (`plugins/team-dev-kit/`)

| パス | 役割 |
|------|------|
| `.claude-plugin/plugin.json` | plugin メタ（name, version, skills dir, hooks file） |
| `skills/` | 11 skill（業務 skill = 条件発火、kit-* skill = `/kit-*` 明示発火のみ） |
| `hooks/hooks.json` | PreToolUse フック定義（matcher: Bash → `egress-scan.sh`） |
| `scripts/kit-sync.py` | Plane B 同期エンジン。init/update/contribute/doctor の実体 |
| `scripts/egress-scan.sh` | L3 発行ゲート。`gh issue/pr create` の本文を gitleaks スキャン |
| `framework/` | 消費側に配る共通ファイルの**原本**（編集禁止対象） |
| `config-starters/` | 消費側に1回だけ置く雛形の**原本**（プロジェクトが以後所有） |

**skill 2 分類**:
- 業務 skill（条件発火）: `git-commit`, `github-workflow`, `doc-writing`, `ticket-draft`,
  `ticket-template`, `ticket-publish`, `ticket-pr-publish`
- kit-* skill（`/kit-*` 明示発火のみ・誤爆防止）: `kit-init`, `kit-update`, `kit-contribute`, `kit-doctor`

### 4.2 Plane B — 消費リポジトリに commit されるファイル

| 配置先 | 種別 | 由来 | 更新 |
|--------|------|------|------|
| `.team-dev-kit/contract.md` | framework | `framework/contract.md` | 置換 |
| `.team-dev-kit/base.gitleaks.toml` | framework | `framework/base.gitleaks.toml` | 置換 |
| `.githooks/pre-commit` | framework | `framework/pre-commit`（+x） | 置換 |
| `AGENTS.md` | config | `config-starters/AGENTS.md` | install-once |
| `.gitleaks.toml` | config | `config-starters/gitleaks.toml` | install-once |
| `.github/ISSUE_TEMPLATE/*`, `PULL_REQUEST_TEMPLATE.md` | config | `config-starters/github/*` | install-once |
| `.team-dev-kit.lock` | provenance | `kit-sync.py` 生成 | init/update で更新 |

### 4.3 lockfile (`.team-dev-kit.lock`)

同期を賢くするための provenance（来歴）記録。消費側ルートに commit する。

```json
{
  "version": "0.1.0",
  "marketplace": "aRaikoFunakami/team-dev-kit",
  "framework": {
    ".team-dev-kit/contract.md":        { "sha": "<sha256>" },
    ".team-dev-kit/base.gitleaks.toml": { "sha": "<sha256>" },
    ".githooks/pre-commit":             { "sha": "<sha256>" }
  },
  "config": ["AGENTS.md", ".gitleaks.toml", ".github/ISSUE_TEMPLATE/bug.md", "..."]
}
```

- **framework hash** — 現ファイルの SHA256 が lock と不一致 → ローカル編集（drift）検出
- **config 一覧** — 既に置いた config を記録 → update 時は新規 starter のみ追加（install-once）
- **version** — kit の陳腐化を検出し `/kit-update` を促す

## 5. データフロー

### 5.1 kit-init（初回導入）

```mermaid
sequenceDiagram
    actor U as ユーザー
    participant S as kit-init skill
    participant P as kit-sync.py init
    participant FS as 消費リポジトリ
    participant G as git config

    U->>S: /kit-init
    S->>P: init --dry-run（プレビュー）
    P-->>S: 配置予定（framework / config / hooksPath）
    S->>P: init
    loop framework 各ファイル
        P->>FS: framework 原本を .team-dev-kit/ ・ .githooks/ へ書込（+x）
        P->>P: SHA256 を lock に記録
    end
    loop config-starters 各ファイル
        alt 既存
            P->>FS: スキップ（--force 時のみ上書き）
        else 新規
            P->>FS: 雛形を配置
            P->>P: lock の config 一覧に追加
        end
    end
    P->>G: core.hooksPath = .githooks（未設定時）
    P->>FS: .team-dev-kit.lock 書込
    S->>P: doctor（検証）
    P-->>U: ✅ healthy
    U->>FS: feature ブランチで commit → PR → merge
```

### 5.2 kit-update（framework 更新）

```mermaid
sequenceDiagram
    actor U as ユーザー
    participant PL as /plugin update
    participant S as kit-update skill
    participant P as kit-sync.py update
    participant FS as 消費リポジトリ

    U->>PL: /plugin update（Plane A を新版へ）
    U->>S: /kit-update
    S->>P: update --dry-run
    P-->>S: 旧→新 version、置換/drift-skip 予定
    S->>P: update
    loop framework 各ファイル
        alt 現 SHA == lock SHA（drift なし）
            P->>FS: 新版で置換
            P->>P: lock SHA 更新
        else 現 SHA != lock SHA（drift）
            P-->>U: ⚠ drift skip（要判断）
        end
    end
    loop config-starters
        alt lock に未記録（新 starter）
            P->>FS: 追加
        else 既存
            P->>FS: 触らない（install-once）
        end
    end
    P->>FS: lock の version / SHA 更新
    alt drift あり
        U->>U: 還元(/kit-contribute) か 破棄(--force) を選択
    end
    U->>FS: commit → PR → merge
```

### 5.3 kit-contribute（現場改善の還元）

framework のローカル改善のみ upstream へ。config は還元対象外。

```mermaid
sequenceDiagram
    actor U as ユーザー
    participant S as kit-contribute skill
    participant P as kit-sync.py contribute
    participant ST as staging (/tmp)
    participant K as kit リポジトリ (fork)

    U->>S: /kit-contribute
    S->>P: contribute（候補抽出）
    loop framework 各ファイル
        alt 現 SHA != lock SHA
            P-->>U: unified diff 表示（先頭 40 行）
        end
    end
    U->>S: 還元する候補を選択
    S->>P: contribute --staging /tmp/... --apply
    P->>ST: 承認分を framework/ レイアウトで書出
    U->>K: fork & ブランチ作成
    U->>K: staging → plugins/team-dev-kit/framework/ へコピー
    U->>K: draft PR（version bump はメンテナが実施）
    Note over K: merge + version bump 後、<br/>全消費側が /plugin update → /kit-update で伝播
```

### 5.4 秘密情報スキャン 2 ゲート (L1 / L3)

検出ルールは両ゲートとも gitleaks + `.gitleaks.toml`（`base.gitleaks.toml` を extend）で共通。

```mermaid
flowchart LR
    subgraph L1["L1: pre-commit（人間の経路）"]
        H["👤 git commit"] --> PC["gitleaks protect --staged"]
        PC -->|clean| HIST["git 履歴へ"]
        PC -->|秘密検出 exit1| XB1["❌ commit 拒否"]
    end
    subgraph L3["L3: PreToolUse（Claude の経路）"]
        C["🤖 gh issue/pr create"] --> ES["egress-scan.sh<br/>--title/--body/--body-file 抽出<br/>→ gitleaks detect"]
        ES -->|clean| GH["GitHub Issue/PR へ"]
        ES -->|秘密検出 exit2| XB3["❌ 発行拒否"]
        ES -->|パース失敗| XB3
    end
```

**L3 が必要な理由**: ドラフト置き場 `.issue_drafts/` は git-ignore（履歴に乗らない）ため L1 では見えない。
`gh` 発行は L3 が唯一のゲート。パース失敗時は fail-closed（exit 2）で漏洩を防ぐ。

## 6. ライフサイクル一覧

| フェーズ | Plane A | Plane B | ゲート |
|---------|---------|---------|--------|
| 導入 | `.claude/settings.json` に marketplace+plugin を commit → clone で自動有効 | `/kit-init` で配置 + lock | PR |
| 運用 | skill 自動発火・egress フック | git pre-commit が秘密情報を止める | PR テンプレ |
| 更新 | `/plugin update` | `/kit-update`（framework を置換・config は不可侵） | PR |
| 還元 | — | `/kit-contribute`（差分検出 → kit へ PR） | PR |

更新も還元も **PR が唯一のレビュー境界**。プロジェクト間の直コピーは禁止。

## 7. 技術スタック

| コンポーネント | 言語 | 用途 |
|---------------|------|------|
| `kit-sync.py` | Python 3 | 同期エンジン（SHA / JSON / ファイル I/O / git subprocess） |
| `egress-scan.sh` | Shell + Python 3 | L3 フック（JSON 入力解析・本文抽出・gitleaks 実行） |
| `pre-commit` | Shell | L1 フック（`gitleaks protect --staged`） |
| skill（`SKILL.md`） | Markdown | Claude への振る舞い指示（実行コードなし） |
| `tests/smoke.sh` | Shell | 全ライフサイクルの E2E（29 アサーション） |
| 設定/テンプレ | TOML / JSON / Markdown / YAML | `.gitleaks.toml`, `plugin.json`, `hooks.json`, 各テンプレ |

**外部依存**: `gitleaks`（秘密/個人情報スキャン）, `git`, `python3`, `gh`（Issue/PR 発行）

## 8. 主要ロジックのファイル参照

| ロジック | ファイル | 概要 |
|---------|---------|------|
| framework/config マッピング | `plugins/team-dev-kit/scripts/kit-sync.py` `fw_map()` / `cfg_map()` | 原本→配置先の対応表 |
| init | `kit-sync.py` `cmd_init()` | 配置・lock 生成・hooksPath 設定 |
| update | `kit-sync.py` `cmd_update()` | SHA 照合による drift 検出・置換・config install-once |
| contribute | `kit-sync.py` `cmd_contribute()` | drift 候補抽出・diff 表示・staging 書出 |
| doctor | `kit-sync.py` `cmd_doctor()` | 依存・hooksPath・version・drift・config の読取専用診断 |
| L3 発行ゲート | `plugins/team-dev-kit/scripts/egress-scan.sh` | `gh ... create` の本文を gitleaks にかける |
| L1 commit ゲート | `plugins/team-dev-kit/framework/pre-commit` | `gitleaks protect --staged` |
| base 検出ルール | `plugins/team-dev-kit/framework/base.gitleaks.toml` | 秘密＋個人情報ルール（L1/L3 の源） |
| `@import` glue | `plugins/team-dev-kit/config-starters/AGENTS.md` | `@.team-dev-kit/contract.md` |
| `[extend]` glue | `plugins/team-dev-kit/config-starters/gitleaks.toml` | `path = ".team-dev-kit/base.gitleaks.toml"` |
| PreToolUse 定義 | `plugins/team-dev-kit/hooks/hooks.json` | Bash matcher → egress-scan.sh |
| marketplace メタ | `.claude-plugin/marketplace.json` | 本リポジトリを marketplace 宣言 |
| E2E テスト | `tests/smoke.sh` | init→doctor→継承→egress block→update→contribute |

## 9. ステータス

M0〜M5 実装済（plugin・lockfile・kit-init/update/contribute/doctor、framework/config 分離、`@import`、
gitleaks overlay→base、3-way merge 撤去）。検証は `sh tests/smoke.sh`（29 アサーション全通過）。
残: marketplace 公開（rollout 判断）、Claude Code 上での `/plugin` 実機確認。
</content>
</invoke>
