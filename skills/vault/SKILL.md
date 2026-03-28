---
name: vault
description: "Obsidian vault management suite. Use when the user mentions vault, obsidian, notes, knowledge base, or asks to capture notes, clean up, search, organize, backup, get health reports, or AI-analyze their vault. Handles all vault operations via sub-commands: capture, cleanup, health, search, organize, ai, backup. Triggers on /vault, vault capture, vault cleanup, vault health, vault search, vault organize, vault ai, vault backup, or natural language equivalents."
---

# Obsidian Vault Manager

Single skill managing all vault operations at `/Users/przbadu/Documents/Obsidian`.

## Shared Configuration

Read before any operation:
- [Vault Config](references/vault-config.md) — paths, frontmatter standard, folder structure, safety protocol
- [Note Templates](references/note-templates.md) — templates for work, idea, reference, career, learning, personal

## Sub-Commands

Route the user's request and read ONLY the relevant reference file:

| Sub-Command | Reference File | When to Load |
|-------------|---------------|-------------|
| **capture** | [capture.md](references/capture.md) | "add note", "capture", "quick note", "save to vault", "new note" |
| **cleanup** | [cleanup.md](references/cleanup.md) | "clean up", "delete empties", "merge duplicates", "fix links", "orphans" |
| **health** | [health.md](references/health.md) | "health", "report", "stats", "audit", "how is my vault" |
| **search** | [search.md](references/search.md) | "search", "find", "related notes", "forgotten", "summarize", "chat with vault" |
| **organize** | [organize.md](references/organize.md) | "organize", "rename", "move", "batch tag", "MOC", "archive", "wikilinks" |
| **ai** | [ai.md](references/ai.md) | "tag notes", "categorize", "duplicates", "AI", "career progress", "behavior" |
| **backup** | [backup.md](references/backup.md) | "backup", "commit vault", "push vault", "git sync" |

Also read [local-ai-config.md](references/local-ai-config.md) when using AI operations.

## Routing Logic

1. Match the user's intent to a sub-command from the table above
2. Read `vault-config.md` + the matched reference file
3. Follow the instructions in the reference file
4. If ambiguous, ask: "Which vault operation? capture / cleanup / health / search / organize / ai / backup"

## Quick Reference

- Vault path: `/Users/przbadu/Documents/Obsidian`
- Frontmatter: YAML `tags:` array. Required: tags, created, modified, status, category
- File naming: `kebab-case-title.md` or `YYYY-MM-DD_topic-name.md`
- Safety: Git-commit before destructive ops, soft-delete to `_trash/`
- Batch limit: 50 files per operation
- Tools: Obsidian CLI (if running) > direct file ops, `rg` for search
- Local AI: Qwen/Ollama preferred, Claude fallback
