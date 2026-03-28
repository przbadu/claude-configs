# Vault Backup

Git-based backup for the vault at `/Users/przbadu/Documents/Obsidian`.

## Operations

### Quick Backup (default)
```bash
cd /Users/przbadu/Documents/Obsidian
git add -A && git status --short && git commit -m "vault: backup $(date +%Y-%m-%d_%H:%M)"
```
If remote configured: `git push origin main`

### Safety Checkpoint
Called by other vault operations before destructive actions:
```bash
cd /Users/przbadu/Documents/Obsidian
git add -A && git commit -m "vault: safety checkpoint before [operation-name]" --allow-empty
```

### Status Check
```bash
cd /Users/przbadu/Documents/Obsidian
echo "=== Uncommitted Changes ===" && git status --short
echo "=== Last 5 Commits ===" && git log --oneline -5
echo "=== Last Backup ===" && git log -1 --format='%cr'
```

### Gitignore Management
Ensure `.gitignore` includes:
```
*.DS_Store
.sync-conflict-*
_trash/
_orphaned/
.obsidian/workspace.json
.obsidian/workspace-mobile.json
```

## Workflow
1. Check `.gitignore`, `git status`, stage all, generate commit message, commit
2. Push if remote configured and user approves
3. Report: commit hash, files changed, time since last backup

## Commit Format
```
vault: <action> — <summary>
vault: backup — 3 new notes, 7 modified
vault: safety checkpoint before cleanup
```

## Scheduled Backup
Compatible with `/schedule` or `/loop`. Skip silently if no changes. Log to `_reports/backup-log.md`.

## Remote
Never force-push. If push fails, alert user. If no remote: `git remote add origin <url>`.
