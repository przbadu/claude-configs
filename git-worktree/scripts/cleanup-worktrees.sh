#!/bin/bash

echo "Cleaning up merged worktrees..."

git worktree list | grep -v "$(git rev-parse --show-toplevel)" | while read worktree branch commit; do
    branch_name=$(echo $branch | sed 's/\[//g' | sed 's/\]//g')

    # Check if branch is merged
    if git branch --merged main | grep -q "$branch_name"; then
        echo "Removing merged worktree: $worktree ($branch_name)"
        git worktree remove "$worktree"
        git branch -d "$branch_name"
    fi
done

echo "Cleanup complete!"
