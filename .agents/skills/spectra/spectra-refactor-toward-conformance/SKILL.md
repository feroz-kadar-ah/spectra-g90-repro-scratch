---
name: spectra-refactor-toward-conformance
description: Iteratively refactors a target repository to build conformance to design standards one at a time, running smoke and integration tests after each refactor and committing each conformance increment. Use when the user wants to incrementally improve standards compliance without altering system behavior.
---

Needs: a standards source, a test command for the repo (`make test`, or the one that the person names), and a clean working tree on a branch that is not the default branch.

Prompt files are in `.agents/skills/spectra/`. Each item below gives the path.

Load and execute in order:

1. `.agents/skills/spectra/spectra-refactor-toward-conformance/refactor-toward-conformance.prompt.md`
