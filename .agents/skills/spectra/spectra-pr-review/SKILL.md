---
name: spectra-pr-review
title: PR Review (read-only)
version: 1.3
description: >-
  Read-only PR review — branch change inventory, design conformance, requirements vs decisions congruence, implementation standards.
  Agent posts REQUEST_CHANGES + structured review; no branch or thread mutation.
---

Needs: GitHub access (an MCP server or `gh`), an `origin` remote on GitHub (or `repo=<owner>/<repo>`), and a standards source.

Prompt files are in `.agents/skills/spectra/`. Each item below gives the path.

Load and execute in order:

1. `.agents/skills/spectra/spectra-pr-review/pr-review.prompt.md`
2. `.agents/skills/spectra/spectra-pr-review/pr-branch-summary-tree.prompt.md`
3. `.agents/skills/spectra/spectra-pr-review/check-conformance.prompt.md` — when design artifacts are in scope (infer from the branch summary tree and diff)
4. `.agents/skills/spectra/spectra-pr-review/check-congruence.prompt.md` — when requirements and design-decision folders are in scope for the PR (infer paths from the tree and diff)
5. `.agents/skills/spectra/spectra-pr-code-review/code-review.prompt.md` — write detailed findings under `.reports/`; summarize for the GitHub review body only

Follow each shard end-to-end. The merge-check closeout shape comes from the review agent that the team runs, when it has one. Without one, close with the findings and a verdict.
