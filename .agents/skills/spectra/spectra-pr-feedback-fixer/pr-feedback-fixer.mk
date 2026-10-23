# pr-feedback-fixer.mk
# PR feedback review workflow — extract thread IDs, mark resolved, batch process CodeRabbit comments.
# Used by pr-feedback-fixer.prompt.md in this folder for systematic feedback triage.

MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
.DELETE_ON_ERROR:

# Variables
PR_REVIEW_DIR ?= $(CURDIR)
# Repo values come from the origin remote when make runs. Nothing is stored in a file.
# A remote that is not <host>/<owner>/<repo> (a local path, a nested group) gives no value.
# Set GITHUB_HOST, GITHUB_OWNER and GITHUB_REPO on the command line for a remote that make cannot read.
# gh reads the GH_HOST environment variable for a host other than github.com.
ORIGIN_URL := $(shell git remote get-url origin 2>/dev/null)
REMOTE_PARTS := $(subst /, ,$(shell printf '%s\n' '$(ORIGIN_URL)' | sed -E -e 's,/+$$,,' -e 's,\.git$$,,' -e 's,^[A-Za-z][A-Za-z0-9+.-]*://,,' -e 's,^[^/@]*@,,' -e 's,^([^/:]+):[0-9]+/,\1/,' -e 's,^([^/:]+):,\1/,' -e '/^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+\/[^\/]+\/[^\/]+$$/!d'))
GITHUB_HOST ?= $(word 1,$(REMOTE_PARTS))
GITHUB_OWNER ?= $(word 2,$(REMOTE_PARTS))
GITHUB_REPO ?= $(word 3,$(REMOTE_PARTS))
PR_ID ?=
THREAD_URL ?=
THREAD_ID ?=
REVIEW_ID ?=
COMMENT_ID ?=
RESOLVED_FILE ?= .reports/pr-$(PR_ID)-resolved-threads.txt
REPORT_FILE ?= .reports/pr-$(PR_ID)-feedback-report.txt
UNRESOLVED_FILE ?= .reports/pr-$(PR_ID)-unresolved-threads.txt

.PHONY: pr-help pr-repo _require-repo extract-thread-id mark-thread-resolved batch-resolve-threads pr-list-comments pr-list-reviews pr-feedback-report

# ─────────────────────────────────────────────────────────────────────────────
# Help
# ─────────────────────────────────────────────────────────────────────────────

pr-help: ## Display PR review makefile targets
	@echo "PR Review Workflow Targets"
	@echo "──────────────────────────"
	@echo ""
	@echo "Repo:"
	@echo "  make pr-repo                                                                 - Print the owner and repo that the targets use (from the origin remote)"
	@echo "  Set GITHUB_HOST=... GITHUB_OWNER=... GITHUB_REPO=... for a remote that make cannot read"
	@echo ""
	@echo "Thread Operations:"
	@echo "  make extract-thread-id THREAD_URL='https://github.com/...#discussion_r...'   - Extract numeric thread ID from discussion URL"
	@echo "  make mark-thread-resolved PR_ID=525 THREAD_ID=3306654520                     - Mark a thread as resolved"
	@echo "  make batch-resolve-threads PR_ID=525 RESOLVED_FILE='threads.txt'             - Mark all threads in file as resolved (one URL/ID per line)"
	@echo "  make reply-to-thread PR_ID=525 THREAD_ID=3306654520 REPLY_BODY='...'         - Reply to a specific discussion thread"
	@echo ""
	@echo "Discovery:"
	@echo "  make pr-list-comments PR_ID=525                                              - List all CodeRabbit inline comments with URLs"
	@echo "  make pr-list-reviews PR_ID=525                                               - List all reviews (with IDs) for a PR"
	@echo ""
	@echo "Reporting:"
	@echo "  make pr-feedback-report PR_ID=525                                            - Generate resolved/unresolved thread report"
	@echo ""
	@echo "Example workflow:"
	@echo "  1. make pr-list-comments PR_ID=525 > threads.txt"
	@echo "  2. Review feedback; reply to specific threads or mark resolved"
	@echo "  3. make reply-to-thread PR_ID=525 THREAD_ID=123 REPLY_BODY='...'            (nested reply)"
	@echo "  4. make batch-resolve-threads PR_ID=525 RESOLVED_FILE=threads.txt"
	@echo "  5. make pr-feedback-report PR_ID=525"
	@echo ""

