---
name: spectra-decisions
description: Extract architecture decision records from a design, and decision matrices from research. Use when a design or research document needs its decisions made explicit.
---

Needs: a design or research document that the person gives you. The decision matrix prompt also needs a standards source with a decision analysis standard.

## Bundled skills and prompts

- `grill/SKILL.md` (`spectra-grill`): Proposal-stage glossary grill; writes confirmed terms to `docs/glossary.md` (see `grill/glossary-format.md`).

Load one of these prompt files when the task matches. The files are in this folder.

- `extract-adr-from-design.prompt.md`: Generate an ADR in Markdown from design and strategy documents.
- `extract-decision-matrix-from-research.prompt.md`: Produce a complete decision analysis for one architectural decision from alternatives, factors, and supporting artifacts.
