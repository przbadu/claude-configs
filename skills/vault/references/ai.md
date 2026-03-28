# AI-Powered Vault Operations

Resolve vault path first:
```bash
VAULT=$(grep 'vault_path:' ~/.config/vault/config.yaml | awk '{print $2}')
```

## Local AI Configuration
See [local-ai-config.md](local-ai-config.md) for setup. Prefer local models. Fall back to Claude if unavailable.
Check: `curl -s -o /dev/null -w "%{http_code}" http://localhost:11434/api/tags 2>/dev/null`

## Operations

### 1. Auto-Tag
Analyze content, suggest tags from existing vault tags. Ask before new tags.
```bash
rg -o 'tags: \[.*?\]' $VAULT --glob '*.md' --no-filename | tr ',' '\n' | sed 's/.*\[//;s/\]//;s/^ *//' | sort -u
```
Batch: up to 50 untagged notes, show table for bulk approval.

### 2. Auto-Categorize
Analyze content → determine category → map to folder → present plan → confirm → execute.

### 3. Duplicate Detection
1. Build summaries (title + first 200 chars + tags)
2. Compare for similarity, full comparison for candidates
3. Present pairs with score and diff — NEVER auto-merge, user confirms
4. Merge: combine unique content, move dupe to `_trash/`

Quick scan: `find ... -name '*.md' | xargs basename -a | sort | uniq -di`

### 4. Summarize Notes
- **Single note:** 2-3 sentences
- **Folder:** Thematic summary (max 50 notes)
- **Topic:** Search by tag, synthesize insights
- **Backlink summary:** Find notes linking TO a note, summarize what they say

Optionally save as new note (ask first).

### 5. Chat with Vault
1. Parse question → extract topics
2. Search: `rg -i "topic1|topic2" --glob '*.md' -l` + tag search
3. Read top 10 notes, synthesize with citations: "According to [[Note Title]], ..."
4. List sources, suggest follow-ups

### 6. Career Tracking
1. Read `AI-Career-Levelup/` files
2. Extract goals, milestones, deadlines
3. Compare against recent notes/topics studied
4. Report: active skills, overdue milestones (flagged), next steps
5. Cross-reference with `genai-bootcamp/` learning notes

### 7. Behavior Coaching
Track: notes/week, frontmatter compliance, naming compliance, root dumps, tags/note, wikilink usage.
Constructive feedback: "8 of 15 recent notes missing frontmatter. Try `vault capture` for automatic frontmatter."

## Model Selection
1. **Local Qwen/Ollama** (preferred): tagging, categorization, summarization
2. **Claude (current session)**: complex analysis, career, chat
3. Check local first, fall back gracefully

## Batch: max 50 notes, show progress, git-commit after each batch
