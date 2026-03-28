# Architecture

**Analysis Date:** 2026-03-23

## Pattern Overview

**Overall:** Domain-decomposed AI skill library for the ProcurementExpress.com API

**Key Characteristics:**
- Documentation-only repository (no executable application code)
- Each skill maps 1:1 to a ProcurementExpress domain entity or concern
- Skills follow a progressive disclosure pattern: YAML frontmatter (routing metadata) -> SKILL.md body (tool reference) -> references/ (detailed schemas)
- Originally MCP-based; transitioning to curl-based API interaction (see `PRD.md`)
- Backend API is Ruby on Rails at two version paths: V1 (static token) and V3 (OAuth2), with identical features

## Layers

**Authentication Layer:**
- Purpose: Establishes session before any API operations
- Location: `skills/pex-auth/SKILL.md`
- Contains: V1 static token auth, V3 OAuth2 auth, token validation, user profile management
- Depends on: Environment variables (`PROCUREMENTEXPRESS_AUTH_TOKEN`, `PROCUREMENTEXPRESS_COMPANY_ID`, `PROCUREMENTEXPRESS_CLIENT_ID`, `PROCUREMENTEXPRESS_CLIENT_SECRET`)
- Used by: All other skills (prerequisite)

**Company Context Layer:**
- Purpose: Sets the active company context for multi-tenant operations
- Location: `skills/pex-companies/SKILL.md`
- Contains: Company selection, company details/settings, employee management, user invitations, approver queries
- Depends on: pex-auth
- Used by: All domain skills (prerequisite after auth)

**Core Domain Layer (Procurement Workflow):**
- Purpose: Primary business operations — creating, approving, and managing purchase orders and invoices
- Location: `skills/pex-purchase-orders/SKILL.md`, `skills/pex-invoices/SKILL.md`
- Contains: Full CRUD + lifecycle management (draft, submit, approve, reject, cancel, archive, delete), delivery tracking, PDF generation, comments, forwarding
- Depends on: pex-auth, pex-companies, pex-suppliers, pex-budgets, pex-departments, pex-settings

**Supporting Domain Layer:**
- Purpose: Reference data and organizational entities that POs and invoices reference
- Locations:
  - `skills/pex-suppliers/SKILL.md` — vendor and product catalog management
  - `skills/pex-budgets/SKILL.md` — cost center management with spending tracking
  - `skills/pex-departments/SKILL.md` — organizational unit management
  - `skills/pex-payments/SKILL.md` — payment recording for invoices and POs
- Depends on: pex-auth, pex-companies
- Used by: pex-purchase-orders, pex-invoices

**Configuration & Integration Layer:**
- Purpose: System configuration, reference data, and third-party integrations
- Location: `skills/pex-settings/SKILL.md`
- Contains: Tax rates, webhooks, currencies, chart of accounts (GL codes), QuickBooks customers/classes
- Depends on: pex-auth, pex-companies
- Used by: PO and invoice line items (tax_rate_id, chart_of_account_id, qbo_customer_id, quickbooks_class_id)

**Approval Automation Layer:**
- Purpose: Configurable multi-step approval routing with conditions
- Location: `skills/pex-approval-flows/SKILL.md`, `skills/pex-approval-flows/references/conditions.md`
- Contains: Flow CRUD, step management, condition configuration, publish/unpublish lifecycle, version history, flow runs
- Depends on: pex-auth, pex-companies
- Used by: pex-purchase-orders, pex-invoices (automatic approval routing)

## Data Flow

**Authentication Flow:**
1. `authenticate` (pex-auth) — obtain session token
2. `get_current_user` (pex-auth) — retrieve user profile and company memberships
3. `set_active_company` (pex-companies) — set tenant context (client-side, no API call)
4. All subsequent API calls include `authentication_token` and `app_company_id` headers

**Purchase Order Lifecycle:**
1. Gather reference data: departments, suppliers, budgets, currencies, tax rates
2. `create_purchase_order` with `commit="Draft"` or `commit="Send"`
3. If sent: approval flow routes to approvers based on conditions
4. Approvers `approve_purchase_order` or `reject_purchase_order` using tokens from `approver_requests[]`
5. Post-approval: delivery tracking via `receive_purchase_order_items`, payment via `create_po_payment`
6. Communication: `forward_purchase_order` to supplier, `generate_purchase_order_pdf`

