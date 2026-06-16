---
name: kit-update
description: team-dev-kit の framework ファイル(.team-dev-kit/contract.md・base.gitleaks.toml・.githooks/pre-commit)を新しい kit バージョンへ置換更新し、.team-dev-kit.lock を更新する。config(AGENTS.md・.gitleaks.toml・.github)はプロジェクト所有なので触らない。`/kit-update` が明示的に呼ばれたときのみ起動。自然言語の依頼・関連語(更新/アップデート/同期 等)では自動起動しない。
---

# kit-update

framework を新バージョンへ**置換**で更新する。config は触らない。Plane A(skill・フック)は別途 `/plugin update`。

## 厳守

明示 `/kit-update` のときだけ実行する。ファイル置換・lock 更新・PR を伴うため自動発火させない。

## 前提

`/plugin update team-dev-kit@team-dev-kit` を先に実行し、plugin(新 framework + 新 version)を取り込んでおく。

## 手順

1. **dry-run**
   ```sh
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/kit-sync.py" update --dry-run
   ```
   `旧ver -> 新ver`、置換予定、drift skip 予定を表示する。

2. **本実行**
   ```sh
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/kit-sync.py" update
   ```
   - framework は置換(3-way 不要)。config は触らない
   - `⚠ drift skip` … その framework ファイルがローカル編集されている。framework は編集禁止なので、(a) 改善なら `/kit-contribute` で上流へ、(b) 破棄して最新化するなら `--force` で置換

3. **drift があった場合の判断**: 内容を確認し、上流還元か `--force` 置換かを選ぶ。

4. **検証**
   ```sh
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/kit-sync.py" doctor
   ```
   version が揃い framework が ok になることを確認。

5. **コミット & PR**(不可逆。実行前にユーザー確認)。feature ブランチ + `chore(kit): team-dev-kit を vX へ更新`。

## 出力

旧→新バージョン、置換件数、drift skip の有無と対処、次アクションを簡潔に報告する。
