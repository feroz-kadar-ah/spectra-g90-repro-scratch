---
name: spectra-pr-feedback-fixer
---

# PR Feedback Fixer

## Persona

Software engineer reviewing PR feedback from CodeRabbit, human reviewers, and CI systems. Systematic, traceability-focused. Triages issues, consults design docs for architecture threads, and addresses feedback with clear resolution tracking.

## Purpose

Fetch PR feedback, triage by severity and source, fix or reply with traceability. Emit auditable output with triple markers (source, severity, resolution) and ledger lines. Integrate design docs for architecture decisions.

## Context

Pull requests receive automated (CodeRabbit, CI), human (peers), and design-driven (architecture) feedback. Responses must be traceable, grounded in design docs when appropriate, and systematically tracked.

## Inputs

- PR ID/URL (e.g., `pr/42`, `https://github.com/owner/repo/pull/42`)
- Owner/repo (inferred from URL or explicit)
- Optional: existing comment URL (for in-place PATCH)
- Optional: mode flag (`loop` for self-healing cycle; default is review-only)

## Prerequisites

- GitHub access (MCP or `gh` CLI)
- PR details, diff, and comments fetchable
- Optional: `caffeinate -t 3600` (macOS, for loop mode)
- Optional: access to any wiki that the repo's design docs link (for example an MCP server)

## Task

Fetch PR feedback, triage, consult design docs, address threads, track resolutions, emit ledger with triple markers.

## Repo values

Read these when the skill starts. Do not store them in a file or a config key.

- Repo: `git remote get-url origin` gives `<host>/<owner>/<repo>`. Accept the `https`, `scp` and `ssh` forms, with or without `.git`. A PR URL overrides it. When the remote is missing or has another shape, use the argument `repo=<owner>/<repo>`; for the make file, set `GITHUB_HOST`, `GITHUB_OWNER` and `GITHUB_REPO` on the command line. When no source gives a value, say so and stop.
- Standards source: the argument `standards=<directory or URL prefix>`, or else the `standards/` directory at the repo root. Only the conformance and code-review steps need it. When one of those steps runs and no standards source exists, that step prints `No standards source found. Pass standards=<directory or URL prefix>.` and stops. The feedback work goes on without it. Never guess what a standard says.

## Makefile Targets, Tools

Systematic PR feedback resolution uses `.agents/skills/spectra/spectra-pr-feedback-fixer/pr-feedback-fixer.mk` for auditable discussion management:

- __pr-repo__: Print the owner and repo that the other targets use
- __extract-thread-id__: Extract numeric ID from GitHub discussion URL
- __mark-thread-resolved__: Mark a thread as resolved
- __batch-resolve-threads__: Bulk mark threads from file (one URL/ID per line)
- __reply-to-thread__: Reply to a specific discussion thread (nested reply)
- __pr-list-comments__: List all CodeRabbit comments with URLs
- __pr-list-reviews__: List all reviews with metadata
- __pr-feedback-report__: Generate report of all comments

Usage: `make -f .agents/skills/spectra/spectra-pr-feedback-fixer/pr-feedback-fixer.mk <target> PR_ID=525 [options]`

The make file reads the owner and repo from `git remote get-url origin`. Run `pr-repo` first to see them. For a remote that it cannot read, add `GITHUB_HOST=<host> GITHUB_OWNER=<owner> GITHUB_REPO=<repo>`. Run the `pr-help` target for examples and for the integration workflow.

## Instructions

The prompt files of the other shards sit in `.agents/skills/spectra/`: `spectra-pr-review/check-conformance.prompt.md` and `spectra-pr-code-review/code-review.prompt.md`. Load them by path.

### Step 1: Fetch PR Details

Use GitHub MCP or `gh` CLI:
- `gh pr view <pr-id>` — details
- `gh pr diff <pr-id>` — diff
- `gh pr view <pr-id> --json comments` — comments

Capture: base branch, head branch, title, body, all comment threads (inline + summary), bot feedback (CodeRabbit).

### Step 2: Consult Design Artifacts

When feedback touches contracts, domain rules, or architecture:

1. Resolve the capability or change from the PR paths, the title, or ask.
2. Read (scope to affected threads):
   - `openspec/specs/<capability>/spec.md` (durable behavior)
   - `openspec/changes/<change>/{proposal,design,tasks}.md` and its delta specs (the change in flight)
   - The design files that the `AGENTS.md` read order names, and the glossary (`docs/glossary.md`)
   - The recent entries of the changelog, when the repo has one
3. Read from the local checkout; when a file is not local, read it from `https://<host>/<owner>/<repo>/blob/<branch>/<path>`.
4. When the repo has none of these, say so and go on without this step.

### Step 3: Triage Feedback

Order by priority:

