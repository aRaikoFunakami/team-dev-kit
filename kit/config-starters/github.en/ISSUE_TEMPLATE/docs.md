---
name: Documentation (Docs)
about: Add or fix documentation.
title: ""
labels: documentation
assignees: ''
---

<!--
Title: one sentence with no prefix, stating "which document gets what added / fixed".
  Example: add a note on port forwarding under Colima to the startup steps in the README
Overview: Markdown template for a documentation issue (spec-first).
Write it so work can start from "purpose → changes → target files → acceptance criteria" alone.
Background comes last. Keep each heading comment within its length limit. Delete sections you do not need.
-->

## Purpose
<!-- 1-2 lines. What to update and why. This alone must convey the gist -->

## Changes
<!-- Gather here the approach for what to add, fix, or remove -->

## Target files
<!-- List the documents to update by name -->
-

## Acceptance criteria
<!-- Only testable outcomes, such as no broken links and consistent wording -->
- [ ] The text matches the latest behavior
- [ ] No broken links

## Background / notes / references
<!-- Why the update is needed (3-5 lines), what is wrong with the current text, related issue numbers (do not restate them in the body) -->

---
<!-- The rest is operational metadata (not part of the update). When reading, prefer the update information above -->

## Verification unit (feature)
<!-- Whether this issue can be verified on its own. If not, one line naming the feature it is bundled into. Do not list sibling issues -->
- feature: standalone            <!-- Verifiable on its own. When bundled, the <name> of feature/<name>. A bundled Task branch is feature/<name>-<issue>-<desc> -->
- E2E: verified by this issue alone   <!-- When bundled: "verified at the feature gate (not by this issue alone)" -->
