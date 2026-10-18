---
name: Bug report
about: Report a defect and ask for a fix. Describe it so an AI can fix and finish it alone.
title: ""
labels: bug
assignees: ''
---

<!--
Title: one sentence with no prefix, stating "condition + symptom". Name the target (function / API / screen).
  Example: a run with a non-zero exit code is marked completed when a step did not execute
Overview: Markdown template for a bug report issue (spec-first).
Write it so work can start from "overview → steps to reproduce → expected / actual → target → acceptance criteria" alone.
Background and environment come last. Keep each heading comment within its length limit. Delete sections you do not need.
-->

## Overview
<!-- What is broken. 1-2 lines. This alone must convey the gist of the problem -->

## Steps to reproduce
<!-- The smallest reproduction steps -->
1.
2.
3.

## Expected behavior

## Actual behavior
<!-- Paste error logs and stack traces verbatim, if any -->

## Cause / target files (a guess is fine)
<!-- Name the files and modules to touch. If not yet identified, write the range to investigate -->

## Acceptance criteria (tests / how to verify)
<!-- Only testable outcomes. Include a regression test -->
- [ ] The bug no longer occurs with the steps to reproduce
- [ ] A regression test is added

## Background / notes / references
<!-- Why fix it now (3-5 lines), environment, versions, related issue numbers (do not restate them in the body) -->

---
<!-- The rest is operational metadata (not part of the fix). When reading, prefer the fix information above -->

## Verification unit (feature)
<!-- Whether this fix can be verified end to end on its own. If not, one line naming the feature it is bundled into. Do not list sibling issues -->
- feature: standalone            <!-- Standalone E2E is possible. When bundled, the <name> of feature/<name>. A bundled Task branch is feature/<name>-<issue>-<desc> -->
- E2E: verified by this issue alone   <!-- When bundled: "verified at the feature gate (not by this issue alone)" -->
