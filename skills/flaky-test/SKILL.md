---
name: flaky-test
description: >-
  Autonomous flaky test fixer, slow test optimizer, and test suite health improver for Rails projects.
  Use when the user asks to: fix flaky tests, speed up slow tests, clean up test suite, optimize test
  performance, find slow queries in tests, remove outdated tests, deduplicate tests, fix timezone
  issues in tests, fix hardcoded ID issues in factories, improve CI time, or any variation of
  "fix my tests", "tests are flaky", "CI is slow", "optimize test suite", "/flaky-test".
  Triggers on: "flaky test", "slow test", "fix tests", "test performance", "CI too slow",
  "test cleanup", "optimize specs", "test health".
---

# Flaky Test Fixer & Test Suite Optimizer

Autonomous skill that identifies, diagnoses, and fixes flaky/slow tests in Rails projects.
Operates in an isolated git worktree, iterates until tests pass fast, then creates a PR.

## Invocation

```
/flaky-test [mode] [target]
```

**Modes:**
- `fix` (default) — Fix flaky/slow tests in target files or auto-detected
- `audit` — Full test suite health audit with recommendations (no changes)
- `cleanup` — Remove outdated, duplicated, or unnecessary tests (asks approval)
- `auto` — Full pipeline: audit → fix → cleanup → PR → watch CI

**Target:** Optional file path, directory, or pattern. If omitted, auto-detect from CI failures or profile the full suite.

**Examples:**
```
/flaky-test                                    # Auto-detect and fix flaky tests
/flaky-test fix spec/models/user_spec.rb       # Fix specific file
/flaky-test audit                              # Full audit, no changes
/flaky-test cleanup spec/models/               # Suggest test cleanup in directory
/flaky-test auto                               # Full autonomous pipeline
```

## Execution Pipeline

### Phase 1: Setup Worktree

Create an isolated worktree for all changes:

```bash
BRANCH="fix/flaky-tests-$(date +%Y%m%d-%H%M%S)"
bash ~/.claude/skills/git-worktree/scripts/create-worktree.sh "$BRANCH" master
cd .worktrees/*-$BRANCH
```

All subsequent work happens inside the worktree. If worktree creation fails, fall back to a regular feature branch.

### Phase 2: Discovery & Profiling

#### 2a. Identify Target Tests

Priority order for finding problematic tests:

1. **User-specified target** — Use the file/dir/pattern provided
2. **Recent CI failures** — Run `gh run list --status failure --limit 5` and inspect logs for test failures
3. **Profile the suite** — Run with profiling to find slowest tests:

```bash
# Minitest
bundle exec rails test TESTOPTS="--profile" 2>&1 | tail -50

# RSpec
bundle exec rspec --profile 20 --format progress 2>&1 | tail -80
```

4. **Known flaky patterns** — Search for common flaky indicators. See [references/flaky-patterns.md](references/flaky-patterns.md) for the complete pattern library.

#### 2b. Categorize Issues

For each problematic test, classify as:

| Category | Symptoms | Common Fix |
|----------|----------|------------|
| **Timezone flaky** | Fails at midnight, month boundaries | Use `travel_to` with fixed time |
| **Hardcoded ID** | Fails when run in different order | Use sequences or let DB assign |
| **Order dependent** | Passes alone, fails in suite | Add proper setup/teardown |
| **Slow query** | >2s per test | Add indexes, use `build_stubbed`, stub expensive calls |
| **Race condition** | Intermittent failures | Add proper waits, avoid shared state |
| **Stale mock** | Fails after code change | Update mock to match current interface |
| **External dependency** | Fails without network | Add VCR cassette or WebMock stub |

### Phase 3: Fix Iteration Loop

For each identified test issue:

1. **Read the test file** — Understand what it tests and why it's failing
2. **Read the source code** — Understand the code under test
3. **Apply the fix** — Make minimal, targeted changes
4. **Run the test** — Verify it passes
5. **Run it 3 times** — Ensure it's not still flaky:
   ```bash
   for i in 1 2 3; do bundle exec rspec path/to/spec.rb:LINE || echo "FAILED on run $i"; done
   ```
6. **Time it** — Confirm performance improvement:
   ```bash
   time bundle exec rspec path/to/spec.rb
   ```
7. **If still failing** — Re-analyze and try a different approach. Max 3 iterations per test.

### Phase 4: Test Suite Audit (audit/auto mode)

Analyze the full test suite for health issues. See [references/audit-checklist.md](references/audit-checklist.md) for the complete checklist.

For `cleanup` and `auto` modes: present findings to the user and **ask for approval** before making cleanup changes. Format as:

```
## Test Cleanup Suggestions

### Remove (outdated/unreachable)
- [ ] test/models/old_feature_test.rb — Tests `OldFeature` removed in commit abc123
- [ ] spec/services/deprecated_service_spec.rb — Service no longer used

### Consolidate (duplicated)
- [ ] spec/models/user_spec.rb:45 and :78 — Both test email validation

### Improve (slow/inefficient)
- [ ] spec/models/report_spec.rb — Creates 500 records per test, use build_stubbed

Approve changes? (y/n/select specific items)
```

### Phase 5: Commit & PR

After all fixes verified:

1. **Stage only changed test files** and any necessary source changes
2. **Commit** using `/commit` skill conventions:
   ```
   test(flaky): fix N flaky tests and optimize M slow tests

   - Fix timezone-dependent assertions using travel_to
   - Replace hardcoded IDs with factory sequences
   - Stub external API calls with VCR cassettes
   ```
3. **Push and create PR:**
   ```bash
   git push -u origin HEAD
   gh pr create --title "test: fix flaky tests and optimize test suite" --body "$(cat <<'EOF'
   ## Summary
   - Fixed N flaky tests (timezone, hardcoded IDs, order-dependent)
   - Optimized M slow tests (reduced from Xs to Ys average)

   ## Changes by category
   [List changes grouped by fix category]

   ## Performance
   | Metric | Before | After |
   |--------|--------|-------|
   | Slowest test | Xs | Ys |

   ## Test plan
   - [x] All modified tests pass locally (3 consecutive runs)
   - [ ] CI passes
   - [ ] CI time under 10 minutes
   EOF
   )"
   ```
4. **Print the PR URL** — Always print the URL at the end.

### Phase 6: CI Watch (auto mode only)

Monitor the PR until CI passes:

```bash
# Poll CI status, max 15 minutes
for i in $(seq 1 15); do
  gh pr checks 2>&1
  STATUS=$?
  if [ $STATUS -eq 0 ]; then echo "CI passed!"; break; fi
  sleep 60
done
```

If CI fails:
1. Download and analyze CI logs: `gh run view --log-failed`
2. Fix the failing test in the worktree
3. Commit and push the fix
4. Resume watching

Target: **CI total time under 10 minutes.** If CI exceeds this, report bottleneck tests/jobs and suggest parallelization.

## Important Rules

- **Never delete tests without user approval** — Always ask first for cleanup
- **Minimal changes** — Fix the test, don't refactor surrounding code
- **Preserve test intent** — The test should still verify the same behavior
- **Run in worktree** — Keep the main working directory clean
- **This project uses both Minitest (`test/`) and RSpec (`spec/`)** — Check file location
- **DatabaseCleaner** — This project uses DatabaseCleaner, not transactional fixtures
- **Explicit factories** — This project uses explicit factory style with hardcoded IDs; be careful changing them
- **Print PR URL** — Always print the PR URL at the end for automation
- **No permission prompts** — Commit, push, and create PR without asking (except for test deletion/cleanup)
