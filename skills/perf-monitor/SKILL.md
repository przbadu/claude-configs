---
name: perf-monitor
description: Daily production performance monitoring, diagnosis, and auto-fix using Chrome browser automation. Checks New Relic APM, Logtails logs, PGHero slow queries, and Airbrake errors to produce a scored performance report and automatically fix the highest-impact issue. Use when the user asks to "check performance", "morning perf check", "run perf monitor", "/perf-monitor", "daily performance report", "check new relic", "check production health", or any variation of monitoring and fixing production performance issues. Requires Chrome browser automation.
---

# Perf Monitor

Daily production performance monitor that scans New Relic, Logtails, PGHero, and Airbrake via Chrome, scores issues by impact, fixes the top issue in an isolated git worktree, and opens a PR.

## Prerequisites

- Chrome browser automation must be enabled (`--chrome` flag or chrome enabled in settings)
- User must be logged into New Relic, Logtails, PGHero, and Airbrake in Chrome
- Git worktree support (uses the `git-worktree` skill)
- GitHub CLI (`gh`) for PR creation (uses the `github-pr` skill)

If Chrome is not available, immediately tell the user:
> "This skill requires Chrome browser automation. Start Claude Code with `--chrome` flag or enable chrome in your settings."

## URL Management

On first run, ask the user for these URLs:
- **New Relic** — APM transactions page URL
- **Logtails** — Dashboard URL
- **PGHero** — Dashboard URL
- **Airbrake** — Project groups URL

Store them in the project's auto memory directory under `perf-monitor-urls.md`. On subsequent runs, read URLs from memory. If a URL is missing or invalid, ask the user for it.

Memory file format:
```markdown
## Perf Monitor URLs
- newrelic: <url>
- logtails: <url>
- pghero: <url>
- airbrake: <url>
```

## Time Window Logic

Determine the lookback window based on the current day:
- **Monday**: Check last **3 days** (covers Saturday + Sunday + Monday morning)
- **Tuesday–Friday**: Check last **1 day** (24 hours)

Apply this window to all tool checks below. When navigating dashboards, set the time range accordingly.

## Workflow

### Phase 1: Data Collection

Execute steps 1–6 sequentially. Collect all data before scoring.

### Step 1: New Relic — Recent Performance

1. Navigate to the New Relic APM transactions URL
2. Set the time picker to the lookback window (1 day or 3 days)
3. Take a screenshot for reference
4. Extract from the transactions list:
   - **Top 10 slowest transactions** by average response time
   - For each: transaction name, avg response time, throughput (rpm), error rate
   - **Overall app response time** and **throughput** for the period
   - **Apdex score** if visible

Record this data for the report.

### Step 2: New Relic — Weekly Comparison

1. Set the time picker to **last 7 days**
2. Note the overall response time, throughput, and error rate
3. Set the time picker to **7–14 days ago** (previous week)
4. Note the same metrics
5. Calculate the delta:
   - Response time: improved/degraded by X%
   - Throughput: changed by X%
   - Error rate: changed by X%

Record weekly comparison for the report.

### Step 3: New Relic — Root Cause Analysis

For each of the top 5 slowest transactions from Step 1:

1. Click into the transaction detail page
2. Identify the slow segments (database queries, external calls, application code)
3. Extract the URL pattern — look for `company_id` query parameter to identify impacted companies
4. Note the controller#action and any N+1 query patterns or slow SQL visible in the trace

Record per-transaction breakdown for the report.

### Step 4: Logtails — H12 Timeout Errors

1. Navigate to the Logtails URL
2. Set the time range to the lookback window
3. Apply filter: `heroku.code:"H12"`
4. Extract:
   - **Total H12 count** in the period
   - **Endpoints** that timed out (group by path if possible)
   - **company_id** from request parameters — identify which company was affected most
5. Take a screenshot

Record H12 data for the report.

### Step 5: Logtails — 500 Error Pages

