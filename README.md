# team-dev-kit

**チームの開発ルールを「覚えるもの」から「自動で守られるもの」に変えるキットです。**

ルールをドキュメントに書いても、新しく入った人は全部は読めないし、覚えても忘れます。
team-dev-kit はルールを Claude Code の **Skill** と **Hook** として配るので、
clone した瞬間からあなたの開発環境にルールが組み込まれます。

> 覚えなくていい。間違えても自動で止まる。だから初日から正しく開発できる。


## これは何の役に立つのか

新しくチームに入ったとき、ふつうはこうなります。

| よくある困りごと | team-dev-kit があると |
|---|---|
| ルールが Confluence / README に散らばっていて読みきれない | clone した時点で Claude Code がルールを理解している |
| コミットメッセージの書き方が分からない | コミット時に Skill が自動で正しい形を提案 |
| PR / Issue の書き方をいちいち調べる | 作成時にワークフローが自動適用される |
| うっかり API キーやパスワードをコミットしてしまう | **commit 前に自動検査してブロック**。事故が起きない |
| レビューで「ルール違反です」と何度も指摘される | そもそも違反できない仕組みになっている |

ポイントは、ルールを**人の記憶や注意力に頼らない**こと。
新人がミスをしても、人ではなく仕組み（Hook・Skill）が止めてくれます。



## 何が変わったのか（ドキュメント運用 → Skill 運用）

team-dev-kit のねらいは、ルールの**守らせ方**を切り替えることです。

- **これまで:** ルールを **ドキュメントに整備** し、それを **人が読んで覚えて守る** 運用でした。
- **これから:** ルールを **Skill に整備** し、それを **AI（Claude Code）が運用する** かたちにします。

同じ「ルールを守る」でも、誰がコストを払うかが変わります。

| | これまで（ドキュメント運用） | これから（Skill 運用） |
|---|---|---|
| ルールの置き場所 | README / Confluence に散らばる | Skill / Hook に集約される |
| 守るのは誰か | 人（記憶と注意力） | AI（毎回自動で適用） |
| 事前に必要な知識 | 全ルールを読んで覚える | ほぼ不要（目的を伝えるだけ） |
| ミスしたとき | レビューで指摘 → 手戻り | その場で Hook が止める／Skill が直す |

この切り替えで効くのは次の2つです。

1. **事前知識のコストが下がる** — ルールを暗記してから開発を始める必要がなくなります。新しく入った人も初日から正しく開発できます。
2. **運用ミスに伴うコスト（時間）が下がる** — 「規約違反です」の指摘・手戻り・修正の往復が減り、そもそも違反できない仕組みなので事故が起きません。

結果として、規約や手順に注意を割く時間が減り、**本来やりたい開発そのものに集中できる**——というのが team-dev-kit の仮説であり、目指している状態です。

### 旧ドキュメント ↔ Skill / Hook 対比

「人が読んで守っていたドキュメント」が、どの Skill / Hook に置き換わったかの対応です。

| 旧ドキュメント（人が読む） | 置き換えた Skill / Hook（AI が運用） | 守られ方 |
|---|---|---|
| コミット規約 | `git-commit` skill | 「コミットして」で正しい形を自動生成 |
| ブランチ運用・Issue/PR 運用 | `github-workflow` skill | ブランチ作成・`Closes #N` 紐付け・直 push 禁止を自動適用 |
| Issue 起票ガイド・テンプレート | `ticket-template` / `ticket-draft` / `ticket-publish` / `ticket-pr-publish` skill | 会話・計画から下書き生成 → 発行 |
| 設計ドキュメント記述ルール | `doc-writing` skill | 設計文書の文体・構造を自動で適用 |
| 秘密情報取り扱いルール | pre-commit hook ＋ PreToolUse hook（gitleaks） | commit 前・発行前に機械検査し、危険なら**ブロック** |

ドキュメント側は[`docs/legacy-manual-rules/`](docs/legacy-manual-rules/)に、Skill 側は
[`plugins/team-dev-kit/skills/`](plugins/team-dev-kit/skills/)にあります。

> 昔どんなルールを「人が読んで守る」前提で整備していたのかは、
> 当時のドキュメントを逆引きで再現した [`docs/legacy-manual-rules/`](docs/legacy-manual-rules/) にまとめてあります。
> 何を Skill に畳み込んだのかが分かります。



## QuickStart

あなたの状況で読む場所が変わります。

- **A. すでに team-dev-kit が導入済みのリポジトリに参加した** → [パターンA](#パターンa-チームに参加しただけの人最短) （ほぼこれ）
- **B. 自分のチーム / リポジトリに team-dev-kit を初めて入れる** → [パターンB](#パターンb-リポジトリに初めて導入する人一度だけ)



### パターンA: チームに参加しただけの人（最短）

リポジトリにすでに導入されていれば、やることは **3つだけ**です。

```bash
git clone <リポジトリURL>
cd <リポジトリ>
```

1. **Claude Code を起動する**
2. **Trust（信頼）を許可する**
3. 以上。終わりです。

これでチームのルールが自動で効く状態になっています。
コミットや PR を作るとき、Claude Code が勝手に正しいやり方を案内してくれます。

> 確認したいとき: Claude Code で `/kit-doctor` と打つと、ちゃんと効いているか診断できます。



### パターンB: リポジトリに初めて導入する人（一度だけ）

> この作業はチームで誰か一人が一度だけ行えば OK です。以後の参加者はパターンAで済みます。

#### 前提

以下がインストール済みであること。

```bash
git --version
python3 --version
gitleaks version    # 秘密情報スキャンに使う
```

Claude Code が利用できること。

#### 手順

**1. プラグインを有効化する**

リポジトリの `.claude/settings.json` に追記します（なければ作成）。

```json
{
  "extraKnownMarketplaces": {
    "team-dev-kit": {
      "source": {
        "source": "github",
        "repo": "aRaikoFunakami/team-dev-kit"
      }
    }
  },
  "enabledPlugins": {
    "team-dev-kit@team-dev-kit": true
  }
}
```

これを commit すると、以後この repo を clone した人は **パターンA だけ**で済みます。

**2. Claude Code を起動して初期化する**

Claude Code 上で実行:

```text
/kit-init
```

ルール本体や秘密情報スキャン設定など、必要なファイルが自動配置されます。

```text
.team-dev-kit/      ← ルール本体（編集禁止）
.githooks/          ← commit 時の自動検査
AGENTS.md           ← プロジェクト固有ルールを書く場所（編集OK）
.gitleaks.toml      ← 秘密情報の検出ルール（編集OK）
.github/            ← Issue / PR テンプレート（編集OK）
.team-dev-kit.lock  ← 管理用
```

**3. 動作確認する**

```text
/kit-doctor
```

こう出れば成功です。

```text
dep gitleaks: ok
dep git: ok
core.hooksPath: .githooks
version: ok

✅ healthy
```

これで導入は完了です。
配置されたファイルはこのあとチームに共有する必要がありますが、
そのコミット & PR は次の [実際に使ってみる](#実際に使ってみるissue--開発--pr--マージ) で
**Claude Code に頼んでやってもらいます**（最初の練習にちょうど良い）。



## 実際に使ってみる（Issue → 開発 → PR → マージ）

team-dev-kit のいちばん大事なところは、**ルールを指示しなくていい**ことです。
「やりたいこと」を Claude Code に言うだけで、コミット規約・ブランチ運用・Issue/PR の紐付け・
秘密情報チェックは Skill が**勝手に・正しく**やります。手順もコマンドも覚える必要はありません。

たとえば、こんな会話だけで一連の開発が回ります。

```text
あなた> ログイン画面に入力チェックを足したい。Issue を立てて取りかかって
あなた> （Claude と一緒にコードを書く）
あなた> できたのでコミットして PR まで出して
あなた> レビュー通ったのでマージして
```

これだけで裏側では自動的に:

- Issue がテンプレートに沿って作られる
- 専用ブランチが切られる（main への直接コミットは禁止）
- コミットメッセージが規約形式（`type(scope): subject`）で生成される
- PR が Issue に紐付く（`Closes #N`）
- commit 前・発行前に秘密情報が検査され、混ざっていれば**止まる**

> 📝 デフォルトブランチについて: 本 README では `main` に統一して説明します。
> 古くからあるリポジトリは `master`、GitHub で新規作成したリポジトリは `main` がデフォルトのため、
> 両方が現場に存在します。Skill は実際のデフォルトブランチを自動判定して動くので、
> どちらのリポジトリでも「main に直接 push しない」というルールはそのまま機能します。

### 指示しすぎない、がコツ

| ❌ こう言う必要はない | ✅ これで十分 |
|---|---|
| 「`type(scope): subject` 形式でコミットメッセージを書いて」 | 「コミットして」 |
| 「ブランチを切って、main には直接 push しないで」 | 「取りかかって」 |
| 「PR 本文に `Closes #12` を入れて Issue と紐付けて」 | 「PR を出して」 |

ルールは Skill 側に入っています。あなたは**目的だけ**を伝えればいい、というのが team-dev-kit の狙いです。

> 💡 導入直後の最初の練習に最適なのが、まさにこの流れで
> 「team-dev-kit を入れた変更」自体をコミット → PR → マージしてみることです。

### 実例：検証リポジトリで実際にやってみた

「目的を伝えるだけ」で本当に一連の開発が回るのか、検証用リポジトリ
[`sandbox-team-dev-kit`](https://github.com/aRaikoFunakami/sandbox-team-dev-kit)（team-dev-kit 導入済み）で
2つの依頼を Claude Code に投げて実際に流してみました。
以下は **実際に渡したプロンプトと、その結果** です。
ブランチ運用・コミット規約・Issue/PR の紐付けは一切指示していません（すべて Skill / Hook が自動）。

#### 依頼1：Rust で Hello, World を作る

> **プロンプト（そのまま）**
> Rust で "Hello, World!" と標準出力するだけの小さなプログラムを作りたい。
> Issue を立てるところから、実装、PR 作成、マージまで一通りやってほしい。
> 細かい進め方（ブランチ運用・コミット規約・Issue と PR の紐付け）はこのリポジトリのルールに従って。

結果（Claude Code が自動でやったこと）:

| 段階 | 自動でやったこと | 実物 |
|---|---|---|
| Issue 起票 | feature テンプレートに沿って起票 | [#5](https://github.com/aRaikoFunakami/sandbox-team-dev-kit/issues/5) |
| ブランチ | `feature/5-rust-hello-world` を作成（`main` 直接コミットなし） | — |
| 実装 | `Cargo.toml` / `src/main.rs` / `.gitignore` を生成し `cargo run` で検証 | — |
| コミット | `feat(hello-rs): Rust で "Hello, World!" を標準出力するサンプルを追加` | — |
| PR 発行 | 本文に `Closes #5` を入れ、Issue と双方向リンク | [#6](https://github.com/aRaikoFunakami/sandbox-team-dev-kit/pull/6) |
| マージ | squash マージ → Issue #5 が**自動クローズ**、ブランチも自動削除 | — |

#### 依頼2：出力文言を変える

> **プロンプト（そのまま）**
> さっき作った Rust プログラムの出力を "Hello, World!" から "Hello, Team-dev-kit!" に変えたい。
> これも Issue を立てて、修正して、PR を出してマージするところまでやって。
> 進め方はこのリポジトリのルールに従って。

結果:

| 段階 | 自動でやったこと | 実物 |
|---|---|---|
| Issue 起票 | feature テンプレートに沿って起票 | [#7](https://github.com/aRaikoFunakami/sandbox-team-dev-kit/issues/7) |
| ブランチ | `feature/7-hello-team-dev-kit` を作成 | — |
| 修正 | `src/main.rs` を編集し `cargo run` → `Hello, Team-dev-kit!` を確認 | — |
| コミット | `feat(hello-rs): 出力文言を "Hello, Team-dev-kit!" に変更` | — |
| PR 発行 | 本文に `Closes #7` | [#8](https://github.com/aRaikoFunakami/sandbox-team-dev-kit/pull/8) |
| マージ | squash マージ → Issue #7 が**自動クローズ**、ブランチも自動削除 | — |

どちらも「目的」だけを伝え、`type(scope): subject` のコミット形式、feature ブランチ運用、
`Closes #N` による Issue⇄PR リンク、マージ時の Issue 自動クローズはすべて自動でした。
`Closes #N` が効くので、マージした瞬間に Issue が閉じます（手で閉じる必要なし）。

#### 秘密情報ガードも実際に試した

ついでに、本物に近いランダムな AWS キーらしき文字列をわざとコミットしてみたところ、
`git commit` が pre-commit hook で止まりました（実際の出力）。

```text
WRN leaks found: 1

✋ 秘密情報または個人情報の疑いを検出しました。コミットを中止します。
   対応: 該当箇所を削除・マスキング・匿名化してから再コミットしてください。
   誤検知の場合: .gitleaks.toml の [allowlist] に例示値を追加してください。
```

なお `AKIAIOSFODNN7EXAMPLE` のような**ドキュメント頻出の例示キーは素通り**します（誤検知回避の仕様）。
止めたいときは本物に近いランダムな値で試してください。



## 何が自動でやってくれるのか

### ルールの自動適用

共通ルールが Skill として配布され、こういう作業のときに自動で適切なルールが効きます。

- コミット作成
- GitHub 操作（Issue / PR）
- 設計ドキュメント作成
- チケット作成

覚える必要はありません。作業を始めると Claude Code が案内します。

### 秘密情報の漏洩防止（二重ガード）

API キー・トークン・個人情報・認証情報を、**2つの経路**で機械的にブロックします。

```text
あなたが git commit       → pre-commit hook → gitleaks → 危険なら commit を拒否
Claude が gh issue/pr     → PreToolUse hook → gitleaks → 危険なら発行を拒否
```

人がうっかりしても、仕組みが止めます。

> ⚠️ 動作確認するときの注意: `AKIAIOSFODNN7EXAMPLE` のような**ドキュメント頻出の例示キーや連番文字列は、
> gitleaks がわざと無視します**（誤検知を避ける仕様）。「ブロックされない＝壊れている」ではありません。
> 試すときは、本物に近いランダムな値を使ってください。

### ルールの一括配布と改善の還元

- チーム標準を複数リポジトリへ配れる
- あるプロジェクトで改善したルールを本体に戻し、全リポジトリへ展開できる（`/kit-contribute`）



## 日常で使うコマンド

| やりたいこと | コマンド |
|---|---|
| ちゃんと効いているか診断 | `/kit-doctor` |
| ルールを最新版に更新 | `/plugin update team-dev-kit@team-dev-kit` → `/kit-update` |
| 共通ルールへの改善を提案 | `/kit-contribute` |



## よくある質問

**Q. 新しいメンバーが入ったら何をすればいい？**
`git clone` → Claude Code 起動 → Trust の3つだけ（[パターンA](#パターンa-チームに参加しただけの人最短)）。

**Q. `AGENTS.md` は編集していい？**
はい。プロジェクト固有のルールを書く場所です。

**Q. `.team-dev-kit/` 配下は編集していい？**
いいえ。更新時に置き換えられます。改善したいときは `/kit-contribute` を使ってください。

**Q. gitleaks が誤検知する**
`.gitleaks.toml` に allowlist を追加してください。共通ルールに反映したい場合は本体へ提案を。



## 編集していいファイル / だめなファイル

| ファイル | 編集 | 理由 |
|---|---|---|
| `AGENTS.md` | ✅ OK | プロジェクト固有ルールを書く場所 |
| `.gitleaks.toml` | ✅ OK | 自プロジェクトの検出ルール調整 |
| `.github/*` | ✅ OK | Issue / PR テンプレート |
| `.team-dev-kit/*` | ❌ 禁止 | 共通ルール本体。更新時に置換される |
| `.githooks/*` | ❌ 禁止 | 共通フック本体。更新時に置換される |



## もっと詳しく（仕組みを知りたい人向け）

アーキテクチャ（Plane A / Plane B の2層構造、framework と config の分離、
lockfile による同期、秘密情報スキャンの2ゲート設計など）は
[`docs/architecture.md`](docs/architecture.md) を参照してください。

ふだん使うだけならこの README で十分です。

team-dev-kit が「昔は人が読んで守っていた」どんなルールを Skill / Hook に畳み込んだのかは、
当時のルールドキュメントを逆引きで再現した [`docs/legacy-manual-rules/`](docs/legacy-manual-rules/)
にまとめてあります（現役のルールではなく、移し替え元のサンプルです）。
