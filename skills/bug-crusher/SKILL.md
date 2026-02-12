---
name: bug-crusher
description: >
  Triage, rank, and fix GitHub bug tickets to systematically reduce bug count.
  Fetches open issues with "Bug" label from a GitHub repo, scores each by complexity
  and AI-fixability, presents a ranked dashboard, and guides the user through fixing
  selected bugs using git worktrees, task-master, and automated PR creation.
  Use when: user says "crush bugs", "triage bugs", "fix bugs", "bug crusher",
  "reduce bug count", "low hanging bugs", "show me bugs", "/bug-crusher",
  "what bugs can AI fix", "bug dashboard", "bug progress", or any request to
  systematically work through GitHub bug tickets.
---

# Bug Crusher

Systematically triage, rank, and fix GitHub bugs to hit a target bug count. Scores each bug for complexity and AI-fixability, recommends quick wins, and orchestrates the full fix-validate-PR workflow.

## Workflow Overview

1. **Setup** - Get GitHub repo URL (first run: ask user, save to memory; subsequent: load from memory)
2. **Fetch** - Pull all open "Bug" labeled issues via `gh` CLI
3. **Analyze** - Score each bug for complexity + AI-fixability
4. **Dashboard** - Present ranked list with progress toward target
5. **Fix** - User selects bug(s) -> worktree -> implement -> test -> PR

## Step 1: Setup - Resolve GitHub Repository

Check project-specific memory for a saved bug-crusher config:

```
~/.claude/projects/<project-path>/memory/bug-crusher.md
```

The memory file stores:
```markdown
# Bug Crusher Config
- repo: owner/repo
- target: 15
- bugs_fixed: [list of closed issue numbers]
```

**First run**: Ask the user for their GitHub issues URL (e.g., `https://github.com/org/repo/issues?q=label:Bug`). Extract the `owner/repo` from it. Ask for their target bug count (default: 15). Save to memory.

**Subsequent runs**: Load config from memory. Confirm repo with user: "Using `owner/repo` - correct?"

## Step 2: Fetch Bugs

Run the fetch script:

```bash
bash <skill-path>/scripts/fetch_bugs.sh owner/repo
```

This returns JSON with: number, title, body (truncated to 2000 chars), labels, dates, comment count, assignees, url, and age in days.

If the script fails or `gh` is not authenticated, fall back to:
```bash
gh issue list --repo owner/repo --label "Bug" --state open --limit 100 --json number,title,body,labels,url
```

## Step 3: Analyze and Score Each Bug

Read the scoring criteria from [references/scoring-criteria.md](references/scoring-criteria.md) for the full rubric.

For each bug, produce two scores:

### Complexity Score (1-10, lower = simpler)
Assess based on: lines of code likely affected, number of files involved, dependency coupling, whether DB migrations are needed, external service involvement.

To assess accurately:
1. Read the issue title and body for clues (file paths, error messages, stack traces)
2. Search the codebase for referenced classes, methods, or error messages using Grep/Glob
3. Estimate scope based on what you find

### AI-Fixability Score (1-10, higher = more AI-fixable)
Assess based on: clarity of reproduction steps, scope isolation, existing test coverage, error/backtrace availability, whether it matches a common bug pattern, code clarity.

### Priority Score
```
priority = (11 - complexity) + ai_fixability
```
Range 2-20. Higher = better candidate for AI fix.

### Priority Tiers
- **16-20 Quick Win**: Fix immediately with AI
- **12-15 Good Candidate**: AI can likely handle with guidance
- **8-11 Moderate**: AI assists but needs human review
- **2-7 Complex**: Human-led, AI assists

## Step 4: Present Dashboard

Display results in this format:

```
## Bug Crusher Dashboard

Target: 15 bugs | Current: 28 open | To close: 13
Progress: [========----------] 0/13 fixed this cycle

### Quick Wins (Priority 16-20)
| # | Title | Complexity | AI-Fix | Priority | Age |
|---|-------|-----------|--------|----------|-----|
| #123 | Nil error in user export | 2 | 9 | 18 | 45d |
| #456 | Missing validation on... | 3 | 8 | 16 | 12d |

### Good Candidates (Priority 12-15)
| # | Title | Complexity | AI-Fix | Priority | Age |
|---|-------|-----------|--------|----------|-----|
...

### Moderate (Priority 8-11)
...

### Complex (Priority 2-7)
...
```

After displaying, ask: **"Which bug(s) would you like to fix? Enter issue number(s), or 'auto' to start with the top quick win."**

## Step 5: Fix Selected Bug

Once the user selects a bug, execute this workflow:

### 5a. Create Worktree
Use the `git-worktree` skill pattern:
```bash
git worktree add ../$(basename $PWD)-bug-{issue_number} -b issues/{issue_number}
```

### 5b. Understand the Bug
1. Fetch full issue details: `gh issue view {number} --repo owner/repo --json body,comments`
2. Read all comments for additional context
3. Search codebase for referenced files, error messages, stack traces
4. Identify the root cause

### 5c. Plan the Fix
Use task-master if the fix involves multiple steps:
```bash
task-master add-task --prompt="Fix #{number}: {title}. {description}"
task-master expand --id={task_id}
```

For simple fixes (complexity <= 3), skip task-master and fix directly.

### 5d. Implement and Validate
1. Make the code changes
2. Run relevant tests: `bundle exec rails test {test_file}` or `bundle exec rspec {spec_file}`
3. Run linter: `bundle exec rubocop --autocorrect {changed_files}`
4. If tests don't exist, write them first (RSpec for new tests)

### 5e. Create Pull Request
Use the `github-pr` skill pattern:
```bash
git add {files}
git commit -m "fix(scope): #{issue_number} {description}"
gh pr create --title "fix: #{issue_number} {title}" --body "Fixes #{issue_number}\n\n## Summary\n{what_changed}\n\n## Test plan\n{test_details}"
```

### 5f. Update Progress
After PR is created, update the memory file:
- Add issue number to `bugs_fixed` list
- Update the dashboard counts

Then ask: **"PR created for #{number}. Ready for the next bug?"**

## Auto-Fix Mode

When user says "auto" or requests batch fixing:

1. Start with highest-priority Quick Win
2. Before each fix, confirm with user: "Next: #{number} - {title} (Priority: {score}). Proceed?"
3. On user approval, execute Step 5 workflow
4. After each fix, show updated progress dashboard
5. Continue until user stops or all Quick Wins are done

Never auto-fix without confirmation per bug.

## Staleness Detection

Flag bugs that may be stale or already fixed:
- **Age > 180 days** with no recent comments: "May be outdated - verify still relevant"
- **Referenced code no longer exists**: "Code referenced in issue may have been refactored"
- **Similar recent PRs merged**: "Check if PR #{pr_number} already addresses this"

Present stale candidates separately: "These bugs may already be resolved. Verify before fixing, or close if no longer relevant."

## Memory File Format

```markdown
# Bug Crusher Config

## Repository
- repo: owner/repo
- target: 15

## Progress
- last_triage_date: 2025-01-15
- bugs_at_start: 30
- bugs_fixed: [#123, #456, #789]

## Session Log
### 2025-01-15
- Triaged 28 bugs
- Fixed #123 (nil error in export) - PR #500
- Fixed #456 (missing validation) - PR #501
```
