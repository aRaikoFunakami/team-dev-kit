---
name: Feature request
about: A new feature or an improvement. Describe it at a technical-spec level so an AI can implement and finish it alone.
title: ""
labels: feature
assignees: ''
---

<!--
Title: one sentence with no prefix, stating "what becomes possible". Name the target (function / API / screen).
  Example: pick a target app and activity from the apps on the device and run it
Overview: Markdown template for a feature issue (spec-first).
Write it so work can start from "purpose → specification → targets → acceptance criteria" alone.
Design rationale and background come last. Keep each heading comment within its length limit. Delete sections you do not need.
-->

## Purpose
<!-- 1-2 lines. What and why. This alone must convey the gist of the implementation -->

## Specification
<!-- Gather here only testable implementation requirements (API / arguments / return values / exceptions).
     Put "why" under Design decisions and history under Background; do not mix them into this section -->

## Targets
<!-- List the files, directories, and modules to touch by name -->
-

## Acceptance criteria (tests / how to verify)
<!-- Only testable outcomes. Do not restate the specification. Write the test commands and expected results -->
- [ ]

## Design decisions
<!-- Bullet points of the reasons for the choice only. Details of comparisons and alternatives go to the PR / ADR -->

## Background
<!-- 3-5 lines. Only why it is needed now. Details go to design notes / ADR -->

## Findings / references / out of scope
<!-- Current-state findings, related issue / PR numbers, and what is not done this time. Give related items by number only (do not restate them in the body) -->

---
<!-- The rest is operational metadata (not part of the implementation). When reading, prefer the implementation information above -->

## Verification unit (feature)
<!-- Whether this issue can be verified end to end on its own. If not, one line naming the feature it is bundled into. Do not list sibling issues -->
- feature: standalone            <!-- Standalone E2E is possible. When bundled, write the <name> of feature/<name> -->
- E2E: verified by this issue alone   <!-- When bundled: "verified at the feature gate (not by this issue alone)" -->

## Branch
<!-- Standalone: feature/<issue>-<desc> / bundled: feature/<name>-<issue>-<desc> (base is the umbrella feature/<name>; separate with - because / hierarchies collide in git). The issue number is fixed once assigned -->
feature/<issue-number>-short-description