# Print the repo values that the other targets use
pr-repo: _require-repo ## Print host/owner/repo from the origin remote (or the command-line values)
	@echo "$(GITHUB_HOST)/$(GITHUB_OWNER)/$(GITHUB_REPO)"

# Stop when no owner and repo are known. Never send a request to a guessed repo.
_require-repo:
	@if [ -z "$(GITHUB_HOST)" ] || [ -z "$(GITHUB_OWNER)" ] || [ -z "$(GITHUB_REPO)" ]; then \
		echo "ERROR: no owner and repo. The checkout has no readable origin remote." >&2; \
		echo "Set GITHUB_HOST, GITHUB_OWNER and GITHUB_REPO on the command line." >&2; \
		exit 1; \
	fi

# ─────────────────────────────────────────────────────────────────────────────
# Core Operations
# ─────────────────────────────────────────────────────────────────────────────

# Extract thread ID (discussion_r...) from a GitHub discussion URL
# Usage: make extract-thread-id THREAD_URL='https://github.com/<owner>/<repo>/pull/525#discussion_r3306654520'
extract-thread-id: ## Extract numeric thread ID from GitHub discussion URL
	@if [ -z "$(THREAD_URL)" ]; then \
		echo "ERROR: THREAD_URL not set. Usage: make extract-thread-id THREAD_URL='https://<host>/<owner>/<repo>/pull/525#discussion_r...'"; \
		exit 1; \
	fi
	@THREAD_URL="$(THREAD_URL)"; \
	if echo "$$THREAD_URL" | grep -qE '#discussion_r[0-9]+'; then \
		ID=$$(echo "$$THREAD_URL" | sed -E 's/.*#discussion_r([0-9]+).*/\1/'); \
		echo "$$ID"; \
	elif echo "$$THREAD_URL" | grep -qE '#discussion_r'; then \
		ID=$$(echo "$$THREAD_URL" | grep -oE 'discussion_r[0-9]+' | sed 's/discussion_r//'); \
		echo "$$ID"; \
	else \
		echo "ERROR: URL does not contain #discussion_r<ID> pattern: $$THREAD_URL"; \
		exit 1; \
	fi

