# Codebase Concerns

**Analysis Date:** 2026-03-23

## Tech Debt

**MCP Dependency — Skills Built on Deprecated Foundation:**
- Issue: All skills reference MCP tool names (e.g., `authenticate`, `list_purchase_orders`, `create_payment`) but `PRD.md` explicitly states the current skills are "outdated" and need to be rebuilt using `curl` instead of MCP
- Files: All `skills/pex-*/SKILL.md` files, `PRD.md` (lines 18-19)
- Impact: The entire skill set describes an MCP-based interface that the owner wants to replace. Any consumer following these skills will use the MCP approach, not the desired curl-based approach
- Fix approach: Rewrite each SKILL.md to document curl endpoints, request/response formats, and headers instead of MCP tool references. Use `PRD.md` lines 29-68 as the template for the curl-based format

**PRD.md Contains Hardcoded Credentials:**
- Issue: `PRD.md` contains a plaintext email and password in a curl example (line 54): `admin@rubberstamp.io` / `rubberst@mp99`
- Files: `PRD.md` (line 54)
- Impact: These credentials are committed to git. Even if they are dev/test credentials, this sets a bad precedent and could leak if the repo becomes public
- Fix approach: Replace with placeholder values like `<email>` and `<password>`, matching the pattern already used for `<token>` and `<company_id>` elsewhere in the same file

**PRD.md Contains Hardcoded Local Paths:**
- Issue: `PRD.md` references absolute local filesystem paths (`/Users/przbadu/projects/pex/po-app/...`) that are specific to one developer's machine
- Files: `PRD.md` (lines 7-8)
- Impact: These paths are useless for any other contributor and will break if the developer changes their directory structure
- Fix approach: Use environment variables or relative references (e.g., `$PEX_BACKEND_PATH`) or document as configuration rather than hardcoded paths

## Inconsistencies

**Operator Representation Conflict in Approval Flow Conditions:**
- Issue: `skills/pex-approval-flows/references/conditions.md` documents operators as named strings (`"equals"`, `"greater_than"`, `"is_any_of"`) in the Operators table, but the JSON examples use numeric string values (`"0"` for equals, `"2"` for greater_than, `"4"` for is_any_of)
- Files: `skills/pex-approval-flows/references/conditions.md` (lines 30-41 vs lines 48-65)
- Impact: A consumer building approval flow conditions will get conflicting guidance. Using the wrong format will cause API errors
- Fix approach: Verify against the actual API which format is correct and update the document to be consistent. If both are accepted, document that explicitly

**Invoice Line Items Have No Required Fields:**
- Issue: In `skills/pex-invoices/references/line-items.md`, every field including `description`, `quantity`, and `unit_price` is marked as optional ("No"). In contrast, `skills/pex-purchase-orders/references/line-items.md` marks `description`, `quantity`, and `unit_price` as required ("Yes")
- Files: `skills/pex-invoices/references/line-items.md` (lines 8-25), `skills/pex-purchase-orders/references/line-items.md` (lines 8-27)
- Impact: Users may create invoice line items with no description or amounts, which may fail or produce garbage data
- Fix approach: Verify against the API which fields are actually required for invoice line items and update the documentation

**V1 vs V3 API Version Confusion:**
- Issue: `PRD.md` states V3 API "supports oauth2 authentication, apart from that all the features are identical with v1 api" but `skills/pex-auth/SKILL.md` describes them as having different authentication flows with different parameters and different response formats (V1 returns User object, V3 returns TokenInfo)
- Files: `PRD.md` (line 8), `skills/pex-auth/SKILL.md` (lines 20-37, 50-53)
- Impact: Unclear whether V3 endpoints should be documented separately or if V1 curl examples work for V3 with only auth header changes
- Fix approach: Clarify in each skill whether V1 and V3 endpoints, request params, and response formats are truly identical beyond auth

## Missing Critical Features

**No README.md:**
- Problem: The repository has no README.md explaining what the skills collection is, how to install/use it, or how the skills relate to each other
- Files: Repository root
- Blocks: New users cannot understand the project purpose or get started without reading PRD.md (which is a requirements doc, not usage docs)

**No LICENSE File:**
- Problem: Neither the repository root nor any individual skill directory contains a LICENSE.txt, which is listed as part of the standard skill structure in the parent project's CLAUDE.md
- Files: All `skills/pex-*/` directories
- Blocks: Unclear legal status for reuse or distribution

