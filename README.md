# Claude Code Skills & Hooks

A collection of modular, specialized AI skills and hooks that extend Claude Code's capabilities with domain-specific knowledge, workflows, and tool integrations.

## Available Skills

| Skill | Description |
|-------|-------------|
| **agent-browser** | Browser automation CLI for AI agents (navigate, fill forms, click, screenshot, scrape) |
| **bug-crusher** | Triage, rank, and fix GitHub bug tickets by complexity and AI-fixability scoring |
| **airbrake-fixer** | Triage and fix production Airbrake errors via Chrome, create PRs automatically |
| **algorithmic-art** | Create generative algorithmic art using p5.js |
| **brand-guidelines** | Anthropic brand colors, typography, and styling |
| **canvas-design** | Create visual art and designs in PNG and PDF |
| **commit** | Git commits from staged changes with confirmation |
| **doc-coauthoring** | Structured workflow for collaborative documentation |
| **docx** | Word document creation, editing, and analysis |
| **frontend-design** | Production-grade frontend interfaces with React/HTML/CSS |
| **git-worktree** | Manage git worktrees for parallel development (create, list, cleanup) |
| **github-autopilot** | End-to-end development autopilot: GitHub issue -> PRD -> tasks -> implementation -> PR |
| **github-pr** | Create or find GitHub pull requests and open in browser |
| **internal-comms** | Internal communication templates (updates, newsletters, FAQs) |
| **mcp-builder** | Guide for building Model Context Protocol (MCP) servers |
| **pdf** | PDF processing: merge, split, extract, fill forms, OCR |
| **perf-monitor** | Daily production performance monitoring, diagnosis, and auto-fix via Chrome (New Relic, Logtails, PGHero, Airbrake) |
| **pptx** | PowerPoint presentation creation and editing |
| **pr-review-fixer** | Review and fix GitHub PR code review comments |
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

### bug-crusher

The **bug-crusher** skill requires the `gh` CLI to be installed and authenticated. It fetches open issues labeled "Bug" from your GitHub repo, scores them for complexity and AI-fixability, and orchestrates fixes using git worktrees and PRs.

```
# Triage and rank all open bugs
> crush bugs

# Auto-fix mode: work through top-priority bugs
> fix bugs in auto mode
```

On first run, it asks for your GitHub repo URL and target bug count, then stores config in project memory for future sessions.

### github-autopilot

The **github-autopilot** skill requires the `gh` CLI and [task-master](https://github.com/task-master-ai/task-master) to be installed. It takes a GitHub issue URL and autonomously generates a PRD, parses it into tasks, and implements them.

```
# Implement a GitHub issue end-to-end
> autopilot https://github.com/org/repo/issues/123
```

It selects a standard or RPG-style PRD template based on issue complexity signals (labels, body length, acceptance criteria count). Task files are stored in `.taskmaster/`.

### perf-monitor

The **perf-monitor** skill requires Chrome browser automation enabled (`--chrome` flag or chrome enabled in Claude Code settings). You must be logged into New Relic, Logtails, PGHero, and Airbrake in Chrome. On first run, it will ask for your dashboard URLs and store them in project memory for future use.

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

## Available Hooks

| Hook | Event | Description |
|------|-------|-------------|
| **on-stop.sh** | Stop | Reads the last assistant message aloud using macOS `say` (text-to-speech) |

## Installation

Claude Code discovers skills from `~/.claude/skills/` and hooks from `~/.claude/hooks/`.

```bash
# Clone the repo (if you haven't already)
git clone <repo-url> ~/dev/claude-configs
```

### Install skills

Symlink the entire skills directory so all skills are available across every project:

```bash
ln -s ~/dev/claude-configs/skills ~/.claude/skills
```

To install a single skill instead:

```bash
mkdir -p ~/.claude/skills
ln -s ~/dev/claude-configs/skills/pdf ~/.claude/skills/pdf
```

### Install hooks

Symlink the hooks directory so all hooks are shared across systems:

```bash
ln -s ~/dev/claude-configs/hooks ~/.claude/hooks
```

Hooks are referenced by path in `~/.claude/settings.json`. The settings file should point to `~/.claude/hooks/<script>`, which resolves through the symlink to the repo. Example settings.json:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/on-stop.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### Verify installation

Open Claude Code and type `/` — your installed skills will appear in the autocomplete list. You can invoke any skill directly (e.g., `/pdf`, `/docx`) or let Claude use them automatically based on your request.

## Creating a New Skill

Use the skill-creator to scaffold a new skill:

```bash
python skill-creator/scripts/init_skill.py <skill-name> --path <output-directory>
```

See the [skill-creator SKILL.md](skill-creator/SKILL.md) for the full authoring guide.
