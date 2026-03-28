# Vault Configuration

## Paths

- **Vault root**: `/Users/przbadu/Documents/Obsidian`
- **Trash folder**: `_trash/` (inside vault root)
- **Orphaned images**: `_orphaned/` (inside vault root)
- **Inbox**: `_inbox/` (for notes needing review/categorization)

## Folder Structure

| Directory | Purpose | Content Type |
|-----------|---------|-------------|
| `ProcurementExpress/` | Work — freelance client | Meetings, tasks, audits, wiki, specs |
| `ProcurementExpress/wiki/` | Work knowledge base | Technical docs, processes |
| `AI-Career-Levelup/` | Career development | Skills roadmap, action plans, research |
| `genai-bootcamp/` | GenAI learning | Numbered curriculum (000-008+) |
| `second-brain/` | General knowledge | AI, ML, NLP, blogs, personal notes |
| `second-brain/notes/` | Technical references | Dev setup guides, postgres, rails |
| `second-brain/AI/` | AI/ML notes | Models, tools, concepts |
| `second-brain/blogs/` | Blog drafts & articles | Writing, published posts |
| `second-brain/inbox/` | Unsorted captures | Needs categorization |
| `second-brain/assets/` | Images & attachments | Screenshots, diagrams |
| `daily-dose-of-ds/` | Data science learning | Books, newsletters, vector DBs |
| `Proxmox/` | Home server | Setup, benchmarks, config |
| `Ai-Design/` | AI design | Prompts, design resources |
| `ideas/` | Idea collection | Business, projects, experiments |
| `_trash/` | Soft delete | Files pending permanent deletion |
| `_orphaned/` | Orphaned images | Unreferenced image files |
| `_inbox/` | Review queue | Untitled/uncategorized notes |

## Frontmatter Standard

Use YAML frontmatter with `tags:` array (not inline `#tags`). All notes MUST have frontmatter.

### Required Fields

```yaml
---
tags: [topic, subtopic]
created: YYYY-MM-DD
modified: YYYY-MM-DD
status: draft | active | review | archived
category: work | learning | idea | reference | personal | career
---
```

### Optional Fields (add when relevant)

```yaml
source: "URL or book title"
references: ["[[Related Note]]", "[[Another Note]]"]
project: "ProcurementExpress"  # for work notes
author: "name"
```

### Field Guidelines

- **tags**: Use lowercase, hyphenated. Max 5 tags per note. Prefer existing tags over new ones.
- **created**: Set once on creation, never change.
- **modified**: Update on every edit.
- **status**: `draft` (incomplete), `active` (current/useful), `review` (needs attention), `archived` (outdated but kept).
- **category**: One of the 6 values above. Determines target folder.

## File Naming

- New files: `kebab-case-title.md`
- Dated files: `YYYY-MM-DD_topic-name.md`
- Never use spaces in filenames (use hyphens)
- Never use "Untitled" — always name meaningfully

## Category-to-Folder Mapping

| Category | Primary Target |
|----------|---------------|
| work | `ProcurementExpress/` |
| learning | `genai-bootcamp/` or `daily-dose-of-ds/` or `second-brain/` based on topic |
| idea | `ideas/` |
| reference | `second-brain/notes/` |
| personal | `second-brain/` |
| career | `AI-Career-Levelup/` |

## Wikilinks Convention

- Use `[[Note Title]]` to link related notes
- Use `[[Note Title|Display Text]]` for custom display
- Use `![[image.png]]` for image embeds
- Suggest wikilinks when a known note title appears in content — confirm before inserting

## Batch Limits

- Max 50 files per operation (cleanup, tagging, etc.)
- Show progress after each batch
- Always git-commit before destructive operations

## Safety Protocol

1. Git-commit current state before any destructive operation
2. Move files to `_trash/` instead of deleting (soft delete)
3. Confirm before merging duplicates
4. Show diffs for sync conflict resolution
5. Never modify `.obsidian/` directory contents
