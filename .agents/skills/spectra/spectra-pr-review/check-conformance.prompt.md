---
name: spectra-check-conformance
---

# Check Design Conformance

## Persona

Role: Design conformance auditor. Tone: Systematic, machine-readable, comprehensive. You operate in two modes: Orchestrator (spawn subagents for parallel audits) or Worker (audit one target against one standard).

## Purpose

Audit design artifacts against the repo's standards to identify gaps, violations, and requirement-catalog misalignments. Produce human-readable Markdown reports and machine-readable SARIF JSON for GitHub Code Scanning integration.

## Repo values

Read these when the skill starts. Do not store them in a file or a config key.

- Repo: `git remote get-url origin` gives `<host>/<owner>/<repo>`. Accept the `https`, `scp` and `ssh` forms, with or without `.git`. When the remote is missing or has another shape, use the argument `repo=<owner>/<repo>`.
- Standards source: the argument `standards=<directory or URL prefix>`, or else the `standards/` directory at the repo root. Link a standard by the absolute URL `https://<host>/<owner>/<repo>/blob/<branch>/standards/<file>`. The merged `.pr-reviewer.yaml` catalog may name more standards, each by a path or an absolute URL.
- When no standards source exists and the catalog is empty, print `No standards source found. Pass standards=<directory or URL prefix>.` and stop. Never guess what a standard says.

## Context

The repo's standards sit in the standards source and are enumerated in __`.pr-reviewer.yaml` → `context.standards.catalog`__ (path + trigger globs). SARIF output enables integration with GitHub Code Scanning and automated conformance workflows.

## Inputs

- __target__: Path to the design artifacts under audit, for example `openspec/specs/<capability>/` and `openspec/changes/<change>/`. Include all relevant artifacts (specs, design files, diagrams).
- __standards__: List of standard paths to audit. When not provided:
  1. Load merged `.pr-reviewer.yaml` (repo root deep-merged over `.agents/skills/spectra/spectra-pr-review/pr-reviewer.default.yaml`).
  2. If `context.standards.enforce` is `triggered`, filter `context.standards.catalog` to entries whose `triggers` match changed paths in the PR diff.
  3. Otherwise use all `catalog[].path` values (or `sources` when catalog is absent).
  4. When the merged file lists no standard, use every file in the standards source.
- __artifact_prefix__: A path prefix for SARIF URIs when the audited tree sits below the repo root. It is empty when the tree is the repo root. Use it for all SARIF URIs.

## Prerequisites

Access to the standards source and the audited artifacts. For orchestrator mode: subagent spawning capability. Load `.pr-reviewer.yaml` and iterate `context.standards.catalog` (filter by `triggers` when `enforce: triggered`).

## Task

Audit the design target against all __applicable__ standards (triggered subset when configured) and emit findings in both Markdown (human) and SARIF (machine) formats.

## Workflow

__Orchestrator Mode (one target, multiple standards):__
1. Resolve standards list from `.pr-reviewer.yaml` catalog (triggered filter when `enforce: triggered` and changed paths are known)
2. Spawn one subagent per standard using mcp_task (generalPurpose subagent type)
3. Each subagent audits the same target against one standard (Worker Instructions below)
4. Run all subagents in parallel
5. After subagents complete, merge Markdown reports and SARIF JSON
6. Write per-standard reports to `.reports/design-conformance-check-<standard-slug>-<target-slug>.md`
7. Merge SARIF runs into `.reports/design-conformance-check.sarif`
8. Produce consolidated conformance-violations report: `.reports/YYYYMMDD-HHMMSS-conformance-violations-<target-slug>.md`

__Worker Mode (one target, one standard):__
1. Apply standard to the target artifacts
2. Identify gaps: missing files, missing sections, standard violations, requirement-catalog gaps
3. Emit Markdown report and SARIF JSON (fenced code blocks, not files, for orchestrator extraction)

## Instructions

__Orchestrator Mode:__
- When given one target and multiple standards, do not audit directly; spawn subagents
- Use mcp_task tool with subagent_type=generalPurpose for each standard
- Pass to each subagent: (1) Worker Instructions, (2) --- Standard: <path> ---, (3) --- Target: <path> ---, (4) artifact_prefix directive
- Instruct subagents: output to `.reports/` only (not conformance/ folder); emit both Markdown and SARIF fenced code blocks
- Run subagents concurrently (multiple mcp_task calls in parallel)
- After completion: extract and merge outputs, write consolidated report with timestamp

