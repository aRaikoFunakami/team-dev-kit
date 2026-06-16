---
name: kit-init
description: team-dev-kit の Plane B(リポジトリに commit するファイル群=AGENTS.md・.githooks/pre-commit・.gitleaks.toml・.github テンプレ・docs)を消費プロジェクトへ初回配置し、.team-dev-kit.lock を生成し core.hooksPath を設定する。`/kit-init` が明示的に呼ばれたときのみ起動。自然言語の依頼・関連語(初期化/セットアップ/導入 等)では自動起動しない。
---

# kit-init

team-dev-kit の Plane B を消費プロジェクトに初回導入する。Plane A(skill・フック)は plugin 側で既に有効な前提。

## 厳守

明示 `/kit-init` のときだけ実行する。ファイル配置・git config 変更・PR を伴うため、自動発火させない。

## 手順

1. **dry-run で差分提示**
   ```sh
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/kit-sync.py" init --dry-run
   ```
   write/skip/block(AGENTS.md マージ)/hooksPath の予定を表示する。`--target` 既定は `CLAUDE_PROJECT_DIR`。

2. **既存ファイルの扱いを確認**
   - 既存 `AGENTS.md` は managed-block を挿入/追記し、プロジェクト固有節は温存する
   - `core.hooksPath` が既に他(husky 等)なら上書きせず警告する。手動統合が要る旨を伝える
   - 既存ファイルを上書きしたい場合のみ `--force` を付ける(既定は skip)

3. **本実行**
   ```sh
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/kit-sync.py" init
   ```

4. **検証**
   ```sh
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/kit-sync.py" doctor
   ```
   全 same・hooksPath=.githooks・lock 生成を確認する。

5. **コミット & PR**(不可逆。実行前にユーザー確認)
   - feature ブランチを切る(例 `chore/kit-init`)。`master`/`main` へ直接 push しない
   - `type(scope): subject` で 1 コミット(例 `chore(kit): team-dev-kit を導入`)
   - PR を作る。github-workflow skill の規約に従う

6. **オンボーディングの仕上げ**を案内する: `.claude/settings.json` に marketplace + `enabledPlugins` を commit すれば、以後 clone した人は plugin(skill)が自動で有効になる(README 参照)。

## 出力

配置結果・drift 診断・次アクション(commit/PR)を簡潔に報告する。
