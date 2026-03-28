# Vault Health Report

Resolve vault path first:
```bash
VAULT=$(grep 'vault_path:' ~/.config/vault/config.yaml | awk '{print $2}')
```

## Report Generation

Run these scans in parallel where possible:

### 1. File Statistics
```bash
echo "Markdown files:" && find "$VAULT" -name '*.md' -not -path '*/.obsidian/*' -not -path '*/_trash/*' | wc -l
echo "Images:" && find "$VAULT" -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.gif' -o -name '*.svg' \) -not -path '*/.obsidian/*' | wc -l
echo "PDFs:" && find "$VAULT" -name '*.pdf' -not -path '*/.obsidian/*' | wc -l
echo "Vault size:" && du -sh "$VAULT" --exclude='.git' 2>/dev/null || du -sh "$VAULT"
```

### 2. Frontmatter Audit
```bash
rg -L '^---' $VAULT --glob '*.md' --glob '!.obsidian/**' --glob '!_trash/**'
```
- Count files missing frontmatter and required fields
- Top 10 most-used tags, tag distribution by category

### 3. Orphan Detection
- Empty files (0-byte .md), orphaned images, broken wikilinks, isolated notes (no inbound links)

### 4. Duplicate Detection
- Identical filenames in different dirs, " 2" suffix dirs, near-duplicate content (>80% similar)

### 5. Vault Growth
- Files created/modified in last 7/30/90 days
- Stale notes: not modified in 6+ months

### 6. Plugin Audit (monthly)
```bash
ls $VAULT/.obsidian/plugins/
```
- List plugins, check for empty dirs (broken installs), flag missing `main.js`, ask about removal

## Report Template

```markdown
# Vault Health Report — {{date}}

## Overview
| Metric | Count |
|--------|-------|
| Total markdown files | |
| Total images | |
| Vault size | |
| Files created (30d) | |
| Files modified (30d) | |

## Health Score: X/100

### Scoring
- Frontmatter compliance: X% (target: 90%+)
- Zero orphaned images: +10 or -5 per 10 orphans
- Zero broken links: +10 or -5 per 10 broken
- No empty files: +5 or -2 per empty
- No duplicate dirs: +10 or -10 if any
- Git backup recent: +10 or -10 if >7 days old

## Issues Found
### Critical (fix now)
### Warning (fix soon)
### Info (nice to have)

## Forgotten Gems
Notes not visited in 6+ months with substantial content (top 5)

## Recommendations

## Behavior Observations
- Note-taking frequency, most active category
- Naming/frontmatter compliance percentages
- Suggestions for improvement
```

## Save Report

Save to `_reports/YYYY-MM-DD-health-report.md` inside vault. Create `_reports/` if needed.

## Behavior Coaching

Track and flag (constructive, not critical):
- Notes without frontmatter → remind about `vault capture`
- Root-level file dumps → suggest proper folder
- Untitled files, tag inconsistency, long backup gaps