__Worker Mode:__
- Read standard file (apply all rules)
- Scan the target artifacts for violations
- Identify requirement-catalog gaps (standards mandate something not in the target's requirements)
- Emit Markdown report (executive summary, findings grouped by category, severity, remediation)
- Emit SARIF 2.1.0 JSON (valid schema; `helpUri` belongs on `tool.driver.rules[]` reporting descriptors, not on `results[]`)
- All artifact URIs must be repository-root-relative paths from the repo root; prepend `artifact_prefix` only when it is not empty, never double-prefix
- Do not write files directly; emit fenced code blocks for extraction

__Standards summary for PR closeout:__
- Record verdict: `conformant`, `non-conformant` (with finding ids), `not applicable` (triggered but no in-scope artifacts — use ℹ️ in closeout rollup), or omit when not triggered.
- Emit a short `__Standards:__` bullet list for the pr-reviewer review body (one triggered standard per line; icon on the left; no blank lines between items). Full evidence stays in `.reports/`.

```markdown
__Standards:__
- ✅ design-dives.md
- ☑️ failure-modes.md
- 🔴 service-contracts.md (dc-2)
```

## Constraints

All output goes to `.reports/` only (no conformance/ folder). SARIF artifact and location URIs must use repository-root-relative paths with artifact_prefix prefix. Every SARIF result must have ruleId, level, message.text, locations, and optionally helpUri. Standards in `.pr-reviewer.yaml` `context.standards.catalog` take precedence over requirements that the target documents. Requirement-catalog gaps (standards mandate X but the target's requirements don't enumerate it) must be flagged as violations.

## Standards

- `.pr-reviewer.yaml` (canonical `context.standards.catalog`)
- The standards source (every standard that the run audits)
- https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json (SARIF 2.1.0 schema)

## Output Format

__Per-Standard Report (Markdown):__ `.reports/design-conformance-check-<standard-slug>-<target-slug>.md`
- Title: "Conformance: {standard-path} vs {target-path}"
- Executive summary: pass/fail, finding count
- Findings: grouped by rule/file, include severity and remediation
- References to standard sections

__SARIF JSON:__ `.reports/design-conformance-check.sarif` (merged from all subagents)
- Valid SARIF 2.1.0 schema
- One run per standard (merged into single file)
- Tool: design-conformance-agent v1.0.0
- Artifacts: all scanned files with repository-root-relative URIs (with artifact_prefix)
- Results: ruleId, level (error/warning/note), message.text, locations, helpUri

__Consolidated Report:__ `.reports/YYYYMMDD-HHMMSS-conformance-violations-<target-slug>.md`
- Title and audit scope
- Executive summary: pass/fail, counts by severity, __standards checked__ table or list
- Findings: grouped by category (location norm violations, missing mandatory files, gaps, AGENTS violations, domain-model gaps, requirement-catalog gaps)
- Each finding: ID, severity, finding, remediation, standard reference
- Cross-references to standards and audited artifacts

## Validation

SARIF must be valid 2.1.0 JSON. All artifact URIs must resolve from repository root (with artifact_prefix). Every result must have required fields. Markdown reports must have sections and findings. Consolidated report must merge all per-standard findings.

## Clarifying Questions

Ask if: The target path is ambiguous; the standards list is not provided and `.pr-reviewer.yaml` lists none (audit every file in the standards source?); artifact_prefix unclear (infer from input path?).

## Examples

__Input (Orchestrator):__ target=openspec/changes/add-refunds, changed_paths=[openspec/changes/add-refunds/design.md], enforce=triggered, artifact_prefix=''

__Output:__ Subagents spawn for triggered standards only. Markdown reports written to `.reports/`, SARIF merged, consolidated report includes standards rollup.

__Input (Worker):__ target=openspec/specs/billing, the standard failure-modes.md from the standards source, artifact_prefix=''

__Output:__ Two fenced code blocks: Markdown report and SARIF JSON (orchestrator extracts and merges)

## References

- `.pr-reviewer.yaml`
- The standards source
- `AGENTS.md` of the repo, when it has one

## Non-Goals

Do not fix violations; only identify them. Do not suggest new standards; audit against existing catalog entries. Do not modify the target artifacts during audit.

## Appendices
  SARIF Example Structure:
  ```json
  {
    "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
    "version": "2.1.0",
    "runs": [{
      "tool": { "driver": {
        "name": "design-conformance-agent",
        "version": "1.0.0",
        "rules": [{
          "id": "requirement-catalog-gap",
          "helpUri": "https://github.com/<owner>/<repo>/blob/<branch>/standards/<standard>.md#<section>"
        }]
      } },
      "artifacts": [
        { "location": { "uri": "openspec/changes/add-refunds/design.md" } }
      ],
      "results": [
        {
          "ruleId": "requirement-catalog-gap",
          "level": "error",
          "message": { "text": "Standard mandates ETag checks but requirement catalog does not enumerate this behavior" },
          "locations": [
            { "physicalLocation": { "artifactLocation": { "uri": "openspec/changes/add-refunds/specs/refunds/spec.md" }, "region": { "startLine": 42 } } }
          ]
        }
      ]
    }]
  }
  ```

  Artifact URI Handling:
  - Audited tree is the repo root: use the path from the repo root, for example `openspec/specs/billing/spec.md` (artifact_prefix is empty)
  - Audited tree sits below the repo root: use the prefix that the caller gives, for example `docs/design/` (artifact_prefix='docs/design/')
  - Always use the exact prefix provided; do not strip or alter paths

  Standards Precedence:
  - `.pr-reviewer.yaml` → `context.standards.catalog` (highest priority)
  - A conformance-report standard in the standards source, when it has one (secondary)
  - The standards section of the repo's README (fallback)

  Requirement-Catalog Gaps:
  - If standards mandate behavior but the target's requirements don't enumerate it, flag as violation
  - Example: Standard requires idempotency key but the operations spec doesn't specify it → gap violation
