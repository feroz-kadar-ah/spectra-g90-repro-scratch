---
name: spectra-file-ticket
---

# Work Intake — File Ticket

## Purpose

Take the drafted ticket and routing from [draft-ticket.prompt.md](./draft-ticket.prompt.md), deduplicate against existing Jira issues via the dedup marker, create or update the ticket with the Jira account that the automation holds, and report the outcome — a Slack in-thread reply for `notify`, a chat response for `draft`.

## Prerequisites

`draft-ticket.prompt.md` has already produced `mode`, `effective_routing`, `dedup_marker_line`, `title`, `description`, `open_items`, and `reply_target`. If it instead reported `mode: unmapped_channel` or `mode: unresolved`, this shard never runs — the gap was already reported (or, for `unresolved` with no thread to reply to, deliberately left unreported).

## Clarification loop

Applies to `notify` (Slack thread) and `draft` (chat) when `open_items` is non-empty after Step 5 in draft-ticket.

```
first pass (notify)
├─ dedup → create
├─ file ticket (TBD markers allowed)
└─ Slack closeout + numbered open_items questions

requester replies in thread
└─ automation re-triggers on thread activity

subsequent passes
├─ draft-ticket re-reads full thread; resolves answered TBDs
├─ dedup → update (same issue key — idempotent)
├─ editJiraIssue replaces description with refreshed draft
└─ if open_items still non-empty → post only the remaining numbered questions
    else → final closeout (no TBD footnote)
```

- __Idempotent update:__ the dedup marker in References is the sole identity key; every re-run updates the matched issue — never create a second ticket for the same Slack thread.
- __One outcome message per run:__ post the closeout or the next numbered question block — not both patterns in separate messages unless a Jira write failed and you are reporting the failure.
- __Stop condition:__ `open_items: []` — post the standard Created/Updated closeout with no clarification block.

## Instructions

### Step 1: Dedup search

```
JQL: project = <effective_routing.project_key>
     AND description ~ "\"<dedup_marker_line>\""
     ORDER BY created ASC, id ASC
```

- __Found exactly one:__ continue in __update__ mode only when the issue description contains the work-intake `dedup.marker_prefix` from the registry or carries the `work-intake` label from `effective_routing.labels`. If the match is only a coincidental `Slack thread:` citation without those intake markers, treat as __create__ mode (do not overwrite a non-intake issue).
- __Found none:__ continue in __create__ mode.
- __Found more than one__ (should not happen under this contract): select the first result — the explicit `ORDER BY` makes "oldest by `created`, `id` as tiebreak" deterministic; do not create a third.

### Step 2: File in Jira

- When multiple agent runs may process the same Slack thread concurrently, prefer create mode if dedup search and create are not atomic; after create, re-run dedup search and close duplicate issues if two creates raced (report both keys in the closeout).

- __Create mode:__ `createJiraIssue` with `title`, `description`, and the fields from `effective_routing`.
- __Update mode:__ `editJiraIssue` on the matched issue key — replace the description with the freshly composed one; leave the title as originally filed (a human may have already edited it; never overwrite a human-edited title). This is the only edit authority this shard has.

__No pre-file confirmation gate:__ file even when `description` still carries TBD markers — the ticket carries the gap and the clarification loop closes it in-thread.

### Step 3: Report the outcome

__When `open_items` is empty__ — final closeout:

```
<Created|Updated> <PROJECT-123>: <title>
<jira issue URL>
```

__When `open_items` is non-empty__ — file first, then ask in-thread (or in chat for `draft`):

```
<Created|Updated> <PROJECT-123>: <title>
<jira issue URL>

A few details are still open — reply in this thread and I'll update the ticket:
1. <open_items[0].question>
2. <open_items[1].question>
…
```

Numbering must match `open_items[].id`. Do not use a generic "see the ticket" footnote — always list the specific unanswered questions.

- `reply_target: slack_thread` — post this as one Slack reply to the triggering thread.
- `reply_target: chat` — return this in the chat response; do not post to Slack (there is no thread).

## Write authority and guardrails

- __May:__ `createJiraIssue` once per new thread/request; `editJiraIssue` on the description only of a ticket matched via the dedup marker (including clarification-loop updates); one outcome report per run (Slack reply or chat response, never both).
- __Never:__ transition status, change assignee/reporter after creation, delete an issue, edit any field it did not compose, or write to a ticket not matched via the dedup marker.
- __Never:__ block filing while waiting for clarifications — ask after the write when `open_items` is non-empty.

## Constraints

- Unmapped channel is handled entirely by `draft-ticket.prompt.md` — this shard assumes a resolved mapping and a drafted ticket.
- If `createJiraIssue` fails, re-run the dedup search before any retry. If the marker now matches an issue, continue in update mode or report that issue. Do not repeat `createJiraIssue` directly after an ambiguous failure.
- If `editJiraIssue` fails, report the failure via `reply_target`; do not retry silently more than once.
- Do not fabricate a Slack thread permalink when `dedup_marker_line` uses the `(manual invocation — request-id: …)` form.

## Output Format

Closeout: issue key, mode (`created`/`updated`), issue URL, `open_items` count (0 = complete), and whether a clarification question block was posted.

## References

- [draft-ticket.prompt.md](./draft-ticket.prompt.md)
- The routing registry (`registry=<path>`, or `channels.yaml` in this folder)

## Non-Goals

Do not create a second ticket for a request that already has one. Do not transition or reassign any ticket. Do not draft or re-draft ticket content — that is draft-ticket.prompt.md's job.
