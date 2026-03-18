---
name: git-worktree
description: |
  Manage git worktrees for parallel development. Use when the user wants to
  create a new worktree, work on a feature in a separate worktree, list
  existing worktrees, clean up merged worktrees, or any variation of
  "new worktree", "parallel branch", "worktree for feature X".
  Triggers on requests like "create a worktree", "start a new feature in a
  worktree", "show my worktrees", "clean up worktrees", or "I want to work
  on X in parallel".
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Git Worktree Slot Management

Manage git worktrees with deterministic port assignment for parallel development across po-app (Rails) and po-app-gfo (React).

## Port Convention

| Slot | Rails Port | Vite Port | ActionCable                  |
|------|-----------|-----------|------------------------------|
| Main | 3000      | 3001      | ws://localhost:3000/cable     |
| 1    | 3010      | 3011      | ws://localhost:3010/cable     |
| 2    | 3020      | 3021      | ws://localhost:3020/cable     |
| 3    | 3030      | 3031      | ws://localhost:3030/cable     |
| 4    | 3040      | 3041      | ws://localhost:3040/cable     |
| 5    | 3050      | 3051      | ws://localhost:3050/cable     |

## Slot Management Commands

All commands use the bundled script. Run from any directory — it auto-detects po-app and po-app-gfo:

```bash
bash <skill-path>/scripts/worktree-slot.sh <command> [args]
```

You can also override project directories:
```bash
POAPP_DIR=/path/to/po-app GFO_DIR=/path/to/po-app-gfo bash <skill-path>/scripts/worktree-slot.sh <command>
```

### Commands

| Command | Purpose |
|---------|---------|
| `create <slot> <branch>` | Create worktree pair + config files + update registry |
| `remove <slot>` | Stop processes, remove worktrees, update registry |
| `start <slot> [--frontend]` | Start puma on slot's port (foreground). `--frontend` starts vite instead |
| `stop <slot>` | Kill processes on slot's ports |
| `list` | Show all slots with status (port, branch, running?) |
| `info <slot>` | Detailed info for one slot |

### Examples

```bash
# Create slot 1 for a feature branch
bash <skill-path>/scripts/worktree-slot.sh create 1 issues/23300

# List all active slots
bash <skill-path>/scripts/worktree-slot.sh list

# Start Rails server (port 3010)
bash <skill-path>/scripts/worktree-slot.sh start 1

# Start Vite dev server (port 3011) — run in separate terminal
bash <skill-path>/scripts/worktree-slot.sh start 1 --frontend

# Stop all processes for a slot
bash <skill-path>/scripts/worktree-slot.sh stop 1

# Remove slot (stops processes, removes worktrees, cleans registry)
bash <skill-path>/scripts/worktree-slot.sh remove 1
```

## Workflow: Creating a Slot

1. **Find an available slot**: Read `~/.claude/worktree-slots.json` or run the `list` command
2. **Create the slot**: Run `create <slot> <branch>`
   - Creates Rails worktree at `po-app/.worktrees/slot-N--branch-name`
   - Creates frontend worktree at `po-app-gfo/.worktrees/slot-N--branch-name` (falls back to `main` if branch doesn't exist)
   - Copies and extends `config/application.yml` with slot-specific PORT and APP_HOST
   - Writes `.env.local` in frontend worktree with VITE_PORT and VITE_BACKEND_URL
   - Runs `bundle install` and `npm install`
3. **Start servers**: Run `start <slot>` for Rails, `start <slot> --frontend` for Vite

## Workflow: During Development

- **Rails work directory**: `po-app/.worktrees/slot-N--branch-name/`
- **Frontend work directory**: `po-app-gfo/.worktrees/slot-N--branch-name/`
- **Run tests**: `cd <worktree-path> && bundle exec rails test` or `bundle exec rspec`
- **API endpoint**: `http://localhost:<rails-port>/api/v1/...`
- **Frontend**: `http://localhost:<vite-port>`

## Workflow: Completing a Task

1. Run tests in the worktree to verify changes
2. Create a PR from the worktree branch
3. Report the PR URL and port info to the user
4. After merge: run `remove <slot>` to clean up

## Registry

The slot registry lives at `~/.claude/worktree-slots.json`. Read it to find:
- Available slot numbers (1-5)
- Worktree paths for each slot
- Port assignments
- Branch names

## Simple Worktree Commands (non-slot)

For quick worktrees without port management:

```bash
# Create a worktree
bash <skill-path>/scripts/create-worktree.sh <branch-name> [base-branch]

# List all worktrees
git worktree list

# Clean up merged worktrees
bash <skill-path>/scripts/cleanup-worktrees.sh
```

## Important Notes

- **Sidekiq**: Runs ONLY from the main repo. All slots share the same Redis and database.
- **Database**: Shared across all slots. Migrations in one worktree affect all.
- **ENV**: Managed via Figaro (`config/application.yml`) — each worktree gets its own copy with slot-specific overrides.
- **Frontend ENV**: `.env.local` files (gitignored via `*.local` pattern) in each frontend worktree.
- **Worktree location**: Always under `<repo>/.worktrees/` (already gitignored in both repos).
- **jq required**: The management script requires `jq` for JSON registry manipulation.
- Always run worktree commands from the main repo root, not from inside a worktree.
- Never delete a worktree without checking if its branch is merged first.
- If the user asks to "remove" or "delete" a specific worktree, use `git worktree remove <path>` and confirm with the user before deleting the branch.
