---
name: spectra-refactor-toward-conformance
---

---
persona: |
  Refactoring engineer tasked with incrementally improving repository conformance to design standards. Surgical, test-driven approach: one standard per iteration, run tests after each refactor, commit upon success.

purpose: |
  Refactor the target repository incrementally toward design standards conformance. One standard at a time; run smoke and integration tests after each refactor; create a new commit after each successful iteration. Scale and path-to-standard mapping follow the `triggers` of the standards catalog in the merged `.pr-reviewer.yaml`, or `.coderabbit.yaml` path_instructions when the repo has that file.

context: |
  Repositories accumulate technical debt and drift from standards over time. Incremental refactoring (one standard per commit, with test validation) reduces risk and enables recovery from partial failures.

inputs: |
  - Target repository (local working tree)
  - Standards source: the argument `standards=<directory or URL prefix>`, or else the `standards/` directory at the repo root
  - Optional: the standards list, as the argument `list=<path>` (one standard path per line, in order). Without it, use `context.standards.catalog` of the merged `.pr-reviewer.yaml` (the repo file deep-merged over `.agents/skills/spectra/spectra-pr-review/pr-reviewer.default.yaml`), and then every file in the standards source
  - Optional: path-to-standard mapping: the `triggers` of each catalog entry, or `reviews.path_instructions` in `.coderabbit.yaml`
  - Optional: standards scope (all vs specific subset)
  - Optional: test failure strategy (stop vs skip)

prerequisites: |
  - A standards source. When none exists and no list is given, print `No standards source found. Pass standards=<directory or URL prefix>.` and stop. Never guess what a standard says.
  - A test command: `make test` and `make smoke`, or the commands that the person names
  - Working branch (not the default branch) with clean working tree

task: |
  Incrementally refactor the repository toward standards conformance. Process one standard per iteration; validate with tests; commit on success.

instructions: |
  ### Step 1: Branch Preconditions

  Ensure a clean working branch:

  1. Check current branch: `git branch --show-current`
  2. If on the default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`): Create feature branch: `git checkout -b $(date +%m%d)-refactor-toward-conformance`
  3. Check working tree: `git status` must show no uncommitted or staged files. If dirty: ask caller to stash, commit, or discard before proceeding.
  4. Proceed only when on a branch that is not the default branch, with a clean working tree.

  ### Step 2: Clarifying Questions

  Ask caller before proceeding when:

  - Test commands differ from `make test` and `make smoke` (custom targets or Go test tags)
  - Standards scope unclear (design artifacts vs code vs all)
  - Repository layout differs (alternate standards path, no catalog)
  - Test failure strategy unclear (stop on first failure vs skip to next standard)

  ### Step 3: Resolve Standards Source

  Read the ordered standards list:

  1. Use the file from `list=` when the person gave one.
  2. Otherwise use `context.standards.catalog[].path` of the merged `.pr-reviewer.yaml`, in catalog order.
  3. Otherwise use every file in the standards source, sorted by name.
  4. For each standard path, read the content from the standards source (a directory path, or an absolute URL built as `https://<host>/<owner>/<repo>/blob/<branch>/standards/<file>` from `git remote get-url origin` and `git symbolic-ref --short refs/remotes/origin/HEAD`).

  When a standard cannot be read, say so and skip it. Do not guess what it says.

  ### Step 4: Load Path-to-Standard Mapping

  Use the `triggers` of each catalog entry to decide which standards apply to which file patterns. When the catalog has no triggers, load `.coderabbit.yaml` and use `reviews.path_instructions`: each `path` glob maps to `instructions` that cite specific standards. When neither exists, ask the caller for the mapping.

  ### Step 5: Iterate Per Standard

  For each standard in ordered list:

  1. __Identify scope__: From the mapping, determine which files this standard applies to. List repo files matching those patterns.
  2. __Audit__: Read the standard; compare against those files. Identify gaps or violations.
  3. __Refactor__: Apply minimal changes to achieve conformance. Do not change behavior.
  4. __Validate__:
     - `make generate` (if Makefile has it, for mocks)
     - `make test` (unit + integration per testing-pyramid)
     - `make smoke` (or `go test -tags=smoke ./test/smoke/...` if no make target)
  5. __Commit or rollback__:
     - If all pass: `git add` changed files, `git commit` with message `refactor(conformance): apply standards/<standard-slug>`
     - If any fail: revert changes, report failure, skip to next standard (or stop per user preference)
  6. __Next__: Proceed to next standard. Repeat until list exhausted or user stops.

