---
name: kit-update
description: team-dev-kit の Plane B(リポジトリに commit するテンプレ群)を新しい kit バージョンへ 3-way merge で更新し、.team-dev-kit.lock を更新する。祖先=lock.version、新=導入中の plugin、theirs=作業ツリーを突き合わせ、ローカル改変を保ったままで kit の変更を取り込む。`/kit-update` が明示的に呼ばれたときのみ起動。自然言語の依頼・関連語(更新/アップデート/同期 等)では自動起動しない。
---

# kit-update

Plane B を新バージョンへ 3-way merge で更新する。Plane A(skill・フック)は別途 `/plugin update` で更新する。

## 厳守

明示 `/kit-update` のときだけ実行する。ファイル改変・lock 更新・PR を伴うため自動発火させない。

## 前提

- `/plugin update team-dev-kit@team-dev-kit` を先に実行し、plugin(=新テンプレ+新 version)を取り込んでおく
- 祖先(旧バージョンの templates)は marketplace repo の `tag v<lock.version>` から自動取得する。tag が無い/オフラインなら `--ancestor-dir` に旧 templates を渡す

## 手順

1. **dry-run でプレビュー**(書き込まない)
   ```sh
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/kit-sync.py" update --dry-run
   ```
   `旧ver -> 新ver`、変更ファイル、衝突予定を表示する。

2. **本実行**
   ```sh
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/kit-sync.py" update
   ```
   - `変更 N 件` … クリーンに取り込んだ(ローカル改変は保持)
   - `⚠ 衝突 N 件` … 該当ファイルに `<<<<<<< consumer(local) / ======= / >>>>>>> kit(new)` マーカー。**人が解決する**
   - `manual` … 祖先に無い等で 3-way 不能。内容を見て手当て

3. **衝突解決**: マーカーを除去し、両者の意図を反映する。`git diff` で確認。

4. **検証**
   ```sh
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/kit-sync.py" doctor
   ```
   バージョンが揃い、残すべきローカル改変だけが drift として残ることを確認する。

5. **コミット & PR**(不可逆。実行前にユーザー確認)
   - feature ブランチ(例 `chore/kit-update-vX`)。`master`/`main` 直接 push 禁止
   - `chore(kit): team-dev-kit を vX へ更新`。衝突解決の判断は本文に記す
   - PR を作る(github-workflow 規約)

## 出力

旧→新バージョン、クリーン取込件数、衝突ファイル一覧と解決要否、次アクションを簡潔に報告する。
