# Technology Stack

**Analysis Date:** 2026-03-23

## Languages

**Primary:**
- Markdown — All skill definitions, reference docs, and API documentation

**Secondary:**
- YAML — Frontmatter metadata in every `SKILL.md` file
- Bash (curl) — API interaction examples in `PRD.md`

## Runtime

**Environment:**
- No runtime required — this is a documentation/reference repository consumed by Claude Code as AI skills
- Skills are loaded by Claude Code's skill system via `SKILL.md` files with YAML frontmatter

**Package Manager:**
- None — no `package.json`, `requirements.txt`, `Gemfile`, `Cargo.toml`, or any other package manifest exists

## Frameworks

**Core:**
- Claude Code Skills Framework — skills follow the standard `SKILL.md` + `references/` + YAML frontmatter structure
- MCP (Model Context Protocol) — skills route to MCP tools for ProcurementExpress API interaction (referenced throughout all SKILL.md files)

**Testing:**
- None — no test framework, no test files

**Build/Dev:**
- None — no build step, no compilation, no bundling

## Key Dependencies

**Critical:**
- ProcurementExpress MCP Server — all skills route tool calls to this MCP server (not included in this repo, referenced externally)
- Claude Code — the AI assistant that loads and executes these skills

**Infrastructure:**
- `curl` — used for direct API testing examples in `PRD.md`
- `gh` CLI — not directly used here but referenced by related skills (github-pr, git-worktree)

## Configuration

**Environment:**
- `PROCUREMENTEXPRESS_API_VERSION` — `v1` or `v3` (default: `v1`), referenced in `skills/pex-auth/SKILL.md`
- `PROCUREMENTEXPRESS_AUTH_TOKEN` — V1 static auth token
- `PROCUREMENTEXPRESS_COMPANY_ID` — V1 company ID
- `PROCUREMENTEXPRESS_CLIENT_ID` — V3 OAuth2 client ID
- `PROCUREMENTEXPRESS_CLIENT_SECRET` — V3 OAuth2 client secret
- `.env` file existence: Not detected

**Build:**
- No build configuration files

## API Versions

**V1 API:**
- Base URL: `http://localhost:3000/api/v1`
- Auth: Static token via `authentication_token` header + `app_company_id` header
- Backend path: `/Users/przbadu/projects/pex/po-app/app/controllers/api/v1`

**V3 API:**
- Auth: OAuth2 (email + password flow)
- Backend path: `/Users/przbadu/projects/pex/po-app/app/controllers/api/v3`
- Identical features to V1 except for OAuth2 authentication

## Platform Requirements

**Development:**
- Claude Code with skills support
- Access to ProcurementExpress MCP server (or direct API access via curl)
- The backend application (`po-app`) is a Ruby on Rails app (inferred from `app/controllers/api/` path structure)

**Production:**
- ProcurementExpress SaaS platform at `docs.procurementexpress.com`

## Repository Nature

This is a **documentation-only repository** — it contains zero executable source code. All files are Markdown skill definitions that teach Claude Code how to interact with the ProcurementExpress API via MCP tools or curl commands. There are no builds, no tests, no compiled artifacts.

---

*Stack analysis: 2026-03-23*