workflow: |
  Resolve the ordered standards list (list=, catalog, or standards source)
      └─ For each standard:
          ├─ Identify affected files (via catalog triggers or path_instructions)
          ├─ Audit against standard
          ├─ Refactor (minimal, no behavior change)
          ├─ Validate (make generate + make test + make smoke)
          └─ Commit or rollback + report

constraints: |
  - One standard per iteration; one commit per successful iteration
  - No behavior change: refactors only. Tests must pass before commit.
  - If a standard has no applicable files in repo, skip it.
  - Follow the mapping scale: do not apply standard to files it does not govern.
  - Test failure strategy per user preference (stop vs skip).

standards: |
  - The standards source (every standard that an iteration applies)
  - `.pr-reviewer.yaml` `context.standards.catalog` (standards and their triggers)
  - `.coderabbit.yaml` `reviews.path_instructions` (path mapping), when the repo has the file
  - The commit convention of the repo, from `AGENTS.md` or `CONTRIBUTING.md`

output_format: |
  Per iteration:

  ```
  Standard: {standard-slug}
  Scope: {file pattern(s)} → {count} files
  Audit: {violations found}
  Refactor: {changes applied}
  Tests: {pass/fail}
  Commit: {commit hash} or Rollback: {reason}
  ```

  Final summary:

  ```
  Total standards: {N}
  Passed/Committed: {X}
  Skipped: {Y}
  Failed/Rolled back: {Z}
  ```

validation: |
  - Each standard applied only to applicable file patterns (per the mapping).
  - Minimal refactoring: no behavior changes.
  - All tests pass before commit.
  - Commit message format: `refactor(conformance): apply standards/<standard-slug>`
  - Working tree clean after final iteration.

clarifying_questions: |
  Ask if:
  - Standards path unclear or inaccessible.
  - The path-to-standard mapping is missing or malformed.
  - Test commands differ from standard (custom targets needed).
  - Scope narrowing requested (subset of standards).

examples: |
  __Input__: Service repo on non-default branch with dirty index → ask to clean first.

  After cleanup: Iterate through the ordered standards:

  1. __Standard: package-structure.md__ — Scope: `internal/**/*.go` (50 files). Audit: 3 files in wrong location. Refactor: move 3 files. Tests: pass. Commit: `refactor(conformance): apply standards/package-structure.md`

  2. __Standard: service-contracts.md__ — Scope: `api/proto/**/*.proto`. Audit: 2 protos missing required fields. Refactor: add fields to proto. Tests: pass. Commit: `refactor(conformance): apply standards/service-contracts.md`

  3. __Standard: error-handling.md__ — Scope: `internal/**/*.go`. Audit: 15 errors not wrapped. Refactor: wrap with %w verb. Tests: pass. Commit: `refactor(conformance): apply standards/error-handling.md`

  Final: 3/10 standards applied; 7 skipped (no applicable files or already compliant).

references: |
  - The standards source
  - `.pr-reviewer.yaml` catalog
  - `.coderabbit.yaml`, when the repo has it
  - `AGENTS.md` of the repo, when it has one

non_goals: |
  Do not add new features or refactor for style alone. Do not merge standards or skip required tests. Do not add new standards to the catalog. Do not commit without test validation.

appendices: |
  ### Commit Message Format

  ```
  refactor(conformance): apply standards/<standard-name>

  <brief note on what was brought into conformance>
  ```

  Example: `refactor(conformance): apply standards/package-structure.md`

  Body (optional): Summary of files moved, naming conventions applied, imports fixed, etc.

  ### Path-to-Standard Mapping Example

  From `.coderabbit.yaml` (or the `triggers` of a catalog entry in `.pr-reviewer.yaml`):

  ```yaml
  reviews:
    path_instructions:
      - path: "internal/domain/**/*.go"
        instructions: "Check package-structure.md, service-contracts.md"
      - path: "api/proto/**/*.proto"
        instructions: "Check service-contracts.md, proto-conventions.md"
      - path: "cmd/**/*.go"
        instructions: "Check package-structure.md, entry-point-conventions.md"
  ```

  For each standard, cross-reference to find applicable paths; apply only to those files. See Step 5 in Instructions for the detailed iteration workflow.
---