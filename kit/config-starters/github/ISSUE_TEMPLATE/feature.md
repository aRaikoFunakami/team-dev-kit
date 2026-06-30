---
name: 機能追加 (Feature)
about: 新機能・機能改善。AI が単独で実装・完結できる技術仕様レベルまで記述する。
title: "feat(scope): "
labels: feature
assignees: ''
---

<!--
概要: 機能追加 Issue の Markdown テンプレート。
追加質問なしで着手できる粒度で記述する（github-workflow skill）。曖昧な要望のまま起票しない。
各見出しは自由記述。不要な節は削除してよい。
-->

## 検証単位 (feature)
<!-- このIssueが単体でE2E検証できるか。できないなら束ねる feature 名を1行で。兄弟Issueは列挙しない -->
- feature: 単体            <!-- 単体で E2E 可。N で束ねる場合は feature/<name> の <name> を書く -->
- E2E: このIssue単体で検証   <!-- 束ね時は「feature gate で検証（このIssue単体では検証しない）」 -->

## ブランチ
<!-- 単体: feature/<issue>-<desc> / 束ね: feature/<name>-<issue>-<desc>（base はアンブレラ feature/<name>。/ 階層は git で衝突するため - 区切り）。issue-number は採番後に確定 -->
feature/<issue-number>-short-description

## 背景・目的
<!-- なぜやるか。解決する課題・現状の問題 -->

## 対象ファイル / モジュール
<!-- 触るファイル・ディレクトリを具体名で列挙 -->
-

## 変更方針
<!-- 実装アプローチ。どう作るか -->

## 受け入れ条件（テスト / 検証方法）
<!-- 完了判定基準。テストコマンド・確認手順・期待結果 -->
- [ ]

## 補足 / 参考
<!-- 関連 Issue/PR、参考リンク、制約事項（任意） -->
