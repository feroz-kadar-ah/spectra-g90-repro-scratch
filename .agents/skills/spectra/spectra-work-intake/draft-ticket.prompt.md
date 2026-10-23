---
name: spectra-draft-ticket
---

# Work Intake — Draft Ticket

## Persona

Role: product-savvy technical business analyst. Tone: concise, concrete, no filler.

## Purpose

Resolve the invocation (Slack-triggered `notify` or manual chat `draft`), gather the request, resolve Jira routing from the registry, and draft the full ticket body. Always loaded first; never talks to Jira or Slack — that is [file-ticket.prompt.md](./file-ticket.prompt.md)'s job.

## Context

Work Intake turns a Slack request into a filed Jira task, replete with Context, Motivation, Acceptance Criteria, Key Deliverables, Assumptions & Constraints, and References — using the Jira and Slack accounts that the automation holds. It has two entry points: a Cursor Automation triggered by a Slack message (`notify`), and a manual invocation from chat with no live Slack thread (`draft`). Both run this shard, then `file-ticket.prompt.md`.

__Clarification loop (`notify` only):__ file the ticket on the first pass even when gaps remain — never block filing to ask questions first. When the draft still carries `TBD — needs input from requester` markers, `file-ticket.prompt.md` posts numbered questions in the Slack thread. Each later thread reply re-triggers the agent; this shard re-reads the full thread, resolves any TBD that the requester answered, and emits the remaining `open_items`. `file-ticket.prompt.md` then __updates__ the same Jira issue idempotently via the dedup marker — it never creates a second ticket for the same thread. The loop ends when `open_items` is empty.

## Inputs

```
invocation
├─ notify — WORK_INTAKE_SLACK_CHANNEL_ID, WORK_INTAKE_SLACK_THREAD_PERMALINK (env, Cursor Automation)
└─ draft  — target channel (#name or channel_key) + request text (chat message)

Both modes accept `registry=<path>`: the routing registry to read. Without it the skill reads `channels.yaml` in this folder, which ships empty.
```

Both `notify` env vars are required. Fail closed (reply in-thread, do not file — see Step 2) when either is unset, or when the resolved channel has no registry entry.

## Instructions

### Step 1: Determine mode and gather the request

- Both `WORK_INTAKE_SLACK_CHANNEL_ID` and `WORK_INTAKE_SLACK_THREAD_PERMALINK` set → `mode = notify`.
- Neither set, with a channel and request text supplied directly in the chat message → `mode = draft`. `draft` is selected only for that explicit chat invocation — never inferred from a missing Slack env var.
- Exactly one of the two Slack env vars set → `mode = unresolved`: a partial or broken Slack-trigger invocation. Compose a `reply_message` explaining which env var is missing and that work intake cannot proceed; set `reply_target: slack_thread` when `WORK_INTAKE_SLACK_THREAD_PERMALINK` is available, otherwise `reply_target: none` — there is nowhere to post one. Do not fall back to `draft` and do not proceed to Step 2. `file-ticket.prompt.md` never runs for `mode: unresolved`, exactly as for `mode: unmapped_channel`.

- __notify:__ `slack_read_thread` the thread at `WORK_INTAKE_SLACK_THREAD_PERMALINK` (root + all replies). `request_text` + `source_context` = that thread.
- __draft:__ `request_text` = the chat-supplied text; `source_context` = any doc/thread link pasted alongside it.

### Step 2: Resolve registry routing

1. Choose the registry. Use the file that the argument `registry=<path>` names. Without the argument, use `.agents/skills/spectra/spectra-work-intake/channels.yaml`. When the chosen file does not exist, say so and stop.
2. Load the registry.
3. Match the channel:
   - `notify` — `WORK_INTAKE_SLACK_CHANNEL_ID` against `channels[].slack.channel_id`.
   - `draft` — the named channel against `channels[].channel_key` or `channels[].display_name`.
4. __No match:__ do not draft or file anything. Compose a `reply_message` naming the registry file and stating the channel is not registered for work intake (the registry that ships with the skill is empty); set `reply_target: slack_thread` for `notify`, `reply_target: chat` for `draft`. Stop — `file-ticket.prompt.md` never runs.
5. __Match:__ merge the channel entry over `defaults.jira` (channel keys win) to produce `effective_routing` (`project_key`, `issue_type`, `labels`, `components`, `priority`, `epic_link`, `additional_fields`) and `defaults.dedup.marker_prefix`.

### Step 3: Compose the dedup marker line

- `notify` — `<marker_prefix> <WORK_INTAKE_SLACK_THREAD_PERMALINK>`
- `draft` — `<marker_prefix> (manual invocation — request-id: <request_id>)` where `request_id` is the first 12 lowercase hex characters of SHA-256 over UTF-8 `normalized_request_text|normalized_source_context|invocation_id`. `invocation_id` is a caller-supplied stable id when the user is retrying the same draft; otherwise generate a new random UUID for this chat invocation and embed it in the marker so two distinct manual requests with identical text do not collide. Replays with the same `invocation_id` must match idempotently.

### Step 4: Draft the ticket

Extract a clear, actionable title and compose a Jira-Markdown description. Infer reasonable context from `request_text`/`source_context`; do not hallucinate specifics (a name, a date, a number) that were not stated or clearly implied. __No pre-file confirmation gate:__ when a section can't be supported by the thread yet, flag it inline with a __specific__ question and continue — never block filing to ask in Slack first; `file-ticket.prompt.md` owns the post-file clarification questions.

__Title:__ starts with a verb, states the outcome, one line (e.g. "Add retry backoff to the ingest worker", not "Ingest worker issue").

