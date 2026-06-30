---
name: github-workflow
description: GitHub を操作するとき（Issue の起票・閲覧、PR 作成・レビュー、ブランチ運用）に起動する。gh コマンド必須、Issue の要否は「挙動を変えるか」で判断、branch + PR は常に必須（default ブランチ＝main への直接 push 禁止）、PR 本文に Closes #N で Issue を紐付ける、closing keyword は default ブランチでのみ発火、PR 作成後は /code-review で自己レビュー、といった本リポジトリの GitHub 運用契約を与える。「Issue 作って」「PR 出して」「ブランチ切って」等で発火。
---

<!--
概要: GitHub 運用契約 skill。Issue 要否・branch/PR 規約・default ブランチ push の委譲・worktree での着手・closing keyword・PR 作成後の自己レビューを与える。
旧 instructions 配下の GitHub 運用契約を移植したもの。GitHub 操作のたびに参照する。
-->

# GitHub 運用ルール

本リポジトリにおける GitHub の運用契約を定める。迷ったら AGENTS.md の方針を優先する。

## リポジトリ

- **URL:** リポジトリの origin を `git remote get-url origin` で確認する。
- **default ブランチ:** 本文では `main` と表記する（PR のマージ先。closing keyword の発火条件に関わる）。
  - 歴史的経緯: 古いリポジトリは `master`、GitHub で新規作成したリポジトリは `main` がデフォルトのため、現場には両方が存在する。
  - **実際の default ブランチは必ず動的判定する:** `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`。
    以降この値を「default ブランチ」と呼ぶ。`master` のリポジトリでも本ルールはそのまま機能する。

## ツール

- GitHub 操作（接続・起票・閲覧・PR 等）には必ず `gh` コマンドを使用する。
- ブラウザ操作や Web UI を前提とした手順を記述・依頼しない。

## Issue ベース開発

- 挙動を変える変更（バグ修正・機能追加・ロジック/API 変更）は **Issue の内容に基づいて** 実施する。
- Issue 起票時は、**AI が単独で実装・完結できるレベルまで** 詳細な技術仕様を記述する。
  - 対象ファイル・モジュール、変更方針、受け入れ条件（テスト/検証方法）を含める。
  - 曖昧な要望のままで起票しない。実装者が追加質問なしで着手できる粒度にする。

### Issue の要否（挙動を変えるか）

Issue を起こすかは変更の**性質**で決める。規模（数行か否か）ではない。

| 変更の性質 | Issue | branch + PR |
|------------|-------|-------------|
| 挙動不変かつ些細（typo・誤字・文言の微修正・コメント・整形など） | 不要 | 必須（番号なしブランチ可、`Closes` なし、PR 本文が記録） |
| 挙動変更（バグ・ロジック・API 変更、hotfix を含む）、または実質的な doc/規約変更 | 必要（`/ticket-draft` で AI 生成可） | 必須（`Closes #N` で紐付け） |

- 線引きは「**挙動を変えるか**」。数行の hotfix でも挙動を変えるなら Issue を作る。
- **branch + PR は変更の性質によらず常に必須**（default ブランチ＝`main`／`master` への直接 commit/push 禁止は後述のとおり維持）。
  Issue を省けるのは「挙動不変かつ些細」のときだけで、PR による記録は省略しない。
- **doc 変更でも、ワークフロー規約・設計方針など実質的な内容は Issue 対象**。Issue 不要なのは
  typo・誤字・文言の微修正など些細なものに限る。
- 挙動不変で Issue を省く場合のブランチは番号なしを許可する（例 `docs/readme-wording`、
  `hotfix/fix-typo`）。PR 本文に変更理由を書き、記録とする。

### Issue 前の着手（許可と条件）

Issue 作成前に着手してよい（会話・探索で方針を詰めてから起票する流れを許可する）。
Issue⇄PR の紐付けは PR 作成時に成立する（commit に Issue 番号は不要）ため、着手が先でも問題ない。
ただし次を守る:

1. 着手時に **feature ブランチを切る**（default ブランチ＝`main` へ直接 commit しない）。
2. 挙動変更で Issue が必要な場合は **PR 作成前までに Issue を作成**し `Closes #N` で紐付ける。
3. 挙動変更で緊急（hotfix）なら起票を後回しにしてよいが、**マージまでに Issue を作成**する。

## feature と統合点（1 PR か、束ねるか）

作業の単位は **feature**（E2E で動作確認できる最小の機能の塊）。feature は最終的に
**default ブランチ（`main`）へ 1 本の PR で着地**する。

