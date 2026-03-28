---
name: vault
description: "Obsidian vault management suite. Use when the user mentions vault, obsidian, notes, knowledge base, or asks to capture notes, clean up, search, organize, backup, get health reports, or AI-analyze their vault. Handles all vault operations via sub-commands: capture, cleanup, health, search, organize, ai, backup, setup. Triggers on /vault, vault capture, vault cleanup, vault health, vault search, vault organize, vault ai, vault backup, vault setup, or natural language equivalents."
---

# Obsidian Vault Manager

## Configuration

All config lives in `~/.config/vault/config.yaml`. Read it at the start of every operation:

```bash
cat ~/.config/vault/config.yaml
```

**Key values to extract:**
- `vault_path` — the Obsidian vault directory (use this everywhere, never hardcode)
- `ai.chat_url`, `ai.embed_url`, `ai.rerank_url` — AI endpoints
- `ai.chat_model`, `ai.embed_model`, `ai.rerank_model` — model names
- `ai_fallback.*` — SSH tunnel fallback URLs

If config file doesn't exist, run the setup wizard (see below).

## Shared References

Read before any operation:
- [Vault Config](references/vault-config.md) — frontmatter standard, folder structure, safety protocol
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
| **setup** | [local-ai-config.md](references/local-ai-config.md) | "vault setup", "configure", "set endpoints", "change vault path" |

## Routing Logic

1. Read `~/.config/vault/config.yaml` to get `vault_path` and AI endpoints
2. Match the user's intent to a sub-command from the table above
3. Read the matched reference file
4. In the reference file, replace any hardcoded vault path with the `vault_path` from config
5. If ambiguous, ask: "Which vault operation? capture / cleanup / health / search / organize / ai / backup / setup"

## First-Time Setup

Run when config file is missing OR user says "vault setup":

1. Check if `~/.config/vault/config.yaml` exists
2. If missing, create `~/.config/vault/` directory
3. Ask these questions one at a time:
   - "Where is your Obsidian vault?" (detect by looking for `.obsidian/` dirs, suggest found paths)
   - "Chat/completion server URL?" (default: `http://192.168.1.150:8080/v1`)
   - "Embedding server URL?" (default: `http://192.168.1.150:8082/v1`)
   - "Re-ranking server URL? (or 'skip')" (default: `http://192.168.1.150:8083/v1`)
4. For each endpoint, test connectivity: `curl -s -o /dev/null -w "%{http_code}" URL/models`
5. If reachable, auto-detect models: `curl -s URL/models | jq -r '.data[].id'`
6. Let user pick models (or accept auto-detected defaults)
7. Write `~/.config/vault/config.yaml` (confirm before writing)
8. Show summary of what was configured

## Quick Reference

- Config: `~/.config/vault/config.yaml`
- Frontmatter: YAML `tags:` array. Required: tags, created, modified, status, category
- File naming: `kebab-case-title.md` or `YYYY-MM-DD_topic-name.md`
- Safety: Git-commit before destructive ops, soft-delete to `_trash/`
- Batch limit: 50 files per operation
- Tools: Obsidian CLI (if running) > direct file ops, `rg` for search
- Local AI: Local models preferred, Claude fallback
