# Claude Code Skills

A collection of modular, specialized AI skills that extend Claude Code's capabilities with domain-specific knowledge, workflows, and tool integrations.

## Available Skills

| Skill | Description |
|-------|-------------|
| **agent-browser** | Browser automation CLI for AI agents (navigate, fill forms, click, screenshot, scrape) |
| **algorithmic-art** | Create generative algorithmic art using p5.js |
| **commit** | Git commits from staged changes with confirmation |
| **brand-guidelines** | Anthropic brand colors, typography, and styling |
| **canvas-design** | Create visual art and designs in PNG and PDF |
| **doc-coauthoring** | Structured workflow for collaborative documentation |
| **docx** | Word document creation, editing, and analysis |
| **git-worktree** | Manage git worktrees for parallel development (create, list, cleanup) |
| **frontend-design** | Production-grade frontend interfaces with React/HTML/CSS |
| **internal-comms** | Internal communication templates (updates, newsletters, FAQs) |
| **mcp-builder** | Guide for building Model Context Protocol (MCP) servers |
| **pdf** | PDF processing: merge, split, extract, fill forms, OCR |
| **pptx** | PowerPoint presentation creation and editing |
| **skill-creator** | Meta-skill for creating new skills |
| **slack-gif-creator** | Create animated GIFs optimized for Slack |
| **theme-factory** | Apply professional themes to artifacts |
| **web-artifacts-builder** | Build complex claude.ai HTML artifacts with React/Tailwind |
| **webapp-testing** | Playwright-based web app testing toolkit |
| **xlsx** | Excel/spreadsheet creation, analysis, and editing |

## Prerequisites

Most skills work out of the box with Claude Code. Some skills require external tools to be installed first.

### agent-browser

The **agent-browser** skill requires the `agent-browser` CLI to be installed. Choose one of the following methods:

**NPM (Recommended)**

```bash
npm install -g agent-browser
agent-browser install  # Downloads Chromium
```

**Homebrew (macOS)**

```bash
brew install agent-browser
agent-browser install  # Downloads Chromium
```

**From Source**

```bash
git clone https://github.com/vercel-labs/agent-browser
cd agent-browser
pnpm install
pnpm build
pnpm build:native  # Requires Rust (https://rustup.rs)
pnpm link --global
agent-browser install
```

**Linux users** — install system dependencies with:

```bash
agent-browser install --with-deps
```

### git-worktree

The **git-worktree** skill requires no extra installation — it uses git's built-in worktree support. Just make sure you have **git 2.5+** installed.

**Usage examples in Claude Code:**

```
# Create a worktree for a new feature
> create a worktree for feature/user-auth

# List existing worktrees
> show my worktrees

# Clean up worktrees whose branches have been merged
> clean up worktrees
```

Worktrees are created under `.worktrees/` in your repo root and automatically added to `.gitignore`.

## Installation

Claude Code discovers skills automatically from `~/.claude/skills/`.

```bash
# Clone the repo (if you haven't already)
git clone <repo-url> ~/dev/skills
```

### Install all skills

Symlink the entire repo as your global skills directory so all skills are available across every project:

```bash
ln -s ~/dev/skills ~/.claude/skills
```

### Install a single skill

```bash
mkdir -p ~/.claude/skills
ln -s ~/dev/skills/pdf ~/.claude/skills/pdf
```

### Verify installation

Open Claude Code and type `/` — your installed skills will appear in the autocomplete list. You can invoke any skill directly (e.g., `/pdf`, `/docx`) or let Claude use them automatically based on your request.

## Creating a New Skill

Use the skill-creator to scaffold a new skill:

```bash
python skill-creator/scripts/init_skill.py <skill-name> --path <output-directory>
```

See the [skill-creator SKILL.md](skill-creator/SKILL.md) for the full authoring guide.