**Invoice Lifecycle:**
```
awaiting_review -> (accept) -> outstanding -> (approve) -> ready_to_pay -> (payment) -> settled
                                           -> (reject)  -> rejected
                                           -> (cancel)   -> cancelled
```

**Approval Flow Evaluation:**
1. Flow-level conditions determine WHICH documents match a flow (e.g., department, supplier, amount thresholds)
2. Step-level conditions determine WHICH steps activate for a matching document
3. Steps execute in `step_no` order; each step requires either all or any approver(s) to approve
4. Flows support versioning and can be rerun on existing documents when rules change

**Three-Way Matching (Invoice-PO Linking):**
1. Invoice `selected_purchase_order_ids` links to POs at the document level
2. Invoice line items link to PO line items via `purchase_order_item_id`
3. Enables variance detection between invoiced and ordered amounts

## Key Abstractions

**MCP Tool Pattern:**
- Purpose: Each API endpoint is documented as a named "tool" with params and returns
- Examples: `create_purchase_order`, `approve_invoice`, `list_suppliers`
- Pattern: Every tool documents params (required/optional, types, defaults), return shape, and required permissions/roles

**Pagination Pattern:**
- Purpose: Consistent paginated list responses across all list endpoints
- Pattern: `{ items: T[], meta: PaginationMeta }` where meta has `current_page`, `next_page`, `prev_page`, `total_pages`, `total_count`
- Used by: POs, invoices, suppliers, products, approval flows, chart of accounts, QBO entities

**Custom Fields Pattern:**
- Purpose: Company-configurable fields at document and line-item levels
- Pattern: `custom_field_values_attributes: [{ id?, value, custom_field_id }]`
- Available on: POs, invoices, budgets, PO line items, invoice line items
- Field definitions from: `get_company_details` -> `custom_fields[]`

**Nested Destroy Pattern (Rails convention):**
- Purpose: Manage nested records in update operations
- Pattern: Include `id` to update existing, omit `id` to create new, set `_destroy: true` to delete
- Used by: Line items, approval flow steps, approval flow conditions, webhook attributes

## Entry Points

**Authentication Entry:**
- Location: `skills/pex-auth/SKILL.md`
- Triggers: Any ProcurementExpress API interaction
- Responsibilities: Establish session, validate tokens, manage user profile

**Skill Routing Entry:**
- Location: Each `SKILL.md` YAML frontmatter `description` field
- Triggers: Keyword matching from frontmatter triggers (e.g., "purchase order", "invoice", "supplier")
- Responsibilities: Route user intent to the correct skill documentation

## Error Handling

**Strategy:** Permission-based access control with role requirements documented per tool

**Patterns:**
- Tools document required roles (e.g., "Requires companyadmin role", "Requires finance role", "Requires cancel permission")
- Feature flags gate functionality (e.g., `approval_flow_enabled`, `invoice_enabled`, `invoice_approval_flow_enabled`)
- Token-based approval/rejection prevents unauthorized approval actions (accept_token/reject_token from approver_requests)

## Cross-Cutting Concerns

**Multi-Tenancy:** Company context set via `app_company_id` header; `set_active_company` is a prerequisite for all domain operations

**Date Formatting:** All date fields must use the company's `date_format` setting (retrieved via `get_company_details` -> `company_setting.date_format`)

**Currency Handling:** Company has a default currency; entities can override with `currency_id` or `iso_code`; budgets track `base_amount`/`base_rate` for cross-currency conversion

**Accounting Integration:** QuickBooks (QBO) customers, classes, and chart of accounts (GL codes) can be attached to line items for accounting export; Sage export status tracked on invoices

**Role-Based Access:**
| Role | Permissions |
|------|------------|
| `companyadmin` | Full admin, manage users/settings |
| `approver` | Approve/reject POs and invoices |
| `finance` | Financial operations, override approvals, archive |
| `teammember` | Create and view POs |

---

*Architecture analysis: 2026-03-23*
