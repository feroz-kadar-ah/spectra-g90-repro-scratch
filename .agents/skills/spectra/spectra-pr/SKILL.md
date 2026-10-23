---
name: spectra-pr
description: Sync the current branch with the default branch of origin, commit, push and open a pull request that follows the template and the conventions of this repo. Use when the user runs /spectra-pr.
---

Needs: `git`, a checkout with an `origin` remote, and `gh` signed in to the host of that remote.

Identity: `spectra-pr`. Invoke it as `/spectra-pr` or `/spectra-pr <commit message>`.

`/spectra-pr` publishes the current branch. Sync means a git rebase onto the fetched default branch of `origin`. It does not run an OpenSpec spec sync.

## 1. Check the tools and find the default branch

Stop before any change when `gh auth status` fails. Report it.

Resolve the default branch before you stash, fetch, rebase, commit, push or open a pull request:

```text
git ls-remote --symref origin HEAD
```

Accept only a line `ref: refs/heads/<default-branch>` followed by a tab and `HEAD`. The default branch is the text after `refs/heads/`, unchanged, including slashes. Accept the name only when it matches `^[A-Za-z0-9][A-Za-z0-9._/-]*$`, does not contain `..`, and does not end with `.lock`. When the command fails, prints no symbolic ref, or the name is not safe, stop and report that the default branch of `origin` cannot be used. Do not assume a name.

Stop when the current branch is the default branch. Do not commit, rebase, push or open a pull request.

## 2. Find the conventions of the repo

- __Commit message and title.__ Read the rule in `AGENTS.md`, then `CONTRIBUTING.md` (at the root, in `.github/` or in `docs/`). When neither has a rule, read the titles of the last 10 merged pull requests with `gh pr list --state merged --limit 10`. Use a pattern only when most titles follow it. When you find no pattern, ask the person once and use the answer for the session.
- __Pull request template.__ Look in this order: `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, the files in `.github/PULL_REQUEST_TEMPLATE/`, `docs/pull_request_template.md`, `pull_request_template.md` at the root. When the folder holds more than one template, ask which one to use.

## 3. Publish

Pass every argument that holds a name as one single-quoted shell argument.

1. When `git status --porcelain` is not empty, stash the changes.
2. Run `git fetch origin '+refs/heads/<default-branch>:refs/remotes/origin/<default-branch>'`, then `git rebase 'origin/<default-branch>'`. A rebase conflict stops the command. Do not commit, push or open a pull request.
3. When you took a stash, restore it. A stash conflict stops the command. Do not commit or push.
4. When changes remain, commit them. Use the message that the person gave. When none was given, write one that follows the pattern from step 2, or ask. When nothing remains, continue without a commit.
5. Push to `origin`. When the branch has no upstream, set it. Do not force-push.
6. When the branch has an open pull request, report its URL. Do not open another. Do not edit it. Do not change its body.
7. When none exists, open one with `gh pr create --base '<default-branch>'`. Give the body as the single `--body` argument.

## 4. The body

When the repo has a template, use it. Keep its headings in its order. Fill each section. Do not remove a section and do not add one. A field that asks for an issue key or a link gets the value that the person gives. Ask for it. Do not invent one. Do not add a tracking line that the template does not have.

When the repo has no template, the body starts at Summary and holds Summary, Evidence and Merge Danger, in that order, with no preamble.

- __Summary__ shows the change as the smallest visual that makes it clear, with brief text beside it. The visual is pseudocode, a call tree, a component tree, a file tree, a diagram of interaction or data flow, or a shaped diff. Use one visual. Add another only when one cannot show the change.
- __Evidence__ is a before screenshot and an after screenshot when the change is visual and you can capture them. Otherwise it is the check that failed before and passes after, or the output that changed. The statement "tests pass" is not Evidence. When you cannot produce a before and an after, stop and do not open the pull request. A template section that asks for tests, evidence or screenshots follows the same rule.
- __Merge Danger__ states the door as one-way or two-way, and states the blast radius: what could break if the change is wrong. The door is one-way when the change has a schema migration, a public API removal, an event or other payload that ships outward, a deletion of stored data or of a public contract, or a money movement. Otherwise it is two-way. For a one-way door, name which kind applies.

Report the URL of the pull request.
