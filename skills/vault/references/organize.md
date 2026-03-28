# Vault Organize

Resolve vault path first:
```bash
VAULT=$(grep 'vault_path:' ~/.config/vault/config.yaml | awk '{print $2}')
```
Git-commit before file moves/renames. Batch limit: 50 files per operation.

## Operations

### 1. Reorganize Files
Move misplaced files to correct folders based on content and category.
1. Scan for misplaced files (root orphans, wrong category folder)
2. Read frontmatter and content, determine correct folder
3. Present move plan: `source → destination`, confirm, execute, update wikilinks, git-commit

Root-level files: `find $VAULT -maxdepth 1 -name '*.md' -not -name 'CLAUDE.md'`

### 2. Rename Files
Standardize to kebab-case. Convert spaces to hyphens, lowercase. Preserve date prefixes. Update all wikilinks. Confirm before batch rename.

### 3. Batch Tag Operations
- `add tag <tag> to <folder-or-glob>`
- `remove tag <tag> from <folder-or-glob>`
- `replace tag <old> with <new> in <scope>`

Parse YAML frontmatter, modify `tags:` array, update `modified:` date, preserve content.

### 4. Generate MOC (Map of Content)
**Per-directory:** Create `_MOC.md` inside directory with links to all notes.
**Per-topic:** Search by tag, group by subfolder/date, create `second-brain/moc-TOPIC.md`.
Add frontmatter: `tags: [moc], category: reference, status: active`.

### 5. Archive Management
- `archive <file>` → Move to `second-brain/Archive/`, set `status: archived`, add `archived_from: original/path`
- `unarchive <file>` → Move back, set `status: active`
- `list archived` → Show all archived notes

### 6. Wikilink Suggestions
1. Build index of note titles: `find ... -name '*.md' | xargs -I{} basename {} .md | sort -u`
2. Search note content for title matches, exclude already-wrapped `[[]]`
3. Present suggestions with file, line, proposed link. User confirms.

### 7. Frontmatter Enforcement
1. Find notes without frontmatter: `rg -L '^---' --glob '*.md'`
2. Infer category (folder), tags (content), dates (git/file)
3. Ask before adding NEW tags. Prepend frontmatter. Batch 50, then pause.

## Post-Operation
1. Git-commit: `vault: organize — [summary]`
2. Show files affected count
