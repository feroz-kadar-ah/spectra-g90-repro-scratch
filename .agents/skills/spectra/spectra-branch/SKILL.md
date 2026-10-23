---
name: spectra-branch
description: Cut a git branch from the fetched default branch of origin, named by the branch pattern of this repo. Use when the user runs /spectra-branch or wants a new branch for a change.
---

Needs: `git`, a checkout with an `origin` remote, and a clean working tree.

Identity: `spectra-branch`. Invoke it as `/spectra-branch <parts>`.

`/spectra-branch` checks out one new branch from the fetched default branch of `origin`. The repo decides the name. The skill does not.

## 1. Find the branch pattern

Look in this order and use the first source that states a pattern.

1. `AGENTS.md` at the repo root. Look for a rule about branch names.
2. `CONTRIBUTING.md` at the repo root, in `.github/` or in `docs/`.
3. The names of the 20 newest remote branches, without the default branch. Run `git branch -r --sort=-committerdate`. Use a pattern only when at least three names follow it. Show the pattern to the person and wait for a yes. A pattern from names alone is a guess.

When no source states a pattern, ask the person once: "What is the branch name pattern of this repo?" Use the answer for the rest of the session. Do not write it to a file. Do not invent a pattern.

## 2. Build the name

- Take each part of the pattern (for example a ticket key, a type word, a short slug) from the argument. Ask for each part that is missing.
- Do not invent a ticket key. Do not look a ticket up. Do not assume that a repo uses a tracker.
- Run `git check-ref-format --branch '<name>'`. When it fails, report the name and ask for a corrected one. Create nothing.

## 3. Check the repo

- Stop when `git status --porcelain` is not empty. Do not create or check out a branch. Do not carry the changes to a branch.
- Stop when a local branch of that name exists, or when `git ls-remote --heads origin '<name>'` finds one. Do not reset or overwrite it.

## 4. Find the default branch

Resolve it before you fetch or check out anything:

```text
git ls-remote --symref origin HEAD
```

Accept only a line `ref: refs/heads/<default-branch>` followed by a tab and `HEAD`. The default branch is the text after `refs/heads/`, unchanged, including slashes. Accept the name only when it matches `^[A-Za-z0-9][A-Za-z0-9._/-]*$`, does not contain `..`, and does not end with `.lock`. When the command fails, prints no symbolic ref, or the name is not safe, stop and report that the default branch of `origin` cannot be used. Do not assume a name.

## 5. Create the branch

Pass every argument that holds a name as one single-quoted shell argument:

```text
git fetch origin '+refs/heads/<default-branch>:refs/remotes/origin/<default-branch>'
git checkout -b '<name>' 'origin/<default-branch>'
```

Do not branch from the current HEAD. Do not commit, push or open a pull request. Report the name of the new branch and the commit that it starts from.
