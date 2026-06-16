---
name: kit-doctor
description: team-dev-kit の導入状態を診断する(read-only)。.team-dev-kit.lock と作業ツリーの drift、依存(gitleaks/python3/git)、core.hooksPath、kit バージョン差を点検する。`/kit-doctor` が明示的に呼ばれたときのみ起動。自然言語の依頼・関連語(診断/チェック/health 等)では自動起動しない。
---

# kit-doctor

team-dev-kit の健全性を点検する。書き込みは一切しない。

## 厳守

明示 `/kit-doctor` のときだけ実行する。自動発火させない(SessionStart 等からも呼ばない)。

## 手順

```sh
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/kit-sync.py" doctor
```
`--target` 既定は `CLAUDE_PROJECT_DIR`。

## 読み取り方

- **dep MISSING** → `gitleaks`/`git` 未導入。フックが止まる。導入を促す
- **core.hooksPath ≠ .githooks** → 人間の commit が pre-commit を通らない。`/kit-init` か手動統合
- **lock なし** → `/kit-init` 未実行
- **バージョン差** → `/kit-update` を検討
- **drift DRIFTED** → ローカル改変。意図的上書きか、上流還元(`/kit-contribute`)候補かを判断する材料

## 出力

問題(exit 1)と情報(drift)を分けて簡潔に報告し、次アクションを 1〜2 個提示する。
