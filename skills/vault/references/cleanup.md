# Vault Cleanup

Resolve vault path first:
```bash
VAULT=$(grep 'vault_path:' ~/.config/vault/config.yaml | awk '{print $2}')
```

## Safety Protocol (MANDATORY)

Before ANY destructive operation:
1. `cd $VAULT && git add -A && git commit -m "vault: safety checkpoint before cleanup"`
2. Use `_trash/` for soft deletes (never hard-delete user content)
3. Max 50 files per batch — show progress between batches

## Cleanup Operations

### 1. Empty Files
```bash
find $VAULT -name '*.md' -empty -not -path '*/.obsidian/*' -not -path '*/_trash/*'
```
- 0-byte files → move to `_trash/`
- Files with only whitespace → move to `_trash/`
- Files with minimal content but a real title → move to `_inbox/` for review

### 2. Empty Directories
```bash
find $VAULT -type d -empty -not -path '*/.obsidian/*' -not -path '*/.git/*' -not -path '*/_trash/*'
```
- Auto-delete empty directories (no confirmation needed)

### 3. Duplicate " 2" Directories
Known duplicate pairs in `second-brain/`:
- `inbox` + `inbox 2`, `notes` + `notes 2`, `AI` + `AI 2`, `AI Composer` + `AI Composer 2`
- `AI Sass Business Ideas` + `AI Sass Business Ideas 2`, `blogs` + `blogs 2`
- `assets` + `assets 2`, `NLP` + `NLP 2`, `00 OpenWebUI` + `00 OpenWebUI 2`
- `Habit Tracker 2` (empty), `Archive 2` (empty)

**Merge procedure:**
1. Compare files in both directories (byte-level: `diff -rq dir1 dir2`)
2. If " 2" has unique files not in original → copy them to original
3. If all files are identical or subset → delete " 2" directory
4. Report what was merged/deleted

### 4. Orphaned Images
```bash
find $VAULT -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.gif' -o -name '*.svg' -o -name '*.webp' \) -not -path '*/.obsidian/*' -not -path '*/_trash/*' -not -path '*/_orphaned/*'
```
- Check each image against markdown references: `rg -l 'IMAGE_FILENAME' --glob '*.md'`
- Unreferenced images → move to `_orphaned/`
- Show count and total size before moving, confirm before executing

### 5. Broken Wikilinks
```bash
rg -o '\[\[([^\]|]+)' $VAULT --glob '*.md' --no-filename -r '$1' | sort -u
```
- For each link target, check if a matching .md file exists
- Report broken links with source file and line number
- Offer to: (a) create stub note, (b) remove the link, (c) fix typo if close match exists

### 6. Sync Conflicts
```bash
find $VAULT -name '*.sync-conflict-*' -not -path '*/_trash/*'
```
- For each conflict file, find the original
- Show diff between conflict and original
- Ask user which to keep (do NOT auto-resolve — user decides)

### 7. System Junk
- `.DS_Store` files → delete all
- Update `.gitignore` to include: `*.DS_Store`, `*.sync-conflict-*`

## Interactive Mode

When invoked without specific args, run a full scan and present a dashboard:

```
Vault Cleanup Report
====================
Empty files:        7 found
Empty directories:  18 found
Duplicate dirs:     11 " 2" pairs
Orphaned images:    ~50 unreferenced
Broken wikilinks:   [scan needed]
Sync conflicts:     4 files
System junk:        [scan needed]

Which to clean? (all / pick numbers / skip)
```

Process user's selection in order. Git-commit after each category.

## Post-Cleanup

1. `cd $VAULT && git add -A && git commit -m "vault: cleanup — [summary]"`
2. Show before/after file counts
3. Suggest running `vault health` for a full report
