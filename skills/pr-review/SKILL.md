---
name: pr-review
description: >
  Dual-agent GitHub PR code review. Spawns two parallel background agents: (1) a Sonnet agent that finds and fixes GitHub Copilot review comments/issues on the PR, and (2) an Opus agent that performs a comprehensive code review covering security, performance, best practices, and test coverage. Use when the user asks to "review a PR", "review pull request", "code review", shares a GitHub PR URL and wants review, or asks to "fix copilot issues" on a PR. Triggers: PR URLs, "review PR #123", "review this PR", "spawn review agents", "review team".
---

# PR Review

Dual-agent parallel code review for GitHub Pull Requests.

## Workflow

When triggered with a GitHub PR URL or PR number:

1. Extract the PR URL/number and repo from user input
2. Spawn **two agents in parallel** (both `run_in_background: true`):
   - **Copilot Fixer** (Sonnet, `rails-expert-engineer`) — finds and fixes Copilot review issues
   - **Code Reviewer** (Opus, `rails-expert-engineer`) — comprehensive read-only review
3. Report results as each agent completes

## Agent 1: Copilot Fixer (Sonnet)

Prompt template:

```
Review the GitHub PR {PR_URL} and fix all GitHub Copilot review issues/comments.

Steps:
1. Use `gh pr view {PR_NUMBER} --repo {REPO}` to get PR details
2. Use `gh api repos/{REPO}/pulls/{PR_NUMBER}/reviews` to find Copilot reviews
3. Use `gh api repos/{REPO}/pulls/{PR_NUMBER}/comments` to find all review comments
4. Look for any comments from GitHub Copilot (author association or bot markers)
5. Read the relevant files and fix each issue Copilot flagged
6. Make the fixes in the codebase

Important: Actually implement the fixes, don't just report them.
```

Config: `model: sonnet`, `subagent_type: rails-expert-engineer`

## Agent 2: Code Reviewer (Opus)

Prompt template:

```
Perform a thorough code review of GitHub PR {PR_URL}.

Steps:
1. Use `gh pr view {PR_NUMBER} --repo {REPO}` to get PR details
2. Use `gh pr diff {PR_NUMBER} --repo {REPO}` to get the full diff
3. Use `gh api repos/{REPO}/pulls/{PR_NUMBER}/files` to list changed files
4. Read any changed files that need deeper context to review properly
5. Provide a comprehensive code review covering:
   - Code quality and Rails best practices
   - Security concerns (SQL injection, XSS, auth issues)
   - Performance issues (N+1 queries, missing indexes, etc.)
   - Test coverage adequacy
   - Error handling
   - Any bugs or logic errors
   - Naming conventions and code style
6. Categorize findings by severity: CRITICAL, HIGH, MEDIUM, LOW
7. Include file paths and line numbers

This is a review-only task -- do NOT make any code changes. Just report findings.
```

Config: `model: opus`, `subagent_type: rails-expert-engineer`

## Result Reporting

As each agent completes, summarize its results to the user:

- **Copilot Fixer**: List each fix applied with file and description
- **Code Reviewer**: Present findings organized by severity (CRITICAL > HIGH > MEDIUM > LOW), with missing test coverage section and actionable recommendations

After both complete, ask the user if they want to run tests or commit the Copilot fixes.