1. In Logtails, change filter to: `heroku.path:"500.html"`
2. Extract:
   - **Total 500 page count** in the period — this is the number of customers who actually saw an error page
   - **Endpoints** that produced 500s
   - **company_id** of affected customers
3. Take a screenshot

Record 500 data for the report. Flag this as **critical** if count > 0.

### Step 6: PGHero — Slow Queries

1. Navigate to the PGHero URL
2. Check the **Slow Queries** section
3. Extract:
   - Queries with avg duration > 100ms
   - For each: query text (truncated), avg duration, calls count
   - Any **long-running queries** currently active
4. Check **Space** section for table bloat or missing indexes if visible
5. Take a screenshot

Record slow query data for the report.

### Phase 2: Scoring and Report

### Step 7: Score Issues by Impact

Assign an impact score (1–10) to each issue found, using this rubric:

| Factor | Weight | Description |
|--------|--------|-------------|
| Customer visibility | 3x | Did customers see error pages (500s)? |
| Frequency | 2x | How often does this occur? |
| Breadth | 2x | How many companies/users affected? |
| Severity | 2x | Timeouts (H12) > slow pages > minor delays |
| Fixability | 1x | Can this be fixed in code today? |

**Score formula**: `(customer_visibility * 3 + frequency * 2 + breadth * 2 + severity * 2 + fixability * 1) / 10`

Rank all issues by score descending.

### Step 8: Generate Report

Save a markdown report to the current working directory:

**Filename**: `perf-report-YYYY-MM-DD.md`

**Report structure** — see [references/report-template.md](references/report-template.md) for the full template.

The report must include:
- Date, lookback window, day of week
- Executive summary (3–5 bullet points)
- New Relic: app health overview + weekly comparison table
- Top slow transactions with impacted companies
- H12 timeout summary with most-affected company
- 500 error page summary (flagged critical if any)
- PGHero slow queries summary
- Scored issue ranking table
- Recommended fix for the #1 issue

Print the report file path and a brief summary to the terminal.

### Phase 3: Fix the Top Issue

### Step 9: Propose Fix

Present the #1 scored issue to the user with:
- What the issue is and why it's ranked #1
- The proposed fix approach
- Which files will likely need changes

Ask: **"Should I proceed with fixing this issue?"**

Wait for explicit user confirmation before proceeding.

### Step 10: Create Worktree and Fix

After user approval:

1. Use the `git-worktree` skill to create a worktree:
   ```bash
   bash <git-worktree-skill-path>/scripts/create-worktree.sh perf/YYYY-MM-DD origin/master
   ```

2. Work in the worktree directory to implement the fix
3. Run relevant tests if they exist for changed files

### Step 11: Commit and Create PR

After the fix is implemented:

1. Stage the changed files in the worktree
2. Use the `commit` skill workflow — generate a commit message, confirm with user
3. Push the branch:
   ```bash
   git push -u origin perf/YYYY-MM-DD
   ```
4. Create a PR using `gh`:
   ```bash
   gh pr create --base master --title "perf: fix <brief description>" --body "$(cat <<'EOF'
   ## Summary
   - Daily perf monitor identified this as the #1 impact issue
   - <description of what was fixed and why>

   ## Performance Data
   - Impact score: X/10
   - Affected companies: <list>
   - <relevant metrics from the report>

   ## Test plan
   - [ ] Verify fix resolves the performance issue
   - [ ] Run existing tests for affected files
   - [ ] Monitor New Relic/Logtails after deploy

   See `perf-report-YYYY-MM-DD.md` for full analysis.
   EOF
   )"
   ```
5. Print the PR URL to the user

### Step 12: Final Summary

Print a final summary:
```
## Perf Monitor Complete

Report: perf-report-YYYY-MM-DD.md
PR: <pr-url>
Top issue: <brief description> (score: X/10)
Files changed: <list>
```
