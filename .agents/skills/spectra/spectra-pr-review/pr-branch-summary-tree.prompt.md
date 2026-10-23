---
name: spectra-pr-branch-summary-tree
---

---
persona: |
  Code reviewer or tooling agent tasked with producing a canonical, tree-formatted summary of changed files between two git refs. Accurate on critical touches, concise on purposes.

purpose: |
  Produce one canonical markdown artifact (`.reports/pr-branch-summary-tree.md`) listing every changed path between a base ref (typically `origin/main`) and head ref (`HEAD` or PR tip), each with one short purpose line, in tree form only (no markdown tables).

context: |
  Pull requests span multiple files and layers (domain, application, adapters, proto, config). Reviewers need a clear, hierarchical inventory of what changed and why it matters. Tree format provides visual hierarchy; purpose lines provide context without verbose descriptions.

inputs: |
  Work from the repository root that owns the comparison (service repo unless user specifies otherwise).

  - __Base ref__: default `origin/<default branch>`, where `git symbolic-ref --short refs/remotes/origin/HEAD` gives `origin/<default branch>`; __head ref__: default `HEAD` or explicit PR SHA.
  - __Repo name__: must be stated in report header.

prerequisites: |
  - Git access to the repository; able to run `git diff --name-status -M <base> <head>`.
  - Optional: `git log`, `git diff --stat` for inferring purposes from commit messages and content changes.

task: |
  Enumerate all changed paths with one-line purpose each, format as UTF-8 tree inside fenced block, write to `.reports/pr-branch-summary-tree.md`.

instructions: |
  ### Step 1: Enumerate Changed Paths

  Run: `git diff --name-status -M <base> <head>` from repo root (e.g., `git diff --name-status -M origin/main HEAD`).

  Output format per line:
  - `A <path>` (added)
  - `D <path>` (deleted)
  - `M <path>` (modified)
  - `R95 <old> <new>` (renamed; leading similarity score may vary)

  Must omit no path unless user narrows scope; prefer `--name-status -M` over `--name-only` when reviewers need explicit rename old→new pairing.

  ### Step 2: Infer Purposes

  For each changed path, infer accurate one-line purpose using:
  - File path pattern (e.g., `api/proto/` → protobuf change)
  - Selective file reads (first 10–20 lines for context, or git log message for file)
  - `git diff --stat` to understand magnitude
  - Commit messages in the PR

  Focus accuracy on critical touches: protos, URNs, domain helpers, services in blast radius.

  ### Step 3: Format as Tree

  Inside one fenced block, use __only__ these box glyphs: `─` `│` `├` `└` (keep one style throughout).

  Structure:

  ```
  <layer>
  ├─ <path>
  │  Purpose: <one-line description>
  ├─ <path>
  │  Purpose: <one-line description>
  └─ <path> [REMOVED]
     Purpose: <reason for removal>
  ```

  Removed paths should be annotated when useful (e.g. `[REMOVED]` on the tree line).

  ### Step 4: Optional Rollup

  At end, optional synthetic node `_rollup_for_reviewers_` grouping by layer (API, domain, application, adapters, smoke, tooling).

  ### Step 5: Write to Output

  Create or overwrite `.reports/pr-branch-summary-tree.md` (create `.reports/` if missing).

workflow: |
  Parse base/head refs
      └─ Enumerate paths: git diff --name-status -M
          └─ Infer purposes from file content & commit messages
              └─ Format as UTF-8 tree
                  └─ Write to .reports/pr-branch-summary-tree.md

constraints: |
  - Tree-only format: no markdown tables as primary list.
  - One purpose line per path (concise, one sentence).
  - All changed paths included (no omissions except user-specified exclusion).
  - `.reports/pr-branch-summary-tree.md` is working-copy only; never commit unless user explicitly requests repo policy exception.
  - Tree indentation must be clean (consistent glyphs).
  - Optional generated churn tagging (e.g. `api/pkg/go/**` from buf, submodule-only commits) still listed unless user excludes.

standards: |
  - `AGENTS.md` of the repo, when it states a rule for lists or trees. This prompt applies no other standard.

output_format: |
  __Header__: Report title, base ref, head ref, repo name, optional date.

  __Fenced tree block__:

  ```
  ── <layer or root>
  ├── <path>
  │   <one-line purpose>
  ├── <path> [REMOVED]
  │   <reason>
  └── <path>
      <one-line purpose>

  (optional rollup section)
  ```

validation: |
  - All changed paths listed (no omissions except user-specified).
  - Each path has one short purpose line.
  - Tree glyphs consistent throughout (no mixing `├──` with `├─`).
  - Tree indentation clean and readable.
  - No markdown tables in primary list.
  - Report written to `.reports/pr-branch-summary-tree.md`.

clarifying_questions: |
  Ask if:
  - Base or head ref ambiguous (which branch? which SHA?).
  - Scope narrowing requested (exclude certain path patterns?).
  - GitHub publication desired (existing comment URL for PATCH vs new comment).

examples: |
  __Input__: PR on an orders service comparing `origin/main` to `HEAD` with 8 changed files.

  __Workflow__:
  1. Run `git diff --name-status -M origin/main HEAD`
  2. Infer purposes from file paths and commit messages
  3. Format as tree with sections: API (proto changes), Domain, Application, Adapters, Smoke, Config
  4. Write to `.reports/pr-branch-summary-tree.md`

  __Output snippet__:

  ```
  ── API
  ├── api/proto/orders/v1/orders.proto
  │   Add new `status` enum value ORDER_STATUS_SHIPPED
  ├── api/proto/common/v1/error.proto
  │   Update error metadata version
  ── Domain
  ├── internal/domain/orders/entities.go
  │   Refactor order status validation logic
  ── Application
  ├── internal/application/orders/service.go
  │   Implement new GetOrderStatus operation
  ── Adapters
  ├── internal/adapters/orders/persistence/ddb/orders_repo.go
  │   Add conditional ETag check on update
  ├── internal/adapters/transport/grpc/orders_handler.go
  │   Wire GetOrderStatus RPC
  ── Smoke
  ├── test/smoke/payloads/orders_create.yaml
  │   Update fixture with new status field
  ```

references: |
  - `AGENTS.md` of the repo (tree format guidance), when it has one

non_goals: |
  Do not analyze code semantics or correctness. Do not generate detailed diff reviews. Do not commit the report file (working-copy only). Do not rewrite the report as a table format.

appendices: |
  ### Optional: GitHub PR Comment Publication

  When user provides existing comment URL (`.../pull/N#issuecomment-ID`):

  1. PATCH that comment in place: `gh api -X PATCH repos/{owner}/{repo}/issues/comments/{id} -f body='{full report body}'`
  2. Do not create a new comment (no duplication).

  After new commits land on same PR:

  1. Regenerate tree from same base/head rules.
  2. Re-PATCH the same comment (same `comment-id`) for one living thread.

  For new comments (no existing URL):

  1. Create PR comment: `gh pr comment <pr-number> --body '{full report body}'`
  2. Do not tell reviewers to pull from `.reports/` file (must not be committed).
---