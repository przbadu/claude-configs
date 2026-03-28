# External Integrations

**Analysis Date:** 2026-03-23

## APIs & External Services

**ProcurementExpress API (Primary):**
- The entire repository documents this single API
- Base URL: `http://localhost:3000/api/v1` (development) / `docs.procurementexpress.com` (production)
- Auth: V1 static token or V3 OAuth2
- Client: MCP tools routed through ProcurementExpress MCP server
- Env vars: `PROCUREMENTEXPRESS_AUTH_TOKEN`, `PROCUREMENTEXPRESS_COMPANY_ID`, `PROCUREMENTEXPRESS_API_VERSION`, `PROCUREMENTEXPRESS_CLIENT_ID`, `PROCUREMENTEXPRESS_CLIENT_SECRET`

**API Domains Covered by Skills:**

| Skill | API Domain | Key MCP Tools |
|-------|-----------|---------------|
| `skills/pex-auth/SKILL.md` | Authentication | `authenticate`, `validate_token`, `revoke_token`, `get_current_user`, `update_current_user` |
| `skills/pex-companies/SKILL.md` | Companies & Users | `list_companies`, `set_active_company`, `list_employees`, `invite_user` |
| `skills/pex-purchase-orders/SKILL.md` | Purchase Orders | `create_purchase_order`, `approve_purchase_order`, `forward_purchase_order`, `generate_purchase_order_pdf` |
| `skills/pex-invoices/SKILL.md` | Invoices | `create_invoice`, `approve_invoice`, `accept_invoice` |
| `skills/pex-payments/SKILL.md` | Payments | `create_payment`, `create_po_payment` |
| `skills/pex-budgets/SKILL.md` | Budgets | `list_budgets`, `create_budget`, `update_budget` |
| `skills/pex-suppliers/SKILL.md` | Suppliers & Products | `list_suppliers`, `create_supplier`, `list_products`, `create_product` |
| `skills/pex-departments/SKILL.md` | Departments | `list_departments`, `create_department` |
| `skills/pex-settings/SKILL.md` | Settings & Reference Data | `list_tax_rates`, `list_webhooks`, `list_currencies`, `list_chart_of_accounts` |
| `skills/pex-approval-flows/SKILL.md` | Approval Flows | `create_approval_flow`, `publish_approval_flow`, `rerun_approval_flows` |

## Third-Party Accounting Integrations

**QuickBooks Online (QBO):**
- Referenced in `skills/pex-settings/SKILL.md`
- Tools: `list_qbo_customers`, `get_qbo_customer`, `list_qbo_classes`, `get_qbo_class`
- Used in PO and invoice line items via `qbo_customer_id`, `quickbooks_class_id`, `qbo_line_description`, `billable_status`
- Budget-level: `qbo_class` field in `skills/pex-budgets/SKILL.md`

**Sage:**
- Referenced in `skills/pex-invoices/SKILL.md` via `sage_exported` filter parameter
- Indicates Sage accounting export integration exists in the platform

## Data Storage

**Databases:**
- Not directly accessed — all data access is through the ProcurementExpress REST API
- The backend (`po-app`) uses a database (PostgreSQL inferred from Rails conventions)

**File Storage:**
- PDF generation: `generate_purchase_order_pdf` returns `{ pdf_link: string }` — hosted by ProcurementExpress platform
- Invoice uploads: `supplier_invoice_uploads[]` in invoice responses
- PO attachments: `uploads[]` in PO responses
- Storage service: Managed by ProcurementExpress platform (not directly accessible)

**Caching:**
- None at the skills level

## Authentication & Identity

**V1 Auth (Static Token):**
- Implementation: Header-based (`authentication_token` + `app_company_id`)
- Tokens never expire
- Configured via env vars or passed directly to `authenticate` MCP tool
- Documented in `skills/pex-auth/SKILL.md`

**V3 Auth (OAuth2):**
- Implementation: Email/password flow returning access token with expiry
- Requires OAuth2 client credentials (`PROCUREMENTEXPRESS_CLIENT_ID`, `PROCUREMENTEXPRESS_CLIENT_SECRET`)
- Token revocation supported via OAuth2 revocation endpoint
- 2FA/OTP not supported — must use V1 for 2FA-enabled accounts
- Documented in `skills/pex-auth/SKILL.md`

**User Roles:**
- `companyadmin` — full admin access
- `approver` — approve/reject POs and invoices
- `finance` — financial operations, override approvals
- `teammember` — create and view POs
- Documented in `skills/pex-companies/SKILL.md`

## Webhooks & Callbacks

**Outgoing Webhooks (Platform to External):**
- Documented in `skills/pex-settings/SKILL.md`
- Events: `new_po`, `po_approved`, `po_delivered`, `po_paid`, `po_cancelled`, `po_update`
- Sends HTTP POST to configured URL
- Supports: custom auth headers, basic auth, JSON or text format, custom key-value attributes
- Tools: `create_webhook`, `update_webhook`, `delete_webhook`, `list_webhooks`

**Incoming Webhooks:**
- None documented

## Email Integration

**PO Forwarding:**
- `forward_purchase_order` tool sends PO PDF to supplier via email
- Supports: multiple recipients, CC, custom subject, email body templates, file attachments
- Email templates managed via `list_send_to_supplier_templates`
- Documented in `skills/pex-purchase-orders/SKILL.md`

**User Invitations:**
- `invite_user` and `resend_invite` trigger invitation emails
- Documented in `skills/pex-companies/SKILL.md`

## Monitoring & Observability

**Error Tracking:**
- None at the skills level

**Logs:**
- None at the skills level

## CI/CD & Deployment

**Hosting:**
- Not applicable — documentation repository, no deployment

**CI Pipeline:**
- None detected

## Environment Configuration

**Required env vars for V1:**
- `PROCUREMENTEXPRESS_AUTH_TOKEN` — static authentication token
- `PROCUREMENTEXPRESS_COMPANY_ID` — company ID

**Required env vars for V3:**
- `PROCUREMENTEXPRESS_CLIENT_ID` — OAuth2 client ID
- `PROCUREMENTEXPRESS_CLIENT_SECRET` — OAuth2 client secret

**Optional env vars:**
- `PROCUREMENTEXPRESS_API_VERSION` — `v1` (default) or `v3`

**Secrets location:**
- Env vars only — no secrets files detected in repository

## Integration Architecture

```
Claude Code
    |
    ├── Loads SKILL.md files (this repo)
    |
    └── Calls MCP Tools
         |
         └── ProcurementExpress MCP Server (external)
              |
              └── ProcurementExpress REST API
                   |
                   ├── V1 endpoints (static token auth)
                   └── V3 endpoints (OAuth2 auth)
                        |
                        ├── QuickBooks Online (accounting sync)
                        ├── Sage (accounting export)
                        ├── Webhooks (event notifications)
                        └── Email (PO forwarding, invitations)
```

---

*Integration audit: 2026-03-23*
