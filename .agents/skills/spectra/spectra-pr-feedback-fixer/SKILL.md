---
name: spectra-pr-feedback-fixer
title: PR Feedback Fixer
version: 1.7
description: >-
  PR feedback triage — ledger, session report, reply-summary. Loop mode iterates until
  green and merge-ready without regressing prior session fixes or decisions.
  Invokes conformance and code-review shards when the playbook requires; not merge-check review.
---

Needs: GitHub access (an MCP server or `gh`), `make`, and an `origin` remote on GitHub (or `repo=<owner>/<repo>`). The conformance and code-review steps also need a standards source.

Prompt files are in `.agents/skills/spectra/`. Each item below gives the path.

Load and execute in order:

1. `.agents/skills/spectra/spectra-pr-feedback-fixer/pr-feedback-fixer.prompt.md`
2. `.agents/skills/spectra/spectra-pr-review/check-conformance.prompt.md`
3. `.agents/skills/spectra/spectra-pr-code-review/code-review.prompt.md`

Follow prompt 1 end-to-end for ledger, threads, and loop; run 2–3 when that flow requires.

__Loop mode:__ iterate until the PR is green and merge-ready (checks, Critical/Major, ledger). Each pass must preserve prior fixes, replies, and decisions from this conversation — no regression or silent rollback.

## Bundled prompts

Load one of these files when the task matches. The files are in this folder.

- `update-spec-per-feedback.prompt.md`: Update a system spec from review feedback, discussions, and ancillary artifacts to close gaps and improve rigor.
