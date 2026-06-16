---
name: kit-init
description: team-dev-kit を消費プロジェクトへ初回導入する。framework(共通・触禁止: .team-dev-kit/contract.md・base.gitleaks.toml・.githooks/pre-commit)を配置し、config 雛形(AGENTS.md・.gitleaks.toml・.github)を1回だけ置き、.team-dev-kit.lock 生成と core.hooksPath 設定を行う。`/kit-init` が明示的に呼ばれたときのみ起動。自然言語の依頼・関連語(初期化/セットアップ/導入 等)では自動起動しない。
---

# kit-init

team-dev-kit の Plane B を初回導入する。Plane A(skill・フック)は plugin 側で既に有効な前提。

## 厳守

明示 `/kit-init` のときだけ実行する。ファイル配置・git config 変更・PR を伴うため自動発火させない。

## framework と config の区別

- **framework**(共通・編集禁止): `.team-dev-kit/contract.md`, `.team-dev-kit/base.gitleaks.toml`, `.githooks/pre-commit`。`/kit-update` が置換する。
- **config**(プロジェクトが書く): `AGENTS.md`(`@.team-dev-kit/contract.md` を import + 固有節), `.gitleaks.toml`(base を extend + 固有 allowlist), `.github/*`。init で雛形を1回だけ置き、以後 kit は触らない。

## 手順

1. **dry-run**
   ```sh
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/kit-sync.py" init --dry-run
   ```
   framework=write、config=write/skip(既存は skip)、hooksPath を確認する。

2. **本実行**(既存 config を上書きしたい時だけ `--force`)
   ```sh
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/kit-sync.py" init
   ```

3. **検証**
   ```sh
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/kit-sync.py" doctor
   ```
   framework=ok、hooksPath=.githooks、lock 生成を確認。`core.hooksPath` が既に他(husky 等)なら警告。手動統合を促す。

4. **コミット & PR**(不可逆。実行前にユーザー確認)。feature ブランチ + `chore(kit): team-dev-kit を導入`。`master`/`main` 直接 push 禁止。

5. **オンボーディング仕上げ**を案内: `.claude/settings.json` に marketplace + `enabledPlugins` を commit すれば、以後 clone した人は plugin(skill)が自動で有効になる(README 参照)。

## 出力

framework/config の配置結果・diagnose・次アクションを簡潔に報告する。
