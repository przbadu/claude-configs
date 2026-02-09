---
name: git-worktree
description: Manage git worktrees for parallel development. Use when the user wants to create a new worktree, work on a feature in a separate worktree, list existing worktrees, clean up merged worktrees, or any variation of "new worktree", "parallel branch", "worktree for feature X". Triggers on requests like "create a worktree", "start a new feature in a worktree", "show my worktrees", "clean up worktrees", or "I want to work on X in parallel".
---

# Git Worktree

Manage git worktrees so developers can work on multiple branches in parallel without stashing or switching.

## Create a worktree

Run the bundled script from the repo root:

```bash
bash <skill-path>/scripts/create-worktree.sh <branch-name> [base-branch]
```

- `branch-name` — the new branch to create (required)
- `base-branch` — branch to base it on (defaults to `main`)

The script creates the worktree at `.worktrees/<repo>-<branch>` and adds `.worktrees` to `.gitignore`.

After creation, tell the user the worktree path so they can open it in their editor or run a second Claude Code session in it.

## List worktrees

```bash
git worktree list
```

Show the output to the user in a readable format.

## Clean up merged worktrees

Run the bundled cleanup script from the repo root:

```bash
bash <skill-path>/scripts/cleanup-worktrees.sh
```

This removes worktrees whose branches have been merged into `main` and deletes those branches.

## Important notes

- Always run worktree commands from the main repo root, not from inside a worktree.
- Never delete a worktree without checking if its branch is merged first.
- If the user asks to "remove" or "delete" a specific worktree, use `git worktree remove <path>` and confirm with the user before deleting the branch.
