# Testing Patterns

**Analysis Date:** 2026-03-23

## Overview

This repository contains **no tests**. It is a pure documentation/skills repository consisting entirely of Markdown files. There is no executable code, no test framework, no CI/CD pipeline, and no package manifest.

## Repository Composition

All files in this repository are Markdown (`.md`):
- 10 `SKILL.md` files (skill definitions)
- 4 reference files in `references/` subdirectories
- 1 `PRD.md` (product requirements document)

## Test Framework

**Runner:** Not applicable -- no executable code exists
**Assertion Library:** Not applicable
**Config:** No test configuration files

## Validation Approach

Since this is a skills repository, "testing" means **validating skill quality**:

### SKILL.md Structural Validation

Each `SKILL.md` should be validated for:
1. **YAML frontmatter** present with `name` and `description` fields
2. **Prerequisites section** exists referencing `pex-auth` and `pex-companies`
3. **Tool documentation** includes params with types and required/optional markers
4. **Response fields** section documents return types
5. **Cross-references** to other skills are accurate

### Validation Commands

The parent repository (`claude-configs`) provides skill validation tools:

```bash
# Package and validate a skill (from parent repo)
python3 skill-creator/scripts/package_skill.py <path/to/skill-folder>
```

This validator checks:
- YAML frontmatter presence and required fields
- File structure compliance
- Reference file linkage

### Manual Validation Checklist

When adding or modifying a skill:

- [ ] YAML frontmatter has `name` (format: `pex:<domain>`) and `description`
- [ ] Description lists MCP tool names and trigger keywords
- [ ] All tool parameters documented with types
- [ ] Required vs optional clearly marked on all params
- [ ] Response type names match across skills (e.g., `PurchaseOrder`, `Budget`)
- [ ] Cross-references use correct skill directory names
- [ ] Relative links to `references/` files are valid
- [ ] Enum values match actual API values
- [ ] Date fields note "must match company date_format"

## CI/CD

**Pipeline:** None configured
**Pre-commit hooks:** None detected
**Linting:** No markdown linting configured

## Coverage

Not applicable -- no executable code to cover.

## Recommendations for Future Testing

If automated validation is desired:

1. **Markdown lint** -- Add `markdownlint` config to enforce heading structure
2. **Frontmatter validation** -- Script to verify all `SKILL.md` files have required YAML fields
3. **Link checking** -- Validate all relative markdown links resolve to existing files
4. **Consistency checks** -- Verify shared type names (e.g., `PaginationMeta`, `PurchaseOrder`) are used consistently across skills
5. **API accuracy** -- Compare documented tools/params against actual MCP server or Rails controllers at the paths noted in `PRD.md`:
   - V1 API: `/Users/przbadu/projects/pex/po-app/app/controllers/api/v1`
   - V3 API: `/Users/przbadu/projects/pex/po-app/app/controllers/api/v3`

---

*Testing analysis: 2026-03-23*
