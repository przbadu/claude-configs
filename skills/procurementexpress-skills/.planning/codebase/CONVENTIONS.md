# Coding Conventions

**Analysis Date:** 2026-03-23

## Repository Type

This is a **documentation-only skills repository** -- no executable source code, no builds, no runtime. All files are Markdown (`.md`) documentation that serves as AI skill definitions for Claude Code's MCP integration with the ProcurementExpress API.

## File Naming Patterns

**Skill definition files:**
- Always named `SKILL.md` (uppercase) -- one per skill directory
- Example: `skills/pex-auth/SKILL.md`, `skills/pex-budgets/SKILL.md`

**Reference files:**
- Always lowercase kebab-case: `line-items.md`, `workflows.md`, `conditions.md`
- Placed in a `references/` subdirectory within the skill folder

**Skill directory naming:**
- Prefix: `pex-` followed by lowercase kebab-case domain name
- Examples: `pex-auth`, `pex-purchase-orders`, `pex-approval-flows`, `pex-settings`
- The prefix groups all ProcurementExpress skills together

## SKILL.md Structure Convention

Every `SKILL.md` follows this exact structure. Adhere to it when creating or modifying skills.

### 1. YAML Frontmatter (Required)

```yaml
---
name: pex:<domain-name>
description: >
  One-paragraph description of what this skill covers. Must include:
  - What it manages (e.g., "purchase order management")
  - MCP tool names it routes to (e.g., "Routes to MCP tools: list_purchase_orders, ...")
  - Trigger phrases (e.g., "Triggers on: purchase order, PO, create PO, ...")
---
```

- `name` uses colon separator: `pex:<domain>` (e.g., `pex:auth`, `pex:purchase-orders`)
- `description` is a single YAML folded scalar (`>`) block
- Description always lists: purpose, MCP tool names, and trigger keywords

### 2. Prerequisites Section

Always the first section after the title. Uses this exact pattern:

```markdown
## Prerequisites

Authenticate (pex-auth) and set active company (pex-companies) first.
```

- References other skills by their directory name in parentheses
- `pex-auth` is the only skill without the "set active company" prerequisite

### 3. Tools Reference Sections

Each MCP tool is documented as an H3 heading with this pattern:

```markdown
### tool_name
Brief one-line description of what the tool does.
- **Params:**
  - `param_name` (required/optional, type) -- description
  - `param_name` (optional, type, default: value) -- description
- **Returns:** `ResponseType` or description
```

Conventions for tool documentation:
- Tool names use `snake_case` matching the MCP tool names
- Parameters list required params first, then optional
- Type annotations: `integer`, `string`, `number`, `boolean`, `array`, `integer array`, `string array`
- Default values noted inline: `(optional, boolean, default: false)`
- Cross-references to other skills use parenthetical format: `(pex-companies)`
- Cross-references to reference files use relative markdown links: `[references/line-items.md](references/line-items.md)`

### 4. Response Fields Section

Documented as a bullet list of field names:

```markdown
## Response Fields

- `id`, `name`, `company_id`, `archived`
- `nested_array[]` -- description of array contents
```

- Array fields use `[]` suffix: `companies[]`, `approver_requests[]`
- Related fields grouped on one line separated by commas
- Nested object access uses dot notation in descriptions: `company_setting.date_format`

### 5. Workflow Sections (Optional)

Step-by-step guides in fenced code blocks:

```markdown
## Workflow: Name

\```
1. tool_name --> brief result description
2. tool_name --> brief result description
\```
```

- Use numbered steps
- Arrow (`-->`) separates tool call from expected result
- Reference other skill tools with skill name in parentheses

## Reference File Conventions

Reference files in `references/` directories follow these patterns:

**Schema documentation** (e.g., `line-items.md`, `conditions.md`):
- Use markdown tables for field schemas with columns: Field, Type, Required, Description
- Include "Tips" or "Examples" sections with JSON code blocks
- Cross-reference related tools from other skills

**Workflow documentation** (e.g., `workflows.md`):
- Each workflow is an H2 heading
- Steps in fenced code blocks, numbered
- Brief prose explanation before or after the steps

## Cross-Referencing Convention

Skills reference each other consistently:
- In prose: `(pex-auth skill)` or `(pex-companies)`
- In tool params: `"get from get_current_user"` or `"from pex-settings"`
- In YAML description: list all MCP tool names that the skill routes to

## Markdown Formatting

**Headers:**
- H1 (`#`): Skill title only, one per file
- H2 (`##`): Major sections (Prerequisites, Tools Reference, Response Fields, Workflows)
- H3 (`###`): Individual tool definitions

**Code blocks:**
- JSON for API request/response examples
- Plaintext (no language) for workflow step sequences
- `bash` for curl examples (only in `PRD.md`)

**Parameter documentation:**
- Bold labels: `**Params:**`, `**Returns:**`, `**Requires:**`, `**Note:**`
- Backticks for all field names, values, and type names
- Enum values in double quotes: `"draft"`, `"pending"`, `"approved"`

**Tables:**
- Used for schema definitions (field/type/required/description)
- Used for enum mappings (value/description)
- Used for cross-reference summaries (data/used-in)

## Naming Conventions

**API entities:**
- snake_case for all field names: `purchase_order_id`, `gross_amount`, `supplier_name`
- snake_case for tool names: `list_purchase_orders`, `create_budget`
- snake_case for status values: `awaiting_review`, `ready_to_pay`

**Skill naming:**
- Directory: `pex-<domain>` (kebab-case)
- YAML name: `pex:<domain>` (colon-separated)
- Display title: "ProcurementExpress <Domain>" (title case)

## Documentation Quality Standards

- Every tool must document all parameters with types and required/optional status
- Default values must be specified for optional params that have them
- Response types must be named (e.g., `Budget`, `PurchaseOrder`, not "the response object")
- Permissions/role requirements noted with `**Requires:**` when applicable
- Feature flags noted when tools depend on company settings (e.g., `invoice_enabled`)

---

*Convention analysis: 2026-03-23*
