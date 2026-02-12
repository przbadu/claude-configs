---
name: github-autopilot
description: >
  End-to-end development autopilot driven by GitHub issue links. When a user
  shares a GitHub issue URL (e.g., https://github.com/org/repo/issues/123),
  this skill fetches the issue, generates a PRD using task-master templates,
  parses it into tasks, analyzes complexity, expands subtasks, then iteratively
  implements each task with validation and code review. Triggers on sharing a
  GitHub issue link with intent to implement, "autopilot this issue",
  "implement this issue", "/github-autopilot", "work on this GitHub issue",
  or any request to autonomously implement a GitHub issue end-to-end.
---

# GitHub Autopilot

Autonomous development workflow: GitHub issue -> PRD -> Tasks -> Implementation -> Validation -> Next task.

## Workflow

### Phase 1: Fetch & Analyze the GitHub Issue

Extract the issue number and repo from the URL, then fetch full details:

```bash
gh issue view <number> --json title,body,labels,comments,assignees
```

Classify the issue by complexity to select the PRD template:

| Signal | Simple (standard PRD) | Complex (RPG PRD) |
|---|---|---|
| Labels | `bug`, `typo`, `hotfix`, `chore` | `feature`, `enhancement`, `epic`, `refactor` |
| Body length | < 500 chars | > 500 chars |
| Mentions multiple models/services | No | Yes |
| Has acceptance criteria list | < 3 items | >= 3 items |
| Requires migration | No | Yes |

**Default**: Use standard template. Only use RPG template when 2+ complex signals are present.

### Phase 2: Generate the PRD

Create the PRD file at `.taskmaster/docs/prd-<issue_number>.md`.

**For standard template** (simple bugs, small features, chores):

Use the structure from `.taskmaster/templates/example_prd.txt`:
- `<context>` section: Overview, Core Features, User Experience — populated from issue body
- `<PRD>` section: Technical Architecture, Development Roadmap, Logical Dependency Chain, Risks

**For RPG template** (complex features, multi-service changes, epics):

Use the structure from `.taskmaster/templates/example_prd_rpg.txt`:
- Overview with Problem Statement, Target Users, Success Metrics
- Functional Decomposition (capabilities -> features with inputs/outputs/behavior)
- Structural Decomposition (mapping capabilities to code locations)
- Dependency Graph (explicit module dependencies by layer/phase)
- Implementation Roadmap (phased tasks with entry/exit criteria)
- Test Strategy
- Architecture decisions

**PRD writing rules:**
1. Title the PRD: `# PRD: #{issue_number} - {issue_title}`
2. Ground all technical details in the actual codebase — read relevant files before writing
3. Use the project's conventions from CLAUDE.md (service objects, Pundit policies, RSpec tests, etc.)
4. Include test strategy aligned with existing patterns
5. Keep scope tight to the issue — no scope creep

### Phase 3: Parse PRD into Tasks

```bash
task-master parse-prd .taskmaster/docs/prd-<issue_number>.md --append
```

This generates tasks in `.taskmaster/tasks/tasks.json`. The `--append` flag adds to existing tasks.

### Phase 4: Analyze Complexity & Expand

```bash
# Analyze complexity of newly created tasks
task-master analyze-complexity --research

# View the complexity report
task-master complexity-report

# Expand tasks that need subtasks
task-master expand --all --research
```

### Phase 5: Implementation Loop

Repeat until all tasks from this issue are done:

#### 5a. Pick next task

```bash
task-master next
```

If the returned task is not from this issue's PRD, use `task-master list` to find the right one.

#### 5b. Start the task

```bash
task-master set-status --id=<id> --status=in-progress
task-master show <id>
```

#### 5c. Implement

1. **Explore**: Read relevant source files, understand existing patterns
2. **Plan**: Log the implementation approach:
   ```bash
   task-master update-subtask --id=<id> --prompt="Implementation plan: ..."
   ```
3. **Code**: Write the implementation following project conventions (service objects, Pundit policies, RSpec tests, concurrent indexes with `disable_ddl_transaction!`, etc.)
4. **Test**: Run relevant tests:
   ```bash
   bundle exec rspec <spec_file>
   bundle exec rails test <test_file>
   ```

#### 5d. Validate

1. **Tests pass**: Run relevant specs/tests
2. **Linting**: `bundle exec rubocop <changed_files>`
3. **No N+1 queries**: Verify `includes`/`eager_load` usage
4. **Strong migrations**: Verify `disable_ddl_transaction!` and `algorithm: :concurrently` if applicable

#### 5e. Log & complete

```bash
task-master update-subtask --id=<id> --prompt="Completed: <summary of changes>"
task-master set-status --id=<id> --status=done
```

#### 5f. Next iteration

Loop back to step 5a.

### Phase 6: Final Review & Commit

After all tasks are done:

1. Run full test suite on changed areas
2. Run rubocop on all changed files
3. Create git branch: `issues/<issue_number>`
4. Commit with proper format:
   ```
   type(scope): #<issue_number> descriptive title

   - What changed
   - Why it changed

   Closes #<issue_number>
   ```
5. Offer to create a PR

## Template Selection Reference

See [references/template-guide.md](references/template-guide.md) for detailed PRD template examples and customization patterns.

## Notes

- Always fetch the GitHub issue fresh — do not assume content from the URL alone
- Always read relevant codebase files before writing PRD technical sections
- Use `--append` when parsing PRDs to avoid overwriting existing tasks
- If a task is blocked, mark it `blocked` and move to the next one
- Prefer small, focused commits over one large commit