統合点（どこへ Task を集めるか）は **着手時に予測しない**。Issue 分解の時点で確定し
Issue の「検証単位」節に記載済みのものに従う（→ ticket-draft skill）。

| 検証単位節の記載 | 統合点 | フロー |
|------------------|--------|--------|
| `feature: 単体`（Task=1） | `main` | 単体ブランチ → PR → main。**従来どおり** |
| `feature: <name>`（Task=N） | アンブレラ `feature/<name>` | Task を束ね、統合点で E2E、最後に main へ 1 本 |

- 「統合点」「統合 E2E ゲート」「`Closes #N` の置き場」は両者で同じ概念。N=1 のときは
  `main`・その 1 PR・その PR 本文に**縮退する**。
- 束ねるのは「単体では E2E が通らない」ときだけ。アンブレラは長命化すると `main` から乖離する
  ため安易に束ねない。
- feature は EPIC（計画上の入れ物）と別物。「同じ EPIC か」ではなく
  「**同じ E2E シナリオで一緒に検証されるか**」で束ねる単位を決める。

## ブランチ運用

### 禁止事項

1. **default ブランチ（`main`）で直接作業しないこと** — 必ず feature ブランチを作成してから作業する。
2. **default ブランチへ直接 push しないこと** — 変更は必ず PR 経由でマージする。

### default ブランチでは commit / push しない（破壊的 git コマンドの規約）

不可逆・破壊的な git コマンドはエージェントから**実行しない**。これは行動規約であり、
リポジトリが `.claude/settings.json` の `permissions.deny` を設定していれば二重に強制される
（**deny は team-dev-kit の bootstrap では配布しない**。任意の追加設定で、手順は team-dev-kit
README「default ブランチを保護する」を参照）。deny に当たること自体は **エラーでも障害でもない**。

| コマンド | 規約 | エージェントの扱い |
|----------|------|--------------------|
| `git push origin main` / `master`（HEAD 経由含む） | 実行しない（deny 推奨） | **default ブランチへの直接 push のみ禁止**。通常の PR フローでは発生しない |
| `git push`（feature ブランチ） | 実行してよい | **エージェントが直接 push してよい**（初回 `git push -u origin <branch>`、再 push は `--force-with-lease`） |
| `git reset --hard*` | 実行しない（deny 推奨） | 履歴・作業ツリーを壊すため人間の判断に委ねる |
| `git push --force*` | 実行しない（deny 推奨） | feature ブランチの再 push は `--force-with-lease` を使う |
| `rm -rf*` | 原則使わない | 退避は削除でなく `mv` |
| `git clean*` | 原則使わない | 未追跡ファイルを消すため、必要時はユーザーに依頼する |

deny が設定されていて当たったら、**リトライや回避（別表記での再 push 等）をしない**。
実行すべき正確なコマンドを提示してユーザーに依頼し、開発プロセスを止めずに継続する。
commit・feature ブランチへの push・`gh` 系（`gh pr create` 等）はエージェントが実行してよい。

> **強制レイヤの注意**: `settings.json` の deny は **Claude エージェントの push を止めるだけ**で、
> bootstrap では配布しない任意設定。人間や他クライアントからの default ブランチへの直接 push を防ぐ
> 強制は **GitHub のブランチ保護**で行う（リポジトリ初期設定で一度だけ。両者の手順は
> team-dev-kit README「default ブランチを保護する」）。

#### commit / push の手順

1. **commit する前に、現在のブランチが default ブランチでないことを確認する**:
   `git remote show origin` の `HEAD branch`（または
   `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`）。default は
   `main` / `master` とは限らない。
2. **default ブランチ上なら commit も push もしない。** feature ブランチ／worktree を切り忘れた
   異常状態。**ここで作業を止め**、worktree で着手し直してから再開する（「worktree での着手」参照）。
   誤って default 上で commit 済みなら、その commit を feature ブランチへ退避してから続ける。
3. feature ブランチであることを確認できたら commit する。
4. **push はエージェントが直接実行する**（初回 `git push -u origin <branch>`、rebase 後の再 push は
   `--force-with-lease`）。default ブランチ（`main` / `master`）への直接 push は規約で行わない（deny を
   設定していればブロックされる）。通常フローでは発生しない。
5. push 後に後続（`gh pr create` 等）へ進む。

> 補足: push が deny ではなく **環境側の認証等で失敗** する場合は、ユーザーに
> `! git push -u origin <branch>` の実行を依頼する（`! <command>` でこのセッション内実行・出力が会話に入る）。

