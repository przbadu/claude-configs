---
name: github-pr
description: Create or find a GitHub pull request for the current branch and open it in the browser. Use when the user asks to "create a PR", "open a PR", "make a pull request", "submit PR", "/pr", "push and create PR", or any variation of creating, finding, or opening a GitHub pull request.
---

# GitHub Pull Request

Create a PR for the current branch against `origin/master`, or find the existing PR if one already exists, then open it in Chrome.

## Workflow

### 1. Ensure changes are pushed

```bash
# Check if current branch has an upstream and is up to date
git status -sb
```

If the branch has unpushed commits, push with:

```bash
git push -u origin HEAD
```

### 2. Check for existing PR

```bash
gh pr view --web 2>/dev/null
```

If a PR already exists, this opens it in the browser. Done.

### 3. Create new PR if none exists

Gather context for the PR:

```bash
# Get current branch name
git branch --show-current

# Get all commits on this branch vs master
git log master..HEAD --oneline

# Get the full diff against master
git diff master...HEAD
```

Create the PR using `gh`:

```bash
gh pr create --base master --fill --web
```

The `--fill` flag auto-populates title and body from commit messages. The `--web` flag opens the PR in the browser immediately after creation.

If commits are too varied for `--fill`, draft a title and body manually:

```bash
gh pr create --base master --title "<title>" --body "$(cat <<'EOF'
## Summary
<bullet points>

## Test plan
<verification steps>
EOF
)" --web
```

### 4. Confirm to user

Print the PR URL so the user can see it.

## Notes

- Always target `master` as the base branch
- Always open the PR in the browser after creating or finding it
- Use `--web` flag on `gh pr create` or `gh pr view` to open in browser
- If `gh` is not authenticated, inform the user to run `gh auth login`
