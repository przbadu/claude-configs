# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A collection of modular, specialized AI skills and hooks that extend Claude's capabilities with domain-specific knowledge, workflows, and tool integrations. Each skill is self-contained and follows a standardized structure. This is not a traditional software project with builds or tests — it is a documentation and reference repository for AI skills and hooks.

## Hooks

Version-controlled Claude Code hooks live in `hooks/`. They are symlinked to `~/.claude/hooks/` so `settings.json` can reference them by path. Hooks must be registered in `~/.claude/settings.json` to be active. See README.md for setup instructions.

| Hook | Event | Description |
|------|-------|-------------|
| `on-stop.sh` | Stop | Text-to-speech readout of last assistant message (macOS `say`) |

## Skill Structure

Every skill follows this layout:

```
skill-name/
├── SKILL.md              # Core documentation with YAML frontmatter (required)
├── LICENSE.txt            # License file
├── scripts/              # Executable helper scripts (Python/JS/Bash)
├── references/           # Supplementary docs loaded on demand
└── assets/               # Templates, fonts, boilerplate code
```

SKILL.md files require YAML frontmatter with `name` and `description` fields.

## Key Commands

### Skill Creation & Validation

```bash
# Initialize a new skill
python3 skill-creator/scripts/init_skill.py <skill-name> --path <output-directory>

# Package a skill (validates automatically)
python3 skill-creator/scripts/package_skill.py <path/to/skill-folder>
```

### Per-Skill Helper Scripts

Skills with complex operations provide helper scripts in their `scripts/` directory. Examples:

```bash
python pdf/scripts/extract_form_structure.py
python pptx/scripts/add_slide.py
python xlsx/scripts/recalc.py
bash web-artifacts-builder/scripts/init-artifact.sh
bash web-artifacts-builder/scripts/bundle-artifact.sh
```

### Web App Testing (Playwright)

```bash
python scripts/with_server.py --server "npm run dev" --port 5173 -- python automation.py
```

## Architecture

### Progressive Disclosure Model

Skills use a three-tier loading strategy to minimize token usage:

1. **Metadata** (YAML frontmatter) — always visible for routing (~100 words)
2. **SKILL.md body** — loaded when the skill is triggered (<5k words)
3. **References/assets** — loaded on demand as Claude needs them

### Shared Utilities

Office-format skills (docx, pptx, xlsx) share common utilities in their `scripts/office/` subdirectories for XML-level document manipulation (unpack, pack, validate).

### Skill Categories

| Category | Skills |
|----------|--------|
| **Office docs** | docx, pptx, xlsx, pdf |
| **Visual/creative** | algorithmic-art, canvas-design, frontend-design, theme-factory, slack-gif-creator |
| **Development** | agent-browser, mcp-builder, web-artifacts-builder, webapp-testing |
| **Git workflow** | commit, git-worktree, github-pr, github-autopilot |
| **Production ops** | perf-monitor, airbrake-fixer, pr-review-fixer, bug-crusher |
| **Writing/process** | doc-coauthoring, internal-comms, skill-creator, brand-guidelines |

## Design Principles for Skills

- **Concise**: Only include what Claude doesn't already know
- **No redundancy**: Information belongs in SKILL.md OR reference files, not both
- **Appropriate specificity**: Match the degree of freedom to how fragile the task is — tightly constrain error-prone operations, leave creative tasks open
- **Progressive loading**: Reference files should be linked from SKILL.md with clear guidance on when to load them