### ブランチ命名規則

| 種別 | 形式 |
|------|------|
| Feature | `feature/<issue-number>-<short-description>` |
| Bugfix | `bugfix/<issue-number>-<short-description>` |
| Hotfix | `hotfix/<issue-number>-<short-description>` |
| Documentation | `docs/<issue-number>-<short-description>` |
| Feature アンブレラ（統合点 / Task=N） | `feature/<name>` |
| アンブレラ配下の Task | `feature/<name>-<issue-number>-<short-description>` |

- 作業開始前に、現在のブランチが default ブランチ（`main`）でないことを確認する。該当する場合は上記命名規則で feature ブランチを作成してから着手する。
- **Task は `/` ではなく `-` でアンブレラ名に続ける**（`feature/<name>-<issue>-<desc>`）。`feature/<name>/<issue>-<desc>` と
  スラッシュで階層化すると、ブランチ `feature/<name>` が存在する以上 git の参照規則で必ず衝突する
  （ref はファイル、その子は同名ディレクトリを要求する D/F conflict。`cannot lock ref ... exists; cannot create` で
  ローカルも GitHub も拒否）。アンブレラ branch 名は Task branch 名の `/` 区切り接頭辞にできない。
- 配下 Task は `git branch --list 'feature/<name>-*'` で一覧化する。単体 `feature/<issue>-<desc>` とは
  `<name>` を数値始まりにしなければ衝突しない。`bugfix`/`hotfix` も同流儀（`-` 区切り）で束ねられる。

### worktree での着手（必須）

新規作業は **必ず `git worktree`** で別ディレクトリに着手する。`git switch -c` / `git checkout` で
カレントの作業ツリーを切り替えることは、**所要時間が一瞬の変更であっても禁止**する。切り替え方式は
並行作業中の他ブランチ・起動中のプロセス・未コミット変更を巻き込み、取り違えや誤コミットといった
並行開発の事故を起こすため。

worktree は **別ディレクトリに別ブランチを同時チェックアウト**する（`.git` は共有、作業ツリーのみ
複製）。default ブランチを起動したまま feature を別 dir で開発でき、stash 不要で並行作業できる。
AI エージェントを並列実行する場合も worktree が前提になる（Agent tool の `isolation: "worktree"` がこれを使う）。

**置き場規約:** リポジトリ外の固定 dir `../worktrees/<branch>` に集約する（リポジトリ内を汚さない）。

```bash
# 起点は必ず origin/<default> を最新化して指定する（未 push のローカル default から分岐しない）。
# <default> は gh repo view --json defaultBranchRef -q .defaultBranchRef.name で動的判定した値。
git fetch origin
git worktree add ../worktrees/<issue>-<desc> -b <type>/<issue>-<desc> origin/<default>
cd ../worktrees/<issue>-<desc>
```

**注意:**
- 「default ブランチで直接作業しない／直接 push しない」禁止事項は worktree でも不変。
- 依存物（`node_modules` / `.venv` 等）は作業ツリー側にあり worktree 間で共有されない。
  新 worktree ではプロジェクトの手順で再構築する。

**後片付け:**

```bash
git worktree remove ../worktrees/<issue>-<desc>   # 作業ツリーを削除
git worktree prune                            # 参照の掃除（手動削除した場合）
```

### 束ねる場合（Task=N）の worktree

Task はリモートのアンブレラを起点に分岐するため、**先にアンブレラを push** する（未 push の
ローカルから Task を分岐しない）。

```bash
BASE="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)"
git fetch origin
git worktree add ../worktrees/<name> -b feature/<name> "origin/$BASE"
git -C ../worktrees/<name> push -u origin feature/<name>
git fetch origin
git worktree add ../worktrees/<name>-<issue> -b feature/<name>-<issue>-<desc> origin/feature/<name>
```

- Task ブランチは `feature/<name>-<issue>-<desc>`（`-` 区切り）。`/` 階層は `feature/<name>` と D/F 衝突して
  作れない（命名規則表の注記参照）。
- Task の起点は `origin/feature/<name>`（上の push が前提）。未 push ローカルから分岐しない。
- 「default で直接作業/直接 push しない」「`switch -c` でカレントを切り替えない」は N=1 と不変。

### Issue 番号の後付け

Issue より先に着手してブランチを切ると、ブランチ名の番号が未確定になる。

