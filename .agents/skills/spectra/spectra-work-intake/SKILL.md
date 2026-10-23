---
name: spectra-work-intake
description: Draft and file a Jira work-item from a Slack request, routed by channel via the registry. Slack-triggered (notify) or manual chat invocation (draft).
---

Needs: Slack and Jira access (MCP servers), and a routing registry. Pass `registry=<path>`; without it the skill reads `channels.yaml` in this folder, which ships empty.

Prompt files are in `.agents/skills/spectra/`. Each item below gives the path.

Load and execute in order:

1. `.agents/skills/spectra/spectra-work-intake/draft-ticket.prompt.md` (always — resolves invocation, registry routing, drafts the ticket, and emits `open_items` for any unresolved TBD markers).
2. `.agents/skills/spectra/spectra-work-intake/file-ticket.prompt.md` (always — dedups, files or idempotently updates in Jira, and reports the outcome; posts numbered clarification questions in-thread when `open_items` is non-empty; skipped when draft-ticket reports an unmapped channel or an unresolved/partial Slack invocation).
