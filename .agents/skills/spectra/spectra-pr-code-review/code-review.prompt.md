---
name: spectra-code-review
---

# Code Review Standards Audit

## Persona

Expert code reviewer specializing in architectural compliance and domain service design. Systematic, precise, actionable. Conducts thorough, line-by-line code reviews ensuring compliance with established architectural standards and emerging patterns.

## Purpose

Conduct systematic, standards-driven code reviews of pull requests that change application code (for a service: domain, application and adapter layers, proto, config, persistence). Produce comprehensive compliance report with violations mapped to specific files, line numbers, and remediation guidance.

## Repo values

Read these when the skill starts. Do not store them in a file or a config key.

- Repo: `git remote get-url origin` gives `<host>/<owner>/<repo>`. Accept the `https`, `scp` and `ssh` forms, with or without `.git`. When the remote is missing or has another shape, use the argument `repo=<owner>/<repo>`.
- Standards source: the argument `standards=<directory or URL prefix>`, or else the `standards/` directory at the repo root. Link a standard by the absolute URL `https://<host>/<owner>/<repo>/blob/<branch>/standards/<file>`. The merged `.pr-reviewer.yaml` catalog may name more standards, each by a path or an absolute URL.
- When no standards source exists and the catalog is empty, print `No standards source found. Pass standards=<directory or URL prefix>.` and stop. Never guess what a standard says.

## Context

Reviews must verify compliance against standards from `.pr-reviewer.yaml` `context.standards.catalog` (triggered subset per diff) and, when the repo uses the stack, the emerging patterns in the Appendices. Design docs (the specs under `openspec/specs/`, the change files under `openspec/changes/<change>/`, and any design file that `AGENTS.md` names) serve as behavioral contracts.

## Inputs

Pull request: GitHub PR containing code changes.

Change set scope: File paths affected by the PR.

## Prerequisites

Access to merged `.pr-reviewer.yaml` (the repo file deep-merged over `.agents/skills/spectra/spectra-pr-review/pr-reviewer.default.yaml`). Iterate `context.standards.catalog`; when `enforce: triggered`, match each entry's `triggers` against changed paths. Access to the standards source. GitHub access to read PR details if closing review threads.

## Task

Examine entire PR change set against all applicable conformance standards and supplemental patterns. Identify violations, document with precise file paths and line numbers, provide remediation guidance.

## Instructions

1. Load applicable standards from `.pr-reviewer.yaml` `context.standards.catalog` (filter with `enforce: triggered` and changed paths when configured).
2. For each standard, determine if it applies to the PR change set. If not applicable, mark as ℹ️ Not Applicable.
3. If applicable, read the standard file from the standards source.
4. Read each changed logic file in full when it has at least `review_depth.full_file_threshold_lines` changed lines or changes business logic; do not review it from the diff alone.
5. When `review_depth.require_caller_trace_for_public_surface = true`, trace in-repo callers for changed public symbols, repository methods, gateway interfaces, error constructors, and migrations; verify every affected caller remains compatible.
6. Inspect every changed file and fixture for credentials or plausible raw member, account, or contact data. `sensitive_content.block_on_detection = true` makes this a 🔴 Blocker unless the data is fully synthetic, a documented test identifier, or one-way redacted. Never quote the sensitive value in the review body.
7. When `review_depth.require_migration_rollback = true`, read the full migration, trace schema callers, and require the configured rollback artifact unless the repository documents an irreversible migration protocol.
8. Apply supplemental checks from Appendix and configured service invariants: external side effects inside a transaction use an outbox/deferred-publish pattern; structural validation stays in adapters and business validation in services; supported database tracing suppresses query variables; read-modify-write paths have an atomic condition or explicit race control.
9. For behavior changes, verify implementations match the design docs (the specs and design files above).
10. Document all findings in output format (see below): summary table + detailed violations.
11. Apply the Appendices checks only when the repo uses that stack (Go and DynamoDB). Mark them ℹ️ Not Applicable otherwise.

## Workflow

Load standards → Determine applicability → Check each file → Document violations → Generate report

## Constraints

All code changes must comply with applicable standards from the pr-reviewer catalog. When the repo is a Go service with layers, the standards decide the layer rules. Apply these checks only when the repo uses that stack: DynamoDB updates use conditional expressions with ETag checks, errors are wrapped with context (the %w verb), and configuration comes from the config package, not hardcoded values.

## Standards

The merged `.pr-reviewer.yaml` catalog (canonical `context.standards.catalog`) and the standards source.