- **原則として、Issue 採番後すみやかにブランチを命名規則 `<type>/<issue-number>-...` へ rename する。**
  PR 前ならレビュアーも PR も無く低摩擦（未 push なら `git branch -m <new>`、push 済みなら
  新ブランチを push し旧ブランチを削除）。これでブランチ名が Issue を自己説明し、命名規則・追跡性を保てる。
- rename が現実的でない例外時のみ、フォールバックとして `/ticket-pr-publish` に `#<issue-number>` を
  引数で渡して紐付ける（ブランチ名は規則から外れたまま残る点に注意）。

## PR 運用

PR は Issue と双方向に辿れる状態を必須とする。「Issue → PR → Commit」「Commit → PR → Issue」の両方向を GitHub 上に残すことが目的。

### Issue との紐付け（必須）

- PR は必ず対応する Issue に紐付ける。**PR 本文**に closing keyword を 1 行入れる:

  ```
  Closes #<issue-number>
  ```

  `Fixes #<n>` / `Resolves #<n>` でも可。

- **紐付けは PR 本文に書く。** ブランチ名や commit メッセージでは Issue⇄PR の双方向リンクは作られない。
  - ブランチ名 `feature/<n>-...` に番号を含めても GitHub はリンクを生成しない（人間が読むためのラベル）。
  - commit メッセージの `#<n>` は Issue を参照（mention）するだけで、その PR は Issue の linked pull request として表示されない。

### default ブランチ制約

- closing keyword はマージ先が **default ブランチ（`main`）** のときのみ発火する。
- default 以外のブランチを base にした PR では keyword は無視されリンクが生成されない。その場合は GitHub の Development サイドバーから手動で Issue を紐付ける。

#### 束ねる場合（Task=N）の closing keyword

- Task PR は base がアンブレラ（≠ default）なので keyword は発火しない。Task PR には `Closes` を
  書かず `Refs #<issue>` で参照だけ残す。
- 最終 PR（アンブレラ → `main`）に `Closes #101 #102 #103` を集約する。base が default なので一括
  close される。集約元は task-list（メンバーの SSOT）or `work/<name>/plan.md` から転記する
  （子 Issue から拾い集めない）。

### 作成例

```
# default ブランチを動的に取得して --base に渡す（main / master どちらでも正しく動く）
BASE="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)"
gh pr create \
  --base "$BASE" \
  --title "<type(scope): subject>" \
  --body "Closes #<issue-number>

<変更概要 / なぜ>"
```

- `--base` は default ブランチ（通常 `main`）を指定する。決め打ちせず上記のとおり動的取得する。
- タイトルは `type(scope): subject` 形式（→ git-commit skill）に揃える。
- PR テンプレート（`.github/PULL_REQUEST_TEMPLATE.md`）がある場合はその構造に沿い、`Closes #` を必ず埋める。

### 束ねる場合（Task=N）の統合と最終 PR

1. 全 Task をアンブレラへマージする。
2. **統合 E2E ゲート**: `feature/<name>` の最新で E2E を回す。feature が初めて動作確認できる地点。
   green になるまで feature は未完（**実行手順・証拠要件は各プロジェクト規約に従う**。github-workflow
   にはプロジェクト固有の E2E 実行手順を書かない）。
3. アンブレラを default へ追従させてから最終 PR を作る:

   ```bash
   BASE="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)"
   git fetch origin
   git -C ../worktrees/<name> rebase "origin/$BASE"   # drift 対策（定期 + 最終 PR 前）
   git -C ../worktrees/<name> push --force-with-lease
   gh pr create --base "$BASE" --head feature/<name> --title "<type(scope): subject>" \
     --body "Closes #101 #102 #103"
   ```

4. 最終 PR でも `/code-review` で自己レビューする（N=1 と同じ）。
5. マージ後、アンブレラと配下 Task のブランチ・worktree を削除する。

### PR 作成後の自己レビュー（必須）

PR を作成したら、続けて **その PR の差分を自分でレビューする**。
`/code-review` を実行し、現ブランチ差分をバグ・簡素化観点で点検する。

- findings は **ユーザーへ報告する**。自動修正・PR への自動コメント投稿はしない（修正可否は人が判断する）。
- findings が無ければ「self-review: 指摘なし」と明示する。
- 自己レビューは PR 作成フローの一部。省略しない。

### 根拠

GitHub 公式ドキュメント [Linking a pull request to an issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue) による。closing keyword は `close/closes/closed`, `fix/fixes/fixed`, `resolve/resolves/resolved`。default ブランチ以外を対象とした PR では keyword は無視される。
