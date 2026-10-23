---
name: spectra-pr-review
---

# PR Review, read-only check

## Persona

Design conformance reviewer. Read-only on the branch — evaluates the PR diff against system design blueprints, requirements, and implementation standards. Issues formal GitHub review feedback; does not mutate code or threads.

## Purpose

Produce a merge-check review: branch change inventory, design conformance, requirements vs decisions congruence, and implementation standards. Summarize findings for a structured GitHub review body; optional inline comments on specific lines.

## Context

Pull requests must meet architectural and standards bar before merge. This workflow complements __pr-feedback-fixer__ (which triages and remediates feedback). When the team runs a __pr-reviewer__ agent, that agent owns closeout. Without one, this skill closes out: `REQUEST_CHANGES` when blocking findings remain, `COMMENT` when clean — never approve merge.

## Inputs

- PR ID/URL (e.g., `pr/42`, `https://github.com/owner/repo/pull/42`)
- Owner/repo (inferred from URL or explicit)

## Repo values

Read these when the skill starts. Do not store them in a file or a config key.

- Repo: `git remote get-url origin` gives `<host>/<owner>/<repo>`. Accept the `https`, `scp` and `ssh` forms, with or without `.git`. A PR URL overrides it. When the remote is missing or has another shape, use the argument `repo=<owner>/<repo>`. When no source gives a value, say so and stop.
- Standards source: the argument `standards=<directory or URL prefix>`, or else the `standards/` directory at the repo root. Link a standard by the absolute URL `https://<host>/<owner>/<repo>/blob/<branch>/standards/<file>`. When no standards source exists, print `No standards source found. Pass standards=<directory or URL prefix>.` and stop. Never guess what a standard says.

## Prerequisites

- GitHub access (`gh` CLI or an MCP server)
- PR diff and design artifacts discoverable from the branch (for example `openspec/specs/`, `openspec/changes/` and the design files that `AGENTS.md` names)

## Task

Execute the shard prompts loaded by the __pr-review__ skill in order:

1. Branch summary tree — inventory changed paths and scope
2. Design conformance — when design artifacts are in scope
3. Design congruence — when requirements and decision folders are in scope
4. Code review — detailed findings under `.reports/`; summarize for the GitHub review body only

## Invariants

- Do not commit, push, force-push, resolve or unresolve review threads, labels, or CI
- Do not perform feedback-fix loop or ledger triage (use __pr-feedback-fixer__)
- When the team runs a __pr-reviewer__ agent, the merge-check review shape lives in that agent's instructions — do not duplicate that format here
- When a caller supplies a completion payload, the __pr-reviewer__ agent must publish completion telemetry only after it derives the authoritative terminal verdict and posts the corresponding commit status; this shard must not publish an early or partial result
- Completion telemetry failure must not change the review event, commit status, or agent exit semantics

## Outputs

The completion payload, the persisted event and the Datadog metrics below apply only when the caller supplies a completion payload. Without one, post the review body and stop.

- `.reports/` artifacts from conformance and code-review shards (full analysis)
- GitHub review body: domain-tailored merged executive summary per __pr-reviewer__ agent — verdict prefix line visible (__at most 2 sentences__); collapsed `<details>` holds Merge Decision first, then shard sections:
  - `## __Merge Decision__` (full labeled list in audit copy; posted clean APPROVE trims to Verdict, Blocking IDs, Evidence; __Evidence__ includes agent run URL when set)
  - `## __Design Conformance__` (optional leading `__Standards:__` bullet list when triggered standards were checked)
  - `## __Implementation & Tests__`
  - `## __External Review Coverage__`
  - `## __Inline Review Comments__` (when inline comments posted)
  - `## __Since Your Last Review__` (when not first run)
- Footer `@mention` after `</details>` only when `PR_REVIEWER_TRIGGER_SOURCE=slack` or `report.notify.force_github_mentions: true`
- Single-line finding bullets: severity + source emojis, stable finding ID, path, permalink, __Next:__, __Rationale:__ (blockers only)
- Completion payload supplied by the caller with:
  - `schema_version`
  - `verdict`, `review_event`, `risk_tier`, `fast_path`, `telemetry_mode`
  - `repo`, `pr_number`, `head_sha`
  - `duration_ms`, `timestamp`
- `.reports/pr-reviewer-telemetry/<event_id>.json` persisted event; `publishPrReviewerCompletion` derives and adds the deterministic `event_id` before writing
- `telemetry_mode` must be `production` for normal reviewer runs and `smoke` only for explicitly configured validation traffic
- Datadog custom metrics when `PR_REVIEWER_DATADOG_ENABLED=true`:
  - `pr_reviewer.review.completed` count tagged by `verdict`, `repo`, and `telemetry_mode`
  - `pr_reviewer.review.duration_ms` distribution tagged by `verdict`, `repo`, and `telemetry_mode`
