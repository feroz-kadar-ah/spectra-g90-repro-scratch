---
name: spectra-pr-code-review
description: Runs a standards-based code review per .agents/skills/spectra/spectra-pr-code-review/code-review.prompt.md, posts the review to a GitHub PR, and when asked to clear feedback it replies on each review thread and resolves CodeRabbit or human conversations after fixes land on the PR head.
---

Needs: GitHub access (an MCP server or `gh`), an `origin` remote on GitHub (or `repo=<owner>/<repo>`), and a standards source.

Prompt files are in `.agents/skills/spectra/`. Each item below gives the path.

Load and execute in order:

1. `.agents/skills/spectra/spectra-pr-code-review/code-review.prompt.md`
