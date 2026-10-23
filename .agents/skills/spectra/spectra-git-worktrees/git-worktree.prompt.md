---
name: spectra-git-worktree
---

# Git worktree workflow

Use when creating, listing, or removing git worktrees (parallel branches, PR review checkouts, hotfix isolation).

## Repo values

Read these when the skill starts. Do not store them in a file or a config key.

- Repo name: the last path segment of `git remote get-url origin`, without `.git`. When the remote is missing, use the name of the top-level directory (`git rev-parse --show-toplevel`).
- Default branch: `git symbolic-ref --short refs/remotes/origin/HEAD` gives `origin/<branch>`. Use `main` only when that command fails.
- Branch rules: the repo's own convention, from `AGENTS.md` or `CONTRIBUTING.md`. When the repo states none, match the style of `git branch -r` and `git log -10 --format=%s`.

## Procedure

1. Run every `git worktree` command from the top level of the checkout (`git rev-parse --show-toplevel`). For a submodule, run it with `git -C <submodule path>`, so that the worktree belongs to the submodule repo.
2. Name the branch by the repo convention. When the repo has none, use `<mmdd>-<short-title>`, or `<TICKET>-<short-title>` when a ticket owns the work.
3. Put each worktree beside the checkout, not inside it: `../<repo>-wt-<slug>`. Use one slug for one piece of work. Do not reuse a path.
4. Create it from the fetched default branch:

   ```sh
   git fetch origin <branch>
   git worktree add -b <new-branch> ../<repo>-wt-<slug> origin/<branch>
   ```

   To review a pull request, do not switch branches. Fetch its head and add a worktree for it:

   ```sh
   git fetch origin pull/<number>/head:pr-<number>
   git worktree add ../<repo>-wt-review-<number> pr-<number>
   ```

   For a hotfix, create the worktree from the release branch or tag, not from the default branch.
5. List the worktrees with `git worktree list`. To work on another branch, change to its worktree. Do not stash.
6. Remove a worktree only after its work is merged or pushed. Run `git worktree remove ../<repo>-wt-<slug>`, then `git worktree prune`. Do not pass `--force`. Do not delete a branch with `-D`. When a removal refuses, report the reason and ask the person what to do.
7. Report the path, the branch and the command to remove it.
