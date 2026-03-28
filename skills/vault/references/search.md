# Vault Search

Search the vault at `/Users/przbadu/Documents/Obsidian`.

## Search Methods (priority order)

### 1. Ripgrep (fastest, default)
```bash
rg -i "QUERY" /Users/przbadu/Documents/Obsidian --glob '*.md' --glob '!.obsidian/**' --glob '!_trash/**' -l
rg -i "QUERY" /Users/przbadu/Documents/Obsidian --glob '*.md' --glob '!.obsidian/**' -C 3
rg "tags:.*TAGNAME" /Users/przbadu/Documents/Obsidian --glob '*.md' -l
```

### 2. Obsidian CLI (if available)
```bash
obsidian search "QUERY" --vault /Users/przbadu/Documents/Obsidian 2>/dev/null
```
Fall back to ripgrep if unavailable.

### 3. Semantic Search (local embeddings)
Check local API: `curl -s http://localhost:11434/api/tags 2>/dev/null || curl -s http://localhost:8000/v1/models 2>/dev/null`
If available, use for meaning-based queries. Otherwise ripgrep with synonyms.

## Commands

### Find Notes
Search by keyword/phrase. Return file paths, matching lines, sorted by match count. Top 20.

### Related Notes
1. Read source note, extract key concepts (title, tags, links)
2. Search vault for those concepts
3. Rank by overlap (shared tags > shared links > keyword matches)
4. Return top 10 with relevance explanation

### Summarize
1. Find all notes matching folder/tag (max 50)
2. Generate summary: key themes, notable entries, gaps, connections
3. Optionally create summary note (ask first)

### Forgotten Gems
```bash
find /Users/przbadu/Documents/Obsidian -name '*.md' -not -path '*/.obsidian/*' -not -path '*/_trash/*' -mtime +180 -size +500c
```
Read sample of old notes, highlight actionable content. Suggest: revisit, archive, or link.

### Chat with Vault
1. Parse question → extract topics
2. Search vault (rg + tag search), read top 5-10 notes
3. Synthesize answer citing notes: "Based on [[Note Title]], ..."
4. Suggest follow-up questions

## Output Format

```
## Search Results for "query"
Found X matches in Y files

1. **[[Note Title]]** — `path/to/note.md`
   > Matching context line...
   Tags: [tag1, tag2] | Category: X | Modified: YYYY-MM-DD
```

## Performance
- Exclude `.obsidian/`, `.git/`, `_trash/`, `_orphaned/`
- Use `rg -l` for initial scan, read top results
- Paginate large results (20 at a time)