__Description__ — exactly these headings, in this order. Omit a section's body only when nothing supports it; state `TBD — needs input from requester: <specific question>` inline rather than dropping the heading, so a reader can see what's missing. Every TBD line must end with the concrete question you need answered — never a bare `TBD` with no question.

```
__Context__
1-2 paragraphs: current state, why this is being filed now, upstream dependencies.

__Motivation__
Business/technical value. What breaks or stays broken without this?

__Acceptance Criteria__
- [ ] Actionable, checkable bullets (or Given/When/Then). Never empty — if
      request_text gives no clear done-condition, write one TBD bullet:
      "- [ ] TBD — needs input from requester: what does \"done\" look like?"

__Key Deliverables__
Tangible outputs (endpoint, doc, dashboard, migration, etc.).

__Assumptions & Constraints__
- Assumptions: what we're taking as true.
- Constraints: deadlines, budgets, legacy systems.
- Dependencies: blocking tickets or external teams, if named.

__References__
- <dedup_marker_line> (always first — see § Dedup marker)
- Any other linked docs/threads from source_context
```

__Fields__ — `project_key`, `issue_type`, `labels`, `components`, `priority`, `epic_link`, `additional_fields` copied unchanged from `effective_routing`. Never add or drop a label/component the routing didn't specify.

### Step 5: Resolve open items from thread replies

After Step 4, scan the composed `description` for every `TBD — needs input from requester:` line.

1. Parse each remaining TBD into `{section, question}` — the section is the nearest preceding `__Heading__`; the question is the text after the colon.
2. Re-read human messages in `source_context` (__notify__) or the chat turn history (__draft__). Skip messages authored by the work-intake agent or other automation accounts — only requester replies count as answers.
3. When a later human message directly answers a TBD question, replace that TBD line (or bullet) with the stated fact in the appropriate section and remove the marker.
4. Emit `open_items` — a 1-based numbered list of `{id, section, question}` for every TBD still present after the resolution pass. When none remain, emit `open_items: []`.

On a re-triggered `notify` run, treat prior work-intake clarification posts as context only; new human replies since the last agent post are the primary answer source.

## Dedup marker

The first bullet of __References__ is always the `dedup_marker_line` verbatim (e.g. `Slack thread: https://<workspace>.slack.com/archives/C.../p...`, or `Slack thread: (manual invocation — request-id: df53307cd32b)` for a `draft` request with that normalized hash). This is the sole key `file-ticket.prompt.md` searches on to avoid filing a duplicate — do not paraphrase, omit, or move it.

## Constraints

- Never invent a `channel_id` or `project_key` not present in the registry; never draft or file for an unmapped channel.
- Never select `draft` because a Slack env var is missing — a partial Slack-trigger invocation is `unresolved`, not `draft`.
- Do not fabricate a reporter, assignee, due date, or dollar figure that `request_text`/`source_context` does not support.
- Do not invent additional description sections beyond the six listed.
- Do not ask clarifying questions in Slack or chat from this shard — flag a gap as `TBD — needs input from requester: <specific question>` and continue; `file-ticket.prompt.md` posts the numbered follow-ups after filing.

## Output Format

```yaml
# notify | draft — full ticket draft
mode: notify|draft
effective_routing: {project_key, issue_type, labels, components, priority, epic_link, additional_fields}
dedup_marker_line: <string>
title: <string>
description: <Jira-Markdown string, six sections as above>
open_items:                       # [] when every TBD is resolved
  - id: 1
    section: <heading name>
    question: <specific question still unanswered>
reply_target: slack_thread|chat   # notify -> slack_thread, draft -> chat

# unmapped_channel | unresolved — early stop (file-ticket never runs)
mode: unmapped_channel | unresolved
reply_target: slack_thread|chat|none
reply_message: <string>           # required when reply_target != none
```

## Validation

- [ ] Title starts with a verb, one line.
- [ ] All six headings present in order.
- [ ] Every Acceptance Criteria bullet is checkable (starts `- [ ]`).
- [ ] References' first bullet is the dedup marker line, verbatim.
- [ ] No fabricated names, dates, or figures.

## Examples

__Input (notify):__ Thread in `#team-intake`: "Can we get the nightly report job to also warn when a repo has no `CODEOWNERS` file at all, not just a stale one? Sam hit this yesterday on `svc-example`." Reply: "no rush, just annoying."

__Output (excerpt):__

```
title: Warn when a repo has no CODEOWNERS file in the nightly report

__Context__
The nightly report job currently warns on a stale CODEOWNERS file but
not on a repo missing the file entirely. Sam hit this on svc-example.

__Motivation__
A silent no-warning path means a repo can look covered when it never was,
delaying follow-up without anyone noticing.

__Acceptance Criteria__
- [ ] The report emits a distinct warning when CODEOWNERS is absent
      (not the existing stale-file warning)
- [ ] TBD — needs input from requester: should this block the report or only warn?

__Key Deliverables__
Updated warning path + one test fixture for the missing-file case.

__Assumptions & Constraints__
- Assumptions: this is a low-priority polish item ("no rush").
- Constraints: none stated.
- Dependencies: none stated.

__References__
- Slack thread: https://<workspace>.slack.com/archives/C0000000000/p1234567890
```

## References

- [file-ticket.prompt.md](./file-ticket.prompt.md)
- The routing registry (`registry=<path>`, or `channels.yaml` in this folder)

## Non-Goals

Do not call createJiraIssue, editJiraIssue, searchJiraIssuesUsingJql, or any Slack write tool from this shard. Do not decide the dedup outcome — only compose the marker line; the search itself belongs to file-ticket.prompt.md. Do not post or file anything.