**No SKILL.md Frontmatter Validation:**
- Problem: There is no script or CI check to validate that SKILL.md files have correct YAML frontmatter with required `name` and `description` fields
- Files: All `skills/pex-*/SKILL.md` files
- Blocks: Malformed frontmatter could cause skill routing failures in the parent skill system

**No scripts/ Directory in Any Skill:**
- Problem: None of the 10 skills contain a `scripts/` directory. The PRD.md goal is to provide curl-based examples, but there are no executable helper scripts to actually run curl commands, test endpoints, or validate API responses
- Files: All `skills/pex-*/` directories
- Blocks: Users must manually construct curl commands; no automation or testing helpers exist

## Security Considerations

**Plaintext Credentials in PRD.md:**
- Risk: Login credentials committed to version control
- Files: `PRD.md` (line 54)
- Current mitigation: None
- Recommendations: Remove credentials, use placeholders, add PRD.md to .gitignore if it must contain sensitive examples, or reference a `.env` file

**Auth Tokens in Skill Documentation:**
- Risk: Skills describe passing `authentication_token` as a header. If users follow curl examples and paste real tokens into their shell history, those tokens persist in `~/.bash_history` or `~/.zsh_history`
- Files: `skills/pex-auth/SKILL.md`, `PRD.md`
- Current mitigation: None
- Recommendations: Document best practice of using environment variables for tokens (e.g., `$PEX_TOKEN`) rather than inline values, and note shell history risks

**V1 Static Tokens Never Expire:**
- Risk: `skills/pex-auth/SKILL.md` (line 29) states "V1 tokens never expire." A leaked V1 token provides permanent API access
- Files: `skills/pex-auth/SKILL.md` (line 29)
- Current mitigation: Token can be manually revoked but this is only documented as a client-side clear for V1
- Recommendations: Document the risk explicitly and recommend V3 OAuth2 for production use

## Fragile Areas

**Date Format Dependency:**
- Files: `skills/pex-budgets/SKILL.md`, `skills/pex-purchase-orders/SKILL.md`, `skills/pex-invoices/SKILL.md`, `skills/pex-payments/SKILL.md`
- Why fragile: Multiple skills reference that date fields "must match company date_format setting" but none document what the possible date formats are or how to programmatically retrieve and parse them. A consumer must first call `get_company_details`, extract `company_setting.date_format`, then format all dates accordingly
- Safe modification: Always test with multiple date formats when changing date-related documentation
- Test coverage: No test scripts exist to validate date format handling

**Cross-Skill Workflow Dependencies:**
- Files: `skills/pex-purchase-orders/references/workflows.md`, all SKILL.md prerequisite sections
- Why fragile: Every skill requires auth (pex-auth) and company selection (pex-companies) first. Workflows span 3-6 skills. If any skill's tool name or parameter changes, all dependent workflows break silently
- Safe modification: Update workflows.md and all cross-references when changing any tool's interface
- Test coverage: No integration tests or workflow validation scripts

## Test Coverage Gaps

**No Tests Whatsoever:**
- What's not tested: The entire skill collection has zero test files, validation scripts, or CI configuration
- Files: All `skills/pex-*/` directories
- Risk: Documentation can drift from the actual API without detection. Incorrect parameter names, types, or required/optional status will cause consumer failures
- Priority: Medium - this is a documentation project, but automated validation against the live API would catch drift

**No API Response Validation:**
- What's not tested: Response field documentation (e.g., `PurchaseOrder` fields, `Invoice` fields) is maintained manually with no way to verify it matches actual API responses
- Files: All SKILL.md files with "Response Fields" sections
- Risk: Documented fields may be missing, renamed, or have changed types in the actual API
- Priority: Medium - add sample response fixtures or schema validation scripts

## Dependencies at Risk

**MCP Server Dependency:**
- Risk: All skills are written for an MCP server that the owner explicitly wants to deprecate in favor of curl
- Impact: The entire skill collection needs rewriting
- Migration plan: Follow the curl template in `PRD.md` (lines 29-68), converting each MCP tool to its equivalent curl endpoint with proper headers, params, and response documentation

---

*Concerns audit: 2026-03-23*