# Mark a single CodeRabbit review comment thread as resolved
# Usage: make mark-thread-resolved PR_ID=525 THREAD_ID=3306654520 [REVIEW_ID=4367257072]
# Note: THREAD_ID is the discussion_r numeric ID from the URL; resolves via GraphQL
mark-thread-resolved: _require-repo ## Mark a CodeRabbit thread as resolved using GraphQL API
	if [ -z "$(PR_ID)" ] || [ -z "$(THREAD_ID)" ]; then
		echo "ERROR: PR_ID and THREAD_ID required."
		echo "Usage: make mark-thread-resolved PR_ID=525 THREAD_ID=3306654520"
		exit 1
	fi
	case "$(PR_ID)" in
		*[!0-9]*|'')
			echo "ERROR: PR_ID must be a positive integer (got: $(PR_ID))"
			exit 1
			;;
	esac
	case "$(THREAD_ID)" in
		*[!0-9]*|'')
			echo "ERROR: THREAD_ID must be a positive integer (got: $(THREAD_ID))"
			exit 1
			;;
	esac
	echo "Marking thread $(THREAD_ID) as resolved on PR $(PR_ID)..."
	THREAD_GLOBAL_ID=""
	after=""
	while [ -z "$$THREAD_GLOBAL_ID" ]; do
		if [ -n "$$after" ]; then
			THREAD_QUERY='query { repository(owner: "$(GITHUB_OWNER)", name: "$(GITHUB_REPO)") { pullRequest(number: $(PR_ID)) { reviewThreads(first: 100, after: "'"$$after"'") { pageInfo { hasNextPage endCursor } nodes { id isResolved comments(first: 100) { nodes { databaseId } } } } } } }'
		else
			THREAD_QUERY='query { repository(owner: "$(GITHUB_OWNER)", name: "$(GITHUB_REPO)") { pullRequest(number: $(PR_ID)) { reviewThreads(first: 100) { pageInfo { hasNextPage endCursor } nodes { id isResolved comments(first: 100) { nodes { databaseId } } } } } } }'
		fi
		THREAD_JSON=$$(gh api graphql -f query="$$THREAD_QUERY" 2>&1) || true
		THREAD_ROW=$$(echo "$$THREAD_JSON" | jq -c --argjson tid $(THREAD_ID) '[.data.repository.pullRequest.reviewThreads.nodes[] | select([.comments.nodes[].databaseId] | index($$tid))][0] // empty')
		THREAD_GLOBAL_ID=$$(echo "$$THREAD_ROW" | jq -r '.id // empty')
		has_next=$$(echo "$$THREAD_JSON" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage // false')
		after=$$(echo "$$THREAD_JSON" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor // empty')
		if [ -n "$$THREAD_GLOBAL_ID" ]; then
			break
		fi
		if [ "$$has_next" != "true" ] || [ -z "$$after" ]; then
			break
		fi
	done
	IS_RESOLVED=$$(echo "$$THREAD_ROW" | jq -r '.isResolved // "false"')
	if [ -z "$$THREAD_GLOBAL_ID" ]; then
		echo "⚠️  Could not find thread global ID for comment $(THREAD_ID)"
		echo "$$THREAD_JSON" | head -5
		exit 1
	fi
	if [ "$$IS_RESOLVED" = "true" ]; then
		echo "✅ Thread $(THREAD_ID) already resolved."
		echo "   URL: https://$(GITHUB_HOST)/$(GITHUB_OWNER)/$(GITHUB_REPO)/pull/$(PR_ID)#discussion_r$(THREAD_ID)"
		exit 0
	fi
	RESPONSE=$$(gh api graphql -f query="mutation { resolveReviewThread(input: {threadId: \"$$THREAD_GLOBAL_ID\"}) { thread { id isResolved } } }" 2>&1)
	if echo "$$RESPONSE" | grep -q '"isResolved":true'; then
		echo "✅ Thread $(THREAD_ID) marked as resolved."
		echo "   URL: https://$(GITHUB_HOST)/$(GITHUB_OWNER)/$(GITHUB_REPO)/pull/$(PR_ID)#discussion_r$(THREAD_ID)"
	else
		echo "⚠️  Could not mark thread as resolved. Response:"
		echo "$$RESPONSE"
		exit 1
	fi

# Reply to a specific discussion thread (nested under that discussion)
# Usage: make reply-to-thread PR_ID=525 THREAD_ID=3306654520 REPLY_BODY='Your response here'
# The reply will appear as a nested comment under the original discussion thread
reply-to-thread: _require-repo ## Reply to a specific PR discussion thread
	@if [ -z "$(PR_ID)" ] || [ -z "$(THREAD_ID)" ] || [ -z "$(REPLY_BODY)" ]; then \
		echo "ERROR: PR_ID, THREAD_ID, and REPLY_BODY required."; \
		echo "Usage: make reply-to-thread PR_ID=525 THREAD_ID=3306654520 REPLY_BODY='Your response'"; \
		exit 1; \
	fi
	@echo "Replying to thread $(THREAD_ID) on PR $(PR_ID)..."
	@RESPONSE=$$(gh api repos/$(GITHUB_OWNER)/$(GITHUB_REPO)/pulls/$(PR_ID)/comments \
		-X POST \
		-f body="$(REPLY_BODY)" \
		-F in_reply_to=$(THREAD_ID) 2>&1); \
	if echo "$$RESPONSE" | grep -q '"id"'; then \
		REPLY_ID=$$(echo "$$RESPONSE" | jq -r '.id'); \
		echo "✅ Reply posted to thread $(THREAD_ID)."; \
		echo "   Reply ID: $$REPLY_ID"; \
		echo "   URL: https://$(GITHUB_HOST)/$(GITHUB_OWNER)/$(GITHUB_REPO)/pull/$(PR_ID)#discussion_r$$REPLY_ID"; \
	else \
		echo "⚠️  Could not post reply. Response:"; \
		echo "$$RESPONSE"; \
		exit 1; \
	fi

# Batch resolve multiple threads from a file (one URL or thread ID per line)
# Usage: make batch-resolve-threads PR_ID=525 RESOLVED_FILE=threads.txt
batch-resolve-threads: _require-repo ## Mark multiple threads as resolved (from file: one URL/ID per line)
	@if [ -z "$(PR_ID)" ] || [ -z "$(RESOLVED_FILE)" ]; then \
		echo "ERROR: PR_ID and RESOLVED_FILE required."; \
		echo "Usage: make batch-resolve-threads PR_ID=525 RESOLVED_FILE=threads.txt"; \
		exit 1; \
	fi
	@if [ ! -f "$(RESOLVED_FILE)" ]; then \
		echo "ERROR: File not found: $(RESOLVED_FILE)"; \
		exit 1; \
	fi
	@echo "Processing $(RESOLVED_FILE)..."
	@mkdir -p .reports
	@PROCESSED=0; FAILED=0; \
	while IFS= read -r line; do \
		[ -z "$$line" ] && continue; \
		if echo "$$line" | grep -qE 'https://.*#discussion_r'; then \
			THREAD_ID=$$(echo "$$line" | sed -E 's/.*#discussion_r([0-9]+).*/\1/'); \
		elif echo "$$line" | grep -qE '^[0-9]+$$'; then \
			THREAD_ID="$$line"; \
		else \
			echo "⚠️  Skipping invalid entry: $$line"; \
			continue; \
		fi; \
		if $(MAKE) -C $(PR_REVIEW_DIR) -f $(abspath $(lastword $(MAKEFILE_LIST))) mark-thread-resolved PR_ID=$(PR_ID) THREAD_ID="$$THREAD_ID" >/dev/null 2>&1; then \
			PROCESSED=$$((PROCESSED + 1)); \
		else \
			FAILED=$$((FAILED + 1)); \
		fi; \
	done < "$(RESOLVED_FILE)"; \
	echo ""; \
	echo "Summary:"; \
	echo "  Processed: $$PROCESSED threads"; \
	echo "  Failed: $$FAILED threads"; \
	[ $$FAILED -eq 0 ] || exit 1

# ─────────────────────────────────────────────────────────────────────────────
# Discovery & Listing
# ─────────────────────────────────────────────────────────────────────────────

# List all CodeRabbit inline comments on a PR with URLs and thread IDs
# Usage: make pr-list-comments PR_ID=525
pr-list-comments: _require-repo ## List all CodeRabbit inline comments with URLs
	@if [ -z "$(PR_ID)" ]; then \
		echo "ERROR: PR_ID not set. Usage: make pr-list-comments PR_ID=525"; \
		exit 1; \
	fi
	@echo "CodeRabbit Comments on PR #$(PR_ID):"
	@echo "─────────────────────────────────────"
	@gh api --paginate repos/$(GITHUB_OWNER)/$(GITHUB_REPO)/pulls/$(PR_ID)/reviews \
		--jq '.[] | select(.user.login == "coderabbitai[bot]") | .id' \
		2>/dev/null | while read REVIEW_ID; do \
		gh api --paginate repos/$(GITHUB_OWNER)/$(GITHUB_REPO)/pulls/$(PR_ID)/reviews/$$REVIEW_ID/comments \
			--jq '.[] | "\(.html_url)"' 2>/dev/null; \
	done | sort | uniq

# List all reviews (with IDs) for a PR
# Usage: make pr-list-reviews PR_ID=525
pr-list-reviews: _require-repo ## List all reviews with IDs for a PR
	@if [ -z "$(PR_ID)" ]; then \
		echo "ERROR: PR_ID not set. Usage: make pr-list-reviews PR_ID=525"; \
		exit 1; \
	fi
	@echo "Reviews on PR #$(PR_ID):"
	@echo "───────────────────────"
	@gh api repos/$(GITHUB_OWNER)/$(GITHUB_REPO)/pulls/$(PR_ID)/reviews \
		--jq '.[] | "\(.id) | \(.user.login) | \(.state) | \(.submitted_at)"' 2>/dev/null | \
		awk -F '|' '{printf "%-12s | %-20s | %-18s | %s\n", $$1, $$2, $$3, $$4}'

# ─────────────────────────────────────────────────────────────────────────────
# Reporting
# ─────────────────────────────────────────────────────────────────────────────

# Generate a report of resolved and unresolved threads for a PR
# Usage: make pr-feedback-report PR_ID=525
pr-feedback-report: _require-repo ## Generate report of resolved/unresolved CodeRabbit threads
	@if [ -z "$(PR_ID)" ]; then \
		echo "ERROR: PR_ID not set. Usage: make pr-feedback-report PR_ID=525"; \
		exit 1; \
	fi
	@mkdir -p .reports
	@echo "Generating feedback report for PR #$(PR_ID)..."
	@echo ""
	@echo "PR #$(PR_ID) Feedback Report" > $(REPORT_FILE)
	@echo "═══════════════════════════════════════════" >> $(REPORT_FILE)
	@echo "Generated: $$(date)" >> $(REPORT_FILE)
	@echo "" >> $(REPORT_FILE)
	@echo "CodeRabbit Comments:" >> $(REPORT_FILE)
	@echo "───────────────────" >> $(REPORT_FILE)
	@COUNT=0; \
	gh api --paginate repos/$(GITHUB_OWNER)/$(GITHUB_REPO)/pulls/$(PR_ID)/reviews \
		--jq '.[] | select(.user.login == "coderabbitai[bot]") | .id' \
		2>/dev/null | while read REVIEW_ID; do \
		gh api --paginate repos/$(GITHUB_OWNER)/$(GITHUB_REPO)/pulls/$(PR_ID)/reviews/$$REVIEW_ID/comments \
			--jq '.[] | "\(.html_url) | \(.path) | \(.body | split("\n")[0])"' 2>/dev/null | while IFS='|' read url path summary; do \
			COUNT=$$((COUNT + 1)); \
			printf "%3d. %s\n" "$$COUNT" "$$url" >> $(REPORT_FILE); \
			printf "     File: %s\n" "$$path" >> $(REPORT_FILE); \
			printf "     Summary: %s\n" "$$summary" >> $(REPORT_FILE); \
		done; \
	done
	@echo "" >> $(REPORT_FILE)
	@echo "Summary:" >> $(REPORT_FILE)
	@TOTAL=$$(grep -c 'https://$(GITHUB_HOST)' $(REPORT_FILE) || echo 0); \
	echo "  Total threads: $$TOTAL" >> $(REPORT_FILE)
	@echo "Report saved to: $(REPORT_FILE)"
	@cat $(REPORT_FILE)

# ─────────────────────────────────────────────────────────────────────────────
# Integration with pr-feedback-fixer.prompt.md
# ─────────────────────────────────────────────────────────────────────────────

# Suggested usage in pr-feedback-fixer.prompt.md Step 4 (Per-Comment Record):
# After creating per-comment records and ledger, use these targets to systematically resolve threads:
#
# 1. Fetch all CodeRabbit comments:
#    make -f .agents/skills/spectra/spectra-pr-feedback-fixer/pr-feedback-fixer.mk pr-list-comments PR_ID=525
#
# 2. Extract thread IDs for threads you've addressed:
#    make -f .agents/skills/spectra/spectra-pr-feedback-fixer/pr-feedback-fixer.mk extract-thread-id THREAD_URL='https://<host>/<owner>/<repo>/pull/525#discussion_r...'
#
# 3. Mark resolved threads in batch:
#    make -f .agents/skills/spectra/spectra-pr-feedback-fixer/pr-feedback-fixer.mk batch-resolve-threads PR_ID=525 RESOLVED_FILE=addressed-threads.txt
#
# 4. Generate report:
#    make -f .agents/skills/spectra/spectra-pr-feedback-fixer/pr-feedback-fixer.mk pr-feedback-report PR_ID=525

.PHONY: pr-help pr-repo _require-repo extract-thread-id mark-thread-resolved batch-resolve-threads pr-list-comments pr-list-reviews pr-feedback-report