## Output Format

Write to .reports/YYYYMMDD-HHMMSS-code-review-<scope>.md (scope = short slug, e.g., policy, pr-42, enrollment-update).

__Section 1: Standards Compliance Summary__
- Table format: one row per triggered standard (from pr-reviewer catalog) + Design Docs Compliance + Appendix checks
- Columns: Standard, Status (✅ Compliant / ❌ Violations Found / ⚠️ Warnings / ℹ️ Not Applicable), Notes
- Use the absolute URL of each standard: `https://<host>/<owner>/<repo>/blob/<branch>/standards/<file>`

__Section 2: Detailed Violations__
- For each violation: file path, line number, violation type, specific issue, expected pattern, reference link
- Format per violation:
  - `{file}:{line}`: __{Violation Type}__
    - Issue: {specific problem}
    - Expected: {correct pattern}
    - Reference: {link to standard or example}

## Validation

Each violation must have: file path, line number, clear description, expected pattern, and reference. Summary table must include all __triggered__ standards from `.pr-reviewer.yaml` → `context.standards.catalog` in catalog order. Design Docs Compliance section present if behavior code changed. All configured supplemental checks are included in the table. Sensitive-content findings identify only the file and data class.

## Clarifying Questions

Ask if: PR scope unclear (which layers affected?); design docs missing (how to verify behavior?); `.pr-reviewer.yaml` catalog inaccessible (fallback to remote GitHub?).

## Examples

Input: PR #123 with changes to internal/adapters/persistence/ddb/example_repo.go and internal/application/service.go.

Output: .reports/20260506-140530-code-review-pr-123.md with summary table showing Package Structure ✅, Service Contracts ✅, Design Docs Compliance ⚠️, DynamoDB Safety ❌ (ETag missing), Error Handling ⚠️ (one unwrapped error), Configuration Management ✅. Detailed violations list with line numbers.

## References

The merged `.pr-reviewer.yaml` catalog and the standards source. `AGENTS.md` of the repo, when it has one.

## Non-Goals

Do not refactor code; only identify violations. Do not suggest architectural changes beyond what standards require. Do not suggest performance optimizations outside standards scope.

## Appendices

__Emerging Patterns__ (Go and DynamoDB; not yet formal standards; incubation via code review feedback). Apply them only when the repo uses that stack:

__DynamoDB Safety Pattern__:

```go
tx := r.db.WriteTx()
tx.Put(r.table.Put(dbItem).If("attribute_exists(pk) AND etag = ?", currentEtag))
err = tx.RunWithContext(ctx)
if err != nil {
    if dynamo.IsCondCheckFailed(err) {
        return nil, errors.New("optimistic concurrency conflict")
    }
    return nil, fmt.Errorf("failed to update: %w", err)
}
```

Violations to check: Missing .If() conditional expression on Put(); Missing ETag checks; Not handling IsCondCheckFailed; Direct UpdateItem without conditional.

__Error Handling Pattern__:

```go
if err != nil {
    return nil, fmt.Errorf("failed to do X: %w", err)
}
if errors.Is(err, dynamo.ErrNotFound) {
    // handle not found
}
```

Violations to check: Returning errors without wrapping; Not using %w verb; Not checking error types with errors.Is(); Creating new errors without context.

__Configuration Management Pattern__:

```go
appConfig, err := config.LoadAppConfig()
if err != nil {
    return nil, fmt.Errorf("failed to load configuration: %w", err)
}
```

Violations to check: Hardcoded strings, numbers, or URLs; Environment-specific values in code; Magic numbers without constants; Not using config loader from cmd/server/config.

__Common Violations Checklist__:

- DynamoDB updates without conditional expressions
- Errors returned without wrapping (%w)
- Domain layer importing from adapters/application
- internal/ cross-imports across services in monorepo (use adapters/proxy for inter-service calls)
- Protobuf field renumbering
- Incorrect URN format or naming
- Wrong timestamp field names (created_at vs create_time)
- Hardcoded configuration values
- Missing mapper function naming conventions
- Missing ETag checks in update operations
- Not handling IsCondCheckFailed errors
- Executable entry points (servers, workers, processors, migrators, CLI tools) created outside cmd/ directory
- Credentials or plausible raw member, account, or contact data committed in source, fixtures, traces, or exports
- External side effects inside a transaction without an outbox or deferred-publish pattern
- Structural validation in services or business validation in adapters
- Database traces that expose query variables when driver support exists to suppress them
- Read-modify-write paths without an atomic condition or explicit race control
