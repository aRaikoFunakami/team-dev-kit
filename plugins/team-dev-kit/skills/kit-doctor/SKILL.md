---
name: kit-doctor
description: team-dev-kit の導入状態を診断する(read-only)。依存(gitleaks/git)、core.hooksPath、kit バージョン差、framework ファイルの drift(編集禁止ファイルが改変されていないか)、config の存在を点検する。`/kit-doctor` が明示的に呼ばれたときのみ起動。自然言語の依頼・関連語(診断/チェック/health 等)では自動起動しない。
---

# kit-doctor

team-dev-kit の健全性を点検する。書き込みは一切しない。

## 厳守

明示 `/kit-doctor` のときだけ実行する。自動発火させない(SessionStart 等からも呼ばない)。

## 手順

```sh
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/kit-sync.py" doctor
```

## 読み取り方

- **dep MISSING**(gitleaks/git) → フックが止まる。導入を促す
- **core.hooksPath ≠ .githooks** → 人間の commit が pre-commit を通らない。`/kit-init` か手動統合
- **lock なし** → `/kit-init` 未実行
- **version 差** → `/kit-update` を検討
- **framework DRIFTED** → 編集禁止の共通ファイルが改変されている。`/kit-contribute` で還元 or `/kit-update --force` で破棄
- **framework MISSING** → 配置漏れ。`/kit-init` か `/kit-update`
- **config present/absent** → プロジェクト所有。drift 判定しない(absent はプロジェクトが意図的に消した可能性)

## 出力

問題(exit 1)と framework drift(情報)を分けて簡潔に報告し、次アクションを 1〜2 個提示する。