1. CodeRabbit Critical/Major (correctness-blocking)
2. Human "why" / design probes (may require architecture input)
3. Heavy human architecture/requirements
4. Style nits (prefer reply over churn)

For each thread:

- Identify severity (critical, major, minor, nit)
- Identify source (CodeRabbit 🐰, human 🧑‍🎄, CI 🤖)
- Check design docs for architecture/contract questions
- Determine resolution (fix, reply, defer, partial/follow-up)

### Step 4: Per-Comment Record, Required

Create one block per thread (inline, summary, or mapped issue comment):

1. __Thread ID__: pattern `<source>-<severity>-<n>` (e.g., `A-C-2` = CodeRabbit Critical #2)
2. __Permalink__: GitHub URL from comment
3. __Markers__: triple prefix (e.g., `🐰 🔴 ✅`)
4. __Problem__: short summary
5. __Steps__: numbered action items
6. __Reply__: thread reply or reasoning

Then emit ledger line: `<source> <severity> <resolution> <permalink> — <one-line summary>`

### Step 5: Address Threads

#### Default mode, no commit/push:
- Fix code or docs inline
- Reply on PR when useful using makefile targets:
  - `make -f .agents/skills/spectra/spectra-pr-feedback-fixer/pr-feedback-fixer.mk reply-to-thread PR_ID=<id> THREAD_ID=<id> REPLY_BODY='...'` — nested reply to discussion
  - `make -f .agents/skills/spectra/spectra-pr-feedback-fixer/pr-feedback-fixer.mk mark-thread-resolved PR_ID=<id> THREAD_ID=<id>` — mark thread resolved
- Update per-comment records + ledger

#### Loop mode, push + re-fetch:
- Follow the normative [loop protocol](#loop-protocol). Each iteration delegates its rebase, protected push, report, and re-fetch ordering to the [canonical post-feedback rebase phase](#canonical-post-feedback-rebase-phase).

#### Canonical post-feedback rebase phase

This phase applies only to __loop mode__. The default review-only mode retains its existing local-edit and PR-reply behavior but performs no commit, push, or history rewrite.

Run this phase immediately after every normal feedback-fix push and before waiting, re-fetching feedback, or making the next loop decision:

0. Require a clean working tree (`git status --porcelain` empty) before step 1. Stash or commit any local edits first; do not start the phase with uncommitted tracked changes.
1. Record `feedback_fix_sha="$(git rev-parse HEAD)"`. Resolve the PR head remote from PR metadata (`gh pr view … --json headRepository,headRefName,baseRepository`); when `headRepository` differs from the checkout’s default remote, use that repository URL for head queries and pushes — do not assume `origin` is the head fork. Query the remote PR head directly, for example with `git ls-remote "${head_remote}" "refs/heads/${head_branch}"`, and require the observed full SHA to equal `feedback_fix_sha`. Merely proving that the remote contains the feedback commit is insufficient. Do not infer remote state from local `HEAD` or a stale remote-tracking ref.
2. If the observed remote SHA differs from `feedback_fix_sha`, do not begin the base rebase:
   1. Fetch that exact remote PR head and enumerate every concurrent commit and affected behavior.
   2. Reconcile all remote commits intentionally with the feedback fixes. The reconciled local head must preserve the complete observed remote head as an ancestor; never create a lease-valid rewrite that deletes an unintegrated remote commit.
   3. Re-run feedback-fix and concurrent-behavior verification.
   4. Normally push the reconciled feedback head only when it is fast-forward-safe relative to the directly observed remote head. Do not use a force option.
   5. Query the remote directly again and require its SHA to equal the reconciled local feedback head. Repeat intentional reconciliation if it moved again.
3. Only after exact equality is established, capture that full remote head SHA as `expected_remote_sha`. This is the lease expectation and the pre-rebase SHA.
4. Resolve the PR base repository from PR metadata (`baseRepository`, `headRepository`, and owner/name fields). When the base repository differs from the head checkout remote, fetch the base branch from the repository that owns the base ref and record that resolved base-remote identity in the report. For same-repository PRs, validate that `origin/${base_branch}` exists after `git fetch origin "${base_branch}"`, then capture `base_sha="$(git rev-parse "origin/${base_branch}")"`. Do not assume `origin` points at the base repository without validation.
5. Rebase the checked-out PR head onto the fetched base commit with `git rebase "origin/${base_branch}"` or the validated equivalent base ref when a non-`origin` base remote was required.
6. Resolve every conflict using the [conflict decision policy](#conflict-decision-policy). Preserve the already-pushed feedback fixes, reconciled concurrent commits, and prior session decisions.
7. Run executable verification that exercises the combined feedback-fix and rebased behavior. Inspect the resulting diff and history to confirm no feedback fix or concurrent change was lost.
   - If verification fails after step 5 completes and no rebase is active, stash or commit any tracked edits produced during verification before `git reset --hard "${expected_remote_sha}"`; never discard uncommitted tracked work silently. Then reset the checked-out branch to `expected_remote_sha`, do not push the unverified rebased candidate, update the session PR comment with a detailed-tier `### Rebase` blocker section, and stop the rebase phase with the remote unchanged.
8. Immediately before rewriting the remote, query its head again and confirm it still equals `expected_remote_sha`. Push only with an explicit SHA-bound lease equivalent to:

   ```sh
   git push --force-with-lease=refs/heads/${head_branch}:${expected_remote_sha} origin HEAD:${head_branch}
   ```

   Plain `--force`, plain `--force-with-lease`, and a lease protecting a different destination are prohibited.
9. Update the [session PR comment](#session-pr-comment) before re-fetching feedback or checks:
   - Append or replace the `### Rebase` section for this attempt using the [rebase report tier](#rebase-report-tier) that matches the outcome.
   - Publish exactly one top-level session comment for the entire skill invocation, or PATCH that same comment on later loop iterations. Never create a second top-level issue comment.
   - Search existing PR comments for the session marker `<!-- pr-feedback-fixer:session:v1 -->`. When found, PATCH that comment id with the updated body. When not found, create one new top-level comment containing the marker and the full session report skeleton (ledger, rebase, CodeRabbit reply-summary when applicable).
   - If the write fails or is uncertain, search again before retrying. At most two additional search-then-publish-or-patch cycles are permitted only when the session comment is still missing or unchanged. When publication remains unconfirmed after those cycles, record an explicit blocked outcome in the ledger and stop the rebase phase until an operator confirms or retries publication.
10. Only after the session comment is published or patched successfully, re-fetch PR feedback and required checks before deciding whether to continue the loop.

##### Conflict decision policy

For each non-trivial conflict, evaluate evidence in this priority order:

1. Governing specifications and repository rules
2. Current PR intent and feedback resolutions already pushed
3. Recent merged PRs affecting the same paths, symbols, or behavior
4. Commit history and blame context
5. Targeted tests, lint, builds, and domain-specific validation

For every ambiguous conflict, actually search recent merged PRs and repository history for each affected path and symbol before choosing or blocking a resolution. Search merged PR metadata and diffs plus `git log`, pickaxe or regex history, and blame as applicable. Cite each result used with a durable PR, commit, or blame link. If a search returns no relevant evidence, record the exact command or query and state that it returned no relevant result; absence of evidence must not be implied or omitted.

Resolve at the hunk or symbol level to produce a coherent combined result. Do not use blanket whole-side conflict resolution, including `checkout` or `restore` of `--ours` or `--theirs`, index stage 2 or 3 copies, `-X ours`, `-X theirs`, or manual replacement with an entire side, even as an experiment. A whole-side outcome is not a viable resolution alternative: reject it by inspection, do not edit or test a file as that outcome, and do not describe it as attempted by the fixer. Evidence supplied by another source about a whole-side outcome may be cited only as historical evidence, not reenacted. Never silently discard a feedback fix, concurrent change, or conflicting behavior.

If the evidence conflicts or verification cannot establish a safe resolution while the base rebase is active:

1. Confirm repository state reports an active rebase, then run `git rebase --abort`.
2. Do not make any rewritten-history push.
3. Query the actual remote PR head directly. Confirm and report whether the feedback-fix commit remains reachable from that remote state (remotely available). Do not require `feedback_fix_sha` to equal the current remote head when a concurrent push moved the branch after capture.
4. Record the blocker outcome in the session report `### Rebase` section (detailed tier) and update the [session PR comment](#session-pr-comment). Do not create a second top-level issue comment.
5. Stop the rebase phase and loop with the feedback progress intact.

If no rebase is active, do not run `git rebase --abort`; leave the remote unchanged and use the applicable post-rebase blocker path.

If the explicit lease push is rejected because the remote moved:

1. Never override the rejection and never retry with a weaker lease.
2. Fetch the new remote PR head and identify every concurrent commit or changed behavior.
3. Reconcile the verified rebased local candidate with that new head intentionally, preserving both the feedback fixes and concurrent changes. Apply the same evidence policy.
4. Capture the newly observed full remote head SHA as the new `expected_remote_sha`.
5. Re-run combined verification and the remote-equality check.
6. Retry only with the explicit SHA-bound lease for that newly captured SHA.
7. If reconciliation is ambiguous or unverifiable after the original rebase completed, leave the remote unchanged, keep the local candidate unpushed, stop, and select the blocker outcome for the report action in the next step. Do not run `git rebase --abort` when no rebase is active. Reserve `git rebase --abort` for a conflict while an active rebase is confirmed by repository state.
8. Update the session PR comment `### Rebase` section after the retry succeeds or reconciliation is blocked, then re-fetch only after a successful publish or patch.

##### Session PR comment

The entire skill invocation must produce __at most one visible__ top-level PR issue comment carrying `<!-- pr-feedback-fixer:session:v1 -->`. Inline review-thread replies and nested discussion replies do not count toward this cap. Prior session comments from the same login are minimized as outdated immediately after each successful create or PATCH.

The session comment is the feedback-fixer closeout report. It must begin with the marker `<!-- pr-feedback-fixer:session:v1 -->` on its own line, then use this shape:

```markdown
<!-- pr-feedback-fixer:session:v1 -->
## pr-feedback-fixer session — PR #{pr_number}

### Ledger
{triple-marker lines from Step 6}

### Rebase
{rebase report tier content for the latest attempt; replace or append per loop iteration}

### CodeRabbit thread replies
{Step 7 reply-summary when applicable; omit section when no CodeRabbit threads}
```

__Publication:__ create the comment once with `github__add_issue_comment` (preferred) or `gh pr comment`. On later loop iterations, PATCH the same comment (`github__update_issue_comment` or `gh api .../issues/comments/{id}`) with the updated body. Never add a second top-level issue comment for merge-decision, blocker, ledger, or reply-summary content.

__Hide prior session comments (non-fatal):__ immediately after create or PATCH succeeds, set `SESSION_COMMENT_ID` to the comment database id and run:

```bash
: "${GH_REPO:?GH_REPO is required}"
: "${GH_PR_NUMBER:?GH_PR_NUMBER is required}"
: "${GH_TOKEN:?GH_TOKEN is required}"
: "${SESSION_COMMENT_ID:?SESSION_COMMENT_ID is required}"

gh_run() { env -u GITHUB_TOKEN GH_TOKEN="$GH_TOKEN" gh "$@"; }
_session_marker='<!-- pr-feedback-fixer:session:v1 -->'
_owner="${GH_REPO%%/*}"
_repo="${GH_REPO#*/}"
_login="$(gh_run api user --jq '.login')"
_prior_minimized=0
_prior_failed=0
while IFS= read -r _node_id; do
  [ -n "$_node_id" ] || continue
  if gh_run api graphql \
    -f query='mutation($id:ID!){minimizeComment(input:{subjectId:$id,classifier:OUTDATED}){minimizedComment{isMinimized}}}' \
    -f id="$_node_id" >/dev/null 2>&1; then
    _prior_minimized=$((_prior_minimized + 1))
  else
    _prior_failed=$((_prior_failed + 1))
    echo "pr-feedback-fixer: warn — minimizeComment failed for ${_node_id}" >&2
  fi
done < <(
  gh_run api graphql \
    -f query='query($owner:String!,$name:String!,$number:Int!){repository(owner:$owner,name:$name){pullRequest(number:$number){comments(first:100){nodes{id databaseId author{login} isMinimized body}}}}}' \
    -f owner="$_owner" -f name="$_repo" -F number="$GH_PR_NUMBER" \
    | jq -r --arg keep "$SESSION_COMMENT_ID" --arg login "$_login" --arg marker "$_session_marker" \
      '.data.repository.pullRequest.comments.nodes[] | select(.author.login==$login) | select(.body|contains($marker)) | select((.databaseId|tostring)!=$keep) | select(.isMinimized|not) | .id'
)
echo "pr-feedback-fixer: minimized ${_prior_minimized} prior session comment(s); ${_prior_failed} failed (non-fatal)"
```

Failures must not block loop exit, ledger publication, or re-fetch.

For offline synthetic harness scenarios, show exactly one executable create or patch invocation with the full session body attached. Judges evaluate rebase and ledger fields only inside that single comment body.

##### Rebase report tier

Classify each rebase attempt before writing `### Rebase`:

- __Simple rebase__ — use when all are true: rebase completed without conflicted paths (or only trivial auto-resolved hunks with no evidence search), verification passed, protected lease push succeeded, no abort, and no lease rejection. Emit exactly one terse line (full SHAs, no abbreviation):

  `Rebase onto {base_branch} ({base_sha}): {pre_rebase_head_sha} → {result_head_sha}; lease OK; no conflicts.`

- __Detailed rebase__ — use for every other outcome (ambiguous or evidence-backed conflict resolution, abort, stale lease, blocked post-rebase verification, or lease reconciliation). The `### Rebase` section must contain:
  - PR base branch and full fetched base SHA
  - Full pre-rebase remote head SHA and full resulting PR head SHA, or `none` when the rebase was aborted before any remote rewrite; when post-rebase verification fails without push, resulting PR head SHA is the unchanged remote head (`expected_remote_sha`)
  - Conflicted paths and affected behavior, or `none`
  - Ambiguity and viable alternatives considered, or `none`
  - Selected decision and rationale
  - Supporting specification, commit, blame, and recent merged-PR evidence; for ambiguity, include the exact merged-PR and history searches and cite results or state that no relevant result was found
  - Feedback fixes explicitly preserved, with the feedback-fix commit SHA
  - Verification commands and concrete results
  - Push result, lease rejection and reconciliation if any, or blocker reason
  - Remaining uncertainty and next action

Do not abbreviate SHAs in either tier. A successful detailed report must follow the protected push and precede the next feedback/check fetch. A detailed blocker report for an active rebase conflict must state that `git rebase --abort` completed, no rebased history was pushed, and the earlier feedback-fix push remains remotely available. A detailed blocker after a completed rebase or lease rejection must state that no rebase was active to abort, the local candidate was not pushed, the remote remained unchanged, and the earlier feedback fixes remain remotely available.

#### Batch workflow for similar feedback:

```bash
# 1. Extract all threads
make -f .agents/skills/spectra/spectra-pr-feedback-fixer/pr-feedback-fixer.mk pr-list-comments PR_ID=525 > all-threads.txt

# 2. Reply to threads with same message (e.g., a standard clarification)
while read THREAD_URL; do
  THREAD_ID=$(make -f .agents/skills/spectra/spectra-pr-feedback-fixer/pr-feedback-fixer.mk extract-thread-id THREAD_URL="$THREAD_URL")
  make -f .agents/skills/spectra/spectra-pr-feedback-fixer/pr-feedback-fixer.mk reply-to-thread PR_ID=525 THREAD_ID=$THREAD_ID \
    REPLY_BODY='This follows the repo convention in AGENTS.md.'
done < all-threads.txt

# 3. Batch mark resolved
make -f .agents/skills/spectra/spectra-pr-feedback-fixer/pr-feedback-fixer.mk batch-resolve-threads PR_ID=525 RESOLVED_FILE=all-threads.txt
```

### Step 6: Output Summary

Format: per-comment records + full triple-marker ledger.

```
### A-C-2 — Nil Check Missing After Repo Call

- __Permalink__: https://github.com/owner/repo/pull/123#discussion_r987654321
- __Markers__: 🐰 🔴 ✅
- __Problem__: LoadConfig error ignored; nil deref downstream.
- __Steps__: 1) Trace call sites. 2) Return/wrap error. 3) Test error path.
- __Reply__: "Error propagated from Run; added TestRun_ConfigError."

---

🐰 🔴 ✅ https://github.com/owner/repo/pull/42#discussion_r111 — Propagated LoadConfig error; added TestRun_ConfigError.
🧑‍🎄 🟠 ⏭️ https://github.com/owner/repo/pull/42#discussion_r222 — Batching deferred to PROJ-789.
🤖 🟡 💬 https://github.com/owner/repo/pull/42#discussion_r333 — Replied: import style per AGENTS.md.
```

### Step 7: CodeRabbit thread replies, reply-summary — required

__Always__ fold this rollup into the [session PR comment](#session-pr-comment) `### CodeRabbit thread replies` section when __any__ CodeRabbit inline thread was triaged, fixed, or replied to in the session (including a single thread). Do not post it as a separate top-level issue comment.

Also emit per-thread blocks in the agent output (Step 6) for traceability. Place the reply-summary section __inside the single session comment body__ after `### Ledger` and `### Rebase`.

Use this shape every time (replace placeholders; do not omit sections):

```markdown
## CodeRabbit thread replies — PR #{pr_number}

{One short paragraph: how many inline CodeRabbit threads; whether each got a threaded GitHub reply and/or a code fix; cite commit SHA when fixes landed (e.g. `a102de9`).}

- **r{id}** — `{path or topic}` — {one-line fix or reply rationale}
- **r{id}** — `{path or topic}` — {one-line fix or reply rationale}

**Verification:** {github_login} reply present on all {N} root comment IDs.

### Ledger

🐰 {severity} {resolution} {permalink} — {one-liner}.
…
```

__Reply-summary list rules__:

- Each bullet starts with `**r{id}**` — the `discussion_r` numeric id (e.g. `r3306820456`) or full `#discussion_r…` suffix; one bullet per root CodeRabbit comment.
- backtick-quoted path or short topic after `—` (not the full comment body).
- one-line fix or reply rationale after the second `—`; keep under ~120 characters when possible.
- When multiple threads share the same fix pattern, you may use one bullet with range `**r{start}–r{end}**` — only when the fix is identical.
- The __Verification__ line must state the GitHub login used for threaded replies and that every listed root comment id has an author reply (or explain any exception).
- The __Ledger__ subsection under reply-summary repeats __every__ triple-marker ledger line from Step 6 (same permalinks and one-liners); do not drop threads that appear in the list.

__When no CodeRabbit threads exist__: skip Step 7 entirely; state in Step 6 that no inline CodeRabbit feedback was present.

### Final session report, multi-thread closeout

When closing a full PR feedback pass with __three or more__ addressed threads (or when an eval harness requests it), you may __also__ emit a compact closeout __instead of or after__ the reply-summary table:

1. `## Ledger` — one triple-marker line per thread (full `https://github.com/…#discussion_r…` permalinks).
2. `## Thread summaries` — UTF-8 box tree (`├─`, `└─`) listing thread ids and file/topic; __no__ markdown table in this section.

Do not replace Step 7 reply-summary with only the box tree unless the user explicitly asks for tree-only output.

## Workflow

For default (review-only):

```
Fetch PR → Triage feedback → Consult design docs
    └─ Per-comment record
    ├─ Address thread (fix or reply)
    └─ Emit ledger
```

For loop mode (self-healing):

Follow the normative [loop protocol](#loop-protocol). Its rebase step follows the [canonical post-feedback rebase phase](#canonical-post-feedback-rebase-phase), and its closeout uses the required per-thread records, reply-summary when applicable, and ledger.

## Constraints

- Default mode: no `git add` / `commit` / `push` / `stash`.
- Loop mode: git is allowed under the repo's commit convention (from `AGENTS.md` or `CONTRIBUTING.md`; when it states none, match `git log -10 --format=%s`). Feedback fixes use a normal push; the canonical post-feedback rebase uses only its explicit expected-SHA `--force-with-lease` push after verification. No other force-push is allowed. The entire skill invocation must publish __at most one__ top-level PR issue comment (session report); loop iterations PATCH that comment instead of adding another. Loop must iterate until merge-ready without regressing prior session fixes, ledger resolutions, or established decisions.
- Ledger lines must have triple markers (source + severity + resolution); no leading resolution alone.
- CodeRabbit Major/Critical always investigated for correctness.
- Design docs consulted for architecture/contract questions; not dismissed without checking.
- Per-comment records must include permalink and markers.

## Standards

The repo's own rules: `AGENTS.md`, `CONTRIBUTING.md` and the commit convention that they state. The conformance and code-review steps use the standards source (see Repo values).

## Output Format

__Per-comment block__:

```markdown
### {THREAD_ID} — {Concise Title}

- __Permalink__: {GitHub URL}
- __Markers__: {Triple markers}
- __Problem__: {Short summary}
- __Steps__: {Numbered actions}
- __Reply__: {Reasoning or response}
```

__Ledger lines__:

```text
{source} {severity} {resolution} {permalink} — {one-liner}
```

__CodeRabbit thread replies (reply-summary)__ — required when any CodeRabbit inline thread was addressed (see [Step 7](#step-7-coderabbit-thread-replies-reply-summary--required)):

```markdown
## CodeRabbit thread replies — PR #{n}

{intro paragraph}

- **r{id}** — `{path or topic}` — {one-line fix or reply rationale}
- **r{id}** — `{path or topic}` — {one-line fix or reply rationale}

**Verification:** {login} reply present on all {N} root comment IDs.

### Ledger

{repeat all triple-marker ledger lines}
```

## Validation

- All feedback threads captured (CodeRabbit, human, inline, summary).
- Each thread has per-comment record + ledger line.
- Triple markers present (source + severity + resolution; no resolution-only).
- When any CodeRabbit inline thread was addressed: reply-summary emitted ([Step 7](#step-7-coderabbit-thread-replies-reply-summary--required)) with list, verification line, and ledger repeat.
- Design docs consulted for architecture/contract threads.
- Loop mode: <= 5 iterations; early exit only when green, merge-ready, and no regression vs prior iterations in this conversation.
- Loop mode: feedback fixes verified, committed, and normally pushed before remote-head capture and base rebase.
- Loop mode: each rebase attempt either verifies and pushes with an explicit expected-SHA lease or aborts without rewriting remote history.
- Loop mode: one session PR comment (create once, PATCH on later iterations) with the rebase tier and ledger folded inside; simple conflict-free rebases use a one-line `### Rebase` entry; re-fetch only after that comment is published or patched.
- Commit format follows the repo's commit convention.

## Clarifying Questions

Ask if:
- PR ID ambiguous (which PR?).
- Owner/repo unclear (infer from URL or ask).
- Mode ambiguous (review-only or loop?).
- Design docs inaccessible (need Atlassian MCP auth or Confluence paste).

## Examples

__Input__: PR #42 on a billing service with CodeRabbit Critical (nil deref risk) and human comment (architecture question on domain model).

__Workflow__:
1. Fetch PR details and comments
2. Triage: CodeRabbit Critical → priority; Human Major → check design docs
3. Consult: `openspec/specs/billing/spec.md`
4. Per-comment records + ledger + replies
5. Fix code for critical nil check; reply to human with design context
6. Output: per-comment blocks + full ledger

## References

`AGENTS.md` of the repo, when it has one. [code-review.prompt.md](../spectra-pr-code-review/code-review.prompt.md) and [check-conformance.prompt.md](../spectra-pr-review/check-conformance.prompt.md).

## Non-Goals

Do not implement unrelated features or scope-creep fixes. Do not merge PRs or close issues (user controls). Loop mode may automatically perform only the canonical explicit expected-SHA `--force-with-lease` push; do not perform any other force-push. Do not skip design doc consultation for architecture threads.

## Appendices

### Marker Reference

__Feedback source__:

- 🤖 — Generic bot / CI
- 🐰 — CodeRabbit
- 🧑‍🎄 — Human reviewer

__Severity__ (rate the finding):

- 🔴 Critical — crash, security, data loss, broken contract, blocker
- 🟠 Major — wrong behavior, heavy debt, failing required check
- 🟡 Minor — localized fix, edge test, correctness-adjacent
- 🔵 Nit — style/name/format

__Resolution__:

- ✅ Fixed in code/docs on branch
- ❌ Not fixed—blocked or still failing verification
- ⏭️ Deferred (reason in one-liner)
- 💬 Reply only (reasoning in one-liner)
- 🔄 Fix pushed; wait for bot/CI (loop mode)
- ⚠️ Partial / follow-up ticket (gap in one-liner)

Example triple: `🐰 🔴 ✅`

### Per-Comment Record Template

```markdown
### {THREAD_ID} — {Title}

- __Permalink__: {URL}
- __Markers__: {Triple}
- __Problem__: {Short}
- __Steps__: 1) X. 2) Y. 3) Z.
- __Reply__: {Reasoning or "none" + why}
```

### Loop Protocol, Self-Healing Cycle

See the normative [loop protocol](#loop-protocol) for iteration, convergence, and no-regression requirements. The [canonical post-feedback rebase phase](#canonical-post-feedback-rebase-phase) defines the protected rebase and report ordering used by each iteration.

Final output remains one per-comment record per thread, the updated ledger, and the required summary.

### Thread id

__Pattern__ `<source>-<severity>-<n>`: __source__ `A` = bot (ledger: 🤖 or 🐰—use 🐰 for CodeRabbit), `H` = human (🧑‍🎄); __severity__ `C`/`M`/`m`/`N` = critical/major/minor/nit; __n__ = ordinal within `(source, severity)`. Example: __`A-C-2`__ — __Nil deref risk__.

### Fields

1. __Permalink__ (required when API provides it).
2. __Markers__: triple prefix + id if useful (e.g. `🐰 🔴 ✅ A-C-2`).
3. __Problem__ (short).
4. __Steps__ (numbered; deferrals: reason + follow-up).
5. __Reply__ (thread response or "none" + why).

Then emit a [ledger line](#systematic-comment-tracking-required).

### Sample preamble

```markdown
### __A-C-2__ — __Nil check missing after repo call__

- __Permalink__: https://github.com/owner/repo/pull/123#discussion_r987654321
- __Markers__: `🐰` `🔴` `✅` · `A-C-2`
- __Problem__: `LoadConfig` error ignored; nil deref downstream.
- __Steps__: 1) Trace call sites. 2) Return/wrap error. 3) Test error path.
- __Reply__: "Propagated error from `Run`; added `TestRun_ConfigError` for verification."
```

## Marker reference

Prefix every ledger line and concise summary: __source → severity → resolution__ (space-separated, fixed order).

### Feedback source

- __🤖__ — Generic bot / automation (not CodeRabbit).
- __🐰__ — CodeRabbit.
- __🧑‍🎄__ — Human reviewer.

### Severity, rate the finding; human threads too

- __🔴__ Critical — crash, security, data loss, broken contract, blocker.
- __🟠__ Major — wrong behavior, heavy debt, failing required check.
- __🟡__ Minor — localized fix, edge test, correctness-adjacent.
- __🔵__ Nit — style/name/format (often reply-only).

### Resolution

- __✅__ Fixed in code/docs on branch.
- __❌__ Not fixed—blocked or still failing verification.
- __⏭️__ Deferred (reason in one-liner).
- __💬__ Reply only (reasoning in one-liner).
- __🔄__ Fix pushed; wait for bot/CI.
- __⚠️__ Partial / follow-up ticket (gap in one-liner).

Example prefix: `🐰 🔴 ✅`.

## Systematic comment tracking, required

Shape: `<source> <severity> <resolution> <permalink> — <one-line summary>`

### Sample ledger

```text
🐰 🔴 ✅ https://github.com/owner/repo/pull/42#discussion_r111 — Propagated `LoadConfig` error; added `TestRun_ConfigError`.
🧑‍🎄 🟠 ⏭️ https://github.com/owner/repo/pull/42#discussion_r222 — Batching deferred to PROJ-789.
🤖 🟡 💬 https://github.com/owner/repo/pull/42#discussion_r333 — Replied: import style per `AGENTS.md` / repo convention.
```

__Default__: one line per thread addressed. __Loop__: rolling ledger; update 🔄 → ✅/❌ after re-review.

## Feedback source strategy

### AI, CodeRabbit

- __Nature__: Rule-driven; style, bugs, best practices.
- __Response__:
  - __Minor/style__: Fix if clarity improves without scope creep.
  - __Correctness__: Always investigate.
  - __Architecture/design__: Evaluate against design docs, __`AGENTS.md`__, and [code-review.prompt.md](../spectra-pr-code-review/code-review.prompt.md); accept only if aligned with project intent.
  - __Performance__: Take if cheap; else defer.
  - __Tooling__: Skip if equivalent alternative exists in repo.
  - Accept → apply. Decline → short reply with rationale.

### Human

- __Nature__: Context, intent, trade-offs.
- __Response__: Answer questions; validate design concerns against docs; take requirements seriously; investigate "why" on fields; discuss subjective points; resolve or give rationale + follow-up.

### Triage order

1. CodeRabbit Critical/Major.
2. Human "why" / design probes.
3. Heavy human architecture/requirements.
4. Style nits (prefer reply over churn).

## Prerequisites

PR id/URL + owner/repo (ask if unsure). GitHub access. Optional: `caffeinate -t 3600` (macOS).

## Repo inference for `gh` CLI

`gh` uses the `origin` remote of the checkout. For a PR in another repo, pass `--repo`:

```sh
gh pr view 282 --repo <owner>/<repo>
gh pr diff 282 --repo <owner>/<repo>
```

When the checkout is the PR repo, `--repo` is optional.

## Workflow, default and loop

### CodeRabbit inline

- Triage __Major__ / __Critical__ first.
- Use __Prompt for AI Agents__ as spec when present.

1. Fetch PR (details, diff, files, comments).
2. Address threads: consult the [design artifacts](#step-2-consult-design-artifacts) when behavior/contracts matter; [per-comment record](#per-comment-record-required) + [ledger](#systematic-comment-tracking-required).
3. Apply `.coderabbit.yaml` `path_instructions` when the repo has that file; self-review rules.
4. Output: [code-review.prompt.md](../spectra-pr-code-review/code-review.prompt.md) / [check-conformance.prompt.md](../spectra-pr-review/check-conformance.prompt.md) as applicable.
5. __Default__: no git write.
6. Reply on PR when useful (__loop__: after push too).

### Loop protocol

When mode is __loop__ (`/pr-feedback-fixer loop`), work __iteratively__ in the same agent conversation until the PR is __green and merge-ready__:

- Required GitHub checks passing
- No open CodeRabbit Critical/Major threads (address or reply with fix commit)
- Ledger reconciled each pass (🔄 → ✅/❌)
- Human and prior-bot threads closed or explicitly deferred with rationale in the ledger

__No regression across iterations.__ Before each push, re-read the session ledger and prior fixes. New changes must not revert, narrow, or contradict earlier resolutions, design-doc conclusions, user directives, or replies already posted on the PR. If a new comment conflicts with a settled decision, reconcile in the ledger (reply or escalate) instead of silently rolling back.

At most __5__ iterations; follow the [canonical post-feedback rebase phase](#canonical-post-feedback-rebase-phase) after each normal feedback-fix push, then wait ~__10__ min after its successful protected push and session-comment update. Re-fetch PR feedback and CI only after the session comment is published or patched; fix only __new__ failures and regressions you introduced; update ledger. __Early exit__ only when merge-ready criteria above hold. End with the single session PR comment containing ledger, rebase tier, and reply-summary when applicable. Outside the canonical explicit expected-SHA lease push, force-push is prohibited. Never change labels or modify CI.

__Quick ref — default vs loop__

Default mode performs no git write. Loop mode follows the normative [loop protocol](#loop-protocol), whose rebase step is the [canonical post-feedback rebase phase](#canonical-post-feedback-rebase-phase). Both modes retain per-thread records and the triple-marker ledger.

## Related, Sonar-only CI

This skill handles GitHub review threads and CI feedback. It does not fix SonarCloud quality gate findings. When the user's goal is a Sonar quality gate, Sonar issues or coverage on new code, say so and ask for a Sonar-specific skill.
