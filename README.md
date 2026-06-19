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
| ミスしたとき | レビューで指摘 → やり直し | その場で Hook が止める／Skill が直す |

この切り替えで効くのは次の2つです。

1. **事前知識のコストが下がる** — ルールを暗記してから開発を始める必要がなくなります。新しく入った人も初日から正しく開発できます。
2. **運用ミスに伴うコスト（時間）が下がる** — 「規約違反です」の指摘・やり直し・修正の往復が減り、そもそも違反できない仕組みなので事故が起きません。

結果として、規約や手順に注意を割く時間が減り、**本来やりたい開発そのものに集中できる**——というのが team-dev-kit の仮説であり、目指している状態です。

### 旧ドキュメント ↔ Skill / Hook 対比

「人が読んで守っていたドキュメント」が、どの Skill / Hook に置き換わったかの対応です。

| 旧ドキュメント（人が読む） | 置き換えた Skill / Hook（AI が運用） | 守られ方 |
|---|---|---|
| コミット規約 | `git-commit` skill | 「コミットして」で正しい形を自動生成 |
| ブランチ運用・Issue/PR 運用 | `github-workflow` skill | ブランチ作成・`Closes #N` 紐付け・直 push 禁止を自動適用 |
| Issue 作成ガイド・テンプレート | `ticket-template` / `ticket-draft` / `ticket-publish` / `ticket-pr-publish` skill | 会話・計画から下書き生成 → 発行 |
| 設計ドキュメント記述ルール | `doc-writing` skill | 設計文書の文体・構造を自動で適用 |
| 秘密情報取り扱いルール | pre-commit hook ＋ PreToolUse hook（gitleaks） | commit 前・発行前に機械検査し、危険なら**ブロック** |

ドキュメント側は[`docs/legacy-manual-rules/`](docs/legacy-manual-rules/)に、Skill 側は
[`kit/skills/`](kit/skills/)にあります。

> 昔どんなルールを「人が読んで守る」前提で整備していたのかは、
> 当時のドキュメントを作り直してまとめた [`docs/legacy-manual-rules/`](docs/legacy-manual-rules/) にあります。
> 何を Skill にまとめ直したのかが分かります。



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

> 確認したいとき: `git config --local core.hooksPath`（→ `.githooks`）と `ls .claude/skills` で導入済みか分かります。



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

**1. ブートストラップを実行する**

導入したいリポジトリの**ルートで** curl を実行します。
skill もガードレールも、すべて**このプロジェクト配下だけ**に入ります（`$HOME` には何も置きません。他プロジェクトに影響しません）。

```bash
cd <リポジトリ>
curl -fsSL https://raw.githubusercontent.com/aRaikoFunakami/team-dev-kit/main/bootstrap.sh | sh
```

必要なファイルが自動配置されます。

```text
.claude/skills/     ← 業務 skill（このプロジェクトでだけ有効）
.claude/settings.json ← PreToolUse 秘密情報フック
.team-dev-kit/      ← ルール本体 + egress スクリプト（編集禁止）
.githooks/          ← commit 時の自動検査
AGENTS.md           ← プロジェクト固有ルールを書く場所（編集OK）
.gitleaks.toml      ← 秘密情報の検出ルール（編集OK）
.github/            ← Issue / PR テンプレート（編集OK）
```

これを commit すると、以後この repo を clone した人は **パターンA だけ**で済みます。

> 🔁 **すでに独自の `AGENTS.md` や `.gitleaks.toml` がある場合**: あなたの記述は**そのまま保持**します。
> その上で、共通契約を読み込む `@.team-dev-kit/contract.md`（AGENTS.md）と、基盤検出ルールを継承する
> `[extend]`（.gitleaks.toml）の**繋ぎ込みだけを自動で追記**します。これにより既存設定を壊さず、
> 秘密ガードと共通契約を確実に効かせます（追記は冪等。再実行で重複しません）。
> 既に別の `[extend]` がある `.gitleaks.toml` は自動編集せず、追記すべき行を警告で案内します。

> 🌐 **全プロジェクトで使いたいとき（明示的グローバル）**: `--global` を付けると skill を
> `~/.claude/skills/` に入れ、どのプロジェクトでも効くようにします。既定はあくまでプロジェクト配下です。
> ```bash
> curl -fsSL https://raw.githubusercontent.com/aRaikoFunakami/team-dev-kit/main/bootstrap.sh | sh -s -- --global
> ```
> 確認だけしたいときは `--dry-run`、既存ファイルを上書きするときは `--force` を付けます。

**2. 動作確認する**

ガードレールが効いているかを確認します。

```bash
git config --local core.hooksPath          # → .githooks と出れば pre-commit が有効
ls .claude/skills                          # → git-commit などの skill が並ぶ
```

Claude Code を起動して Trust を許可すれば、`.claude/skills/` の skill が自動でロードされます。
本物に近いランダムな秘密情報をわざと commit してみて、pre-commit が止めれば成功です
（`AKIAIOSFODNN7EXAMPLE` のような例示キーは誤検知回避のため素通りします）。

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
| Issue 作成 | feature テンプレートに沿って作成 | [#5](https://github.com/aRaikoFunakami/sandbox-team-dev-kit/issues/5) |
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
| Issue 作成 | feature テンプレートに沿って作成 | [#7](https://github.com/aRaikoFunakami/sandbox-team-dev-kit/issues/7) |
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

### ルールの一括配布と改善の共有

- チーム標準を複数リポジトリへ配れる（各 repo で bootstrap を実行）
- あるプロジェクトで改善したルールを本体リポジトリへ Issue / PR で還元し、全リポジトリへ広げられる



## 実装した最低限のルール（サマリ）

team-dev-kit は「全部のルール」ではなく、**チーム開発でこれだけは守りたい最低限のルール**を
Skill / Hook として実装しています。以下はその要約です。**詳細・例外・最新の正確な定義は
各 Skill / Hook の本体を正とし、この表はあくまで地図**として使ってください。

| ルール | 最低限の決まり | 実装（詳細はこちら） |
|---|---|---|
| ブランチ運用 | default ブランチ（`main` / `master`）で直接作業・直接 push しない。必ず feature ブランチを切り、PR 経由でマージ | [`github-workflow` skill](kit/skills/github-workflow/SKILL.md) |
| PR | **変更の性質によらず常に必須**（記録として残す） | [`github-workflow` skill](kit/skills/github-workflow/SKILL.md) |
| Issue の要否 | 線引きは「**挙動を変えるか**」。挙動を変える変更は Issue 必須（`Closes #N` で紐付け）。挙動不変かつ些細（typo・文言微修正・コメント・整形）は Issue 不要 | [`github-workflow` skill](kit/skills/github-workflow/SKILL.md) |
| コミット規約 | `type(scope): subject` 形式 | [`git-commit` skill](kit/skills/git-commit/SKILL.md) |
| 設計ドキュメント | 文体・構造のルールを自動適用 | [`doc-writing` skill](kit/skills/doc-writing/SKILL.md) |
| 秘密情報ガード | commit 前・発行前に gitleaks で機械検査し、危険ならブロック（二重ガード） | pre-commit hook（`.githooks/pre-commit`）＋ PreToolUse egress hook（[`egress-scan.sh`](kit/scripts/egress-scan.sh)） |

### hotfix の扱い

hotfix も特別扱いではなく、**上の「挙動を変えるか」で 2 つに分かれます**。

| hotfix の種別 | Issue | PR |
|---|---|---|
| **挙動不変・些細**（typo・文言の微修正・コメント・整形など） | **不要**（番号なしブランチ可・`Closes` なし・PR 本文が記録） | **必須** |
| **挙動変更**（バグ・ロジック・API の修正など） | **必要**（`Closes #N` で紐付け） | **必須** |

- 線引きは「hotfix かどうか」ではなく「**挙動を変えるか**」です。数行の hotfix でも挙動を変えるなら Issue を作ります。
- 挙動変更で**緊急**な hotfix は起票を後回しにしてよいですが、**マージまでに Issue を作成**します。
- ブランチ命名は `hotfix/<issue-number>-<short-description>`（Issue を省ける挙動不変・些細なケースは `hotfix/fix-typo` のように番号なし可）。

> 正確な条件・例外は [`github-workflow` skill](kit/skills/github-workflow/SKILL.md) を参照してください。



## 日常で使うコマンド

| やりたいこと | コマンド |
|---|---|
| ちゃんと効いているか診断 | `git config --local core.hooksPath`（→ `.githooks`）／ `ls .claude/skills` |
| ルールを最新版に更新 | リポジトリのルートで bootstrap を `--force` 付きで再実行（下記） |
| 共通ルールへの改善を提案 | `.team-dev-kit/` 配下を編集せず、本体リポジトリへ Issue / PR |

更新はブートストラップの再実行です（framework と skill を最新版で上書き。`AGENTS.md` 等の config は既存を残します）。

```bash
cd <リポジトリ>
curl -fsSL https://raw.githubusercontent.com/aRaikoFunakami/team-dev-kit/main/bootstrap.sh | sh -s -- --force
```



## よくある質問

**Q. 新しいメンバーが入ったら何をすればいい？**
`git clone` → Claude Code 起動 → Trust の3つだけ（[パターンA](#パターンa-チームに参加しただけの人最短)）。

**Q. すでに自分の `AGENTS.md` / `.gitleaks.toml` があるけど上書きされない？**
されません。あなたの内容は保持したまま、共通契約の import（`@.team-dev-kit/contract.md`）と
base 継承（`[extend]`）の繋ぎ込みだけを追記します。bootstrap を再実行しても重複しません。

**Q. `AGENTS.md` は編集していい？**
はい。プロジェクト固有のルールを書く場所です（自動追記される import 行は残してください）。

**Q. `.team-dev-kit/` 配下は編集していい？**
いいえ。更新（bootstrap 再実行）時に置き換えられます。改善したいときは本体リポジトリへ Issue / PR を出してください。

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

設計の詳しい中身（ルール本体と各プロジェクト設定の分け方、リポジトリ間でルールを揃える仕組み、
秘密情報チェックを2か所に置いている理由など）は
[`docs/architecture.md`](docs/architecture.md) を参照してください。

ふだん使うだけならこの README で十分です。

team-dev-kit が「昔は人が読んで守っていた」どんなルールを Skill / Hook にまとめ直したのかは、
当時のルールドキュメントを作り直してまとめた [`docs/legacy-manual-rules/`](docs/legacy-manual-rules/)
にあります（現役のルールではなく、移し替え元のサンプルです）。
