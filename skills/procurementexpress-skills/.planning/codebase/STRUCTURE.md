# Codebase Structure

**Analysis Date:** 2026-03-23

## Directory Layout

```
procurementexpress-skills/
├── .planning/                          # Planning and analysis documents
│   └── codebase/                       # Codebase mapping documents
├── skills/                             # All ProcurementExpress API skills
│   ├── pex-auth/                       # Authentication & user profile
│   │   └── SKILL.md
│   ├── pex-companies/                  # Company management & employees
│   │   └── SKILL.md
│   ├── pex-purchase-orders/            # Purchase order lifecycle (core)
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── line-items.md           # PO line item schema
│   │       └── workflows.md           # Step-by-step PO workflows
│   ├── pex-invoices/                   # Invoice lifecycle
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── line-items.md           # Invoice line item schema
│   ├── pex-approval-flows/             # Approval flow configuration
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── conditions.md           # Condition schema & operators
│   ├── pex-budgets/                    # Budget/cost center management
│   │   └── SKILL.md
│   ├── pex-departments/                # Department management
│   │   └── SKILL.md
│   ├── pex-suppliers/                  # Supplier & product catalog
│   │   └── SKILL.md
│   ├── pex-payments/                   # Payment management
│   │   └── SKILL.md
│   └── pex-settings/                   # Tax rates, webhooks, currencies, GL codes, QBO
│       └── SKILL.md
└── PRD.md                              # Product requirements (transition plan)
```

## Directory Purposes

**`skills/`:**
- Purpose: Contains all domain-specific skill modules for the ProcurementExpress API
- Contains: Subdirectories named `pex-{domain}`, each with a `SKILL.md` and optional `references/`
- Key convention: Every skill directory MUST contain a `SKILL.md` with YAML frontmatter

**`skills/pex-{domain}/references/`:**
- Purpose: Detailed reference documentation loaded on demand (progressive disclosure tier 3)
- Contains: Markdown files with schemas, condition definitions, workflow guides
- Present in: `pex-purchase-orders`, `pex-invoices`, `pex-approval-flows`

**`.planning/`:**
- Purpose: Planning and analysis artifacts (not part of the skill content)
- Contains: Codebase mapping documents
- Generated: Yes (by mapping tools)
- Committed: No (typically gitignored)

## Key File Locations

**Entry Points:**
- `skills/pex-auth/SKILL.md`: Authentication — always the first skill invoked
- `skills/pex-companies/SKILL.md`: Company selection — second step after auth

**Core Business Logic:**
- `skills/pex-purchase-orders/SKILL.md`: Purchase order management (the primary domain object)
- `skills/pex-invoices/SKILL.md`: Invoice management
- `skills/pex-approval-flows/SKILL.md`: Approval workflow automation

**Reference Data:**
- `skills/pex-settings/SKILL.md`: Tax rates, currencies, webhooks, chart of accounts, QuickBooks
- `skills/pex-suppliers/SKILL.md`: Suppliers and product catalog
- `skills/pex-budgets/SKILL.md`: Budgets/cost centers
- `skills/pex-departments/SKILL.md`: Organizational departments

**Detailed Schemas (references/):**
- `skills/pex-purchase-orders/references/line-items.md`: PO line item field schema (26 fields)
- `skills/pex-purchase-orders/references/workflows.md`: 8 step-by-step PO workflow guides
- `skills/pex-invoices/references/line-items.md`: Invoice line item field schema with PO linking
- `skills/pex-approval-flows/references/conditions.md`: Condition properties, operators, and examples

**Project Planning:**
- `PRD.md`: Documents the transition from MCP-based to curl-based API interaction; contains the target curl format and backend implementation notes

## Naming Conventions

**Files:**
- `SKILL.md`: Core skill documentation (UPPERCASE, required in every skill directory)
- `*.md`: All content is Markdown (no executable code in this repo)
- Reference files: lowercase-kebab-case (e.g., `line-items.md`, `conditions.md`, `workflows.md`)

**Directories:**
- Skill directories: `pex-{domain-name}` prefix with kebab-case (e.g., `pex-purchase-orders`, `pex-approval-flows`)
- Reference directories: always named `references/`
- The `pex-` prefix namespaces all skills under the ProcurementExpress product

**YAML Frontmatter:**
- `name`: Uses colon-separated namespace: `pex:{domain}` (e.g., `pex:purchase-orders`, `pex:auth`)
- `description`: Multi-line YAML string with tool routing keywords and trigger phrases

## Where to Add New Code

**New Skill (new API domain):**
- Create directory: `skills/pex-{domain-name}/`
- Create required file: `skills/pex-{domain-name}/SKILL.md` with YAML frontmatter (`name`, `description`)
- Add `references/` subdirectory only if detailed schemas or workflows are needed

**New Reference Document:**
- Add to existing skill: `skills/pex-{domain-name}/references/{topic}.md`
- Link from SKILL.md body with relative path: `[references/{topic}.md](references/{topic}.md)`
- Keep SKILL.md under 5000 words; move detailed schemas to references/

**New Workflow Documentation:**
- Add to: `skills/pex-purchase-orders/references/workflows.md` (for PO workflows)
- Or create: `skills/pex-{domain}/references/workflows.md` for other domain workflows

## Special Directories

**`references/`:**
- Purpose: Progressive disclosure tier 3 — detailed schemas, conditions, workflows loaded on demand
- Generated: No (hand-authored)
- Committed: Yes
- Present in: `pex-purchase-orders`, `pex-invoices`, `pex-approval-flows`
- Not present in simpler skills: `pex-auth`, `pex-budgets`, `pex-departments`, `pex-suppliers`, `pex-payments`, `pex-settings` (their SKILL.md is self-contained)

## Skill Dependency Order

When consuming skills, follow this initialization sequence:

```
1. pex-auth          (authenticate)
2. pex-companies     (set_active_company)
3. pex-settings      (reference data: currencies, tax rates, GL codes)
4. pex-departments   (organizational structure)
5. pex-suppliers     (vendors and products)
6. pex-budgets       (cost centers)
7. pex-approval-flows (approval configuration)
8. pex-purchase-orders (core procurement)
9. pex-invoices      (billing)
10. pex-payments     (settlement)
```

Skills 3-7 can be loaded in any order; they are peers. Skills 8-10 depend on reference data from 3-7.

---

*Structure analysis: 2026-03-23*
