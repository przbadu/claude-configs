#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <branch-name> [base-branch]"
    exit 1
fi

# make sure the .worktrees directory exists
mkdir -p .worktrees

# add .worktrees to .gitignore if not already there
if ! grep -qx '.worktrees' .gitignore 2>/dev/null; then
    echo ".worktrees" >> .gitignore
fi

BRANCH_NAME=$1
BASE_BRANCH=${2:-main}
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
WORKTREE_PATH=".worktrees/${REPO_NAME}-${BRANCH_NAME}"

# Create worktree
git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "$BASE_BRANCH"

echo "Worktree created at: $WORKTREE_PATH"
echo "Ready for development!"
