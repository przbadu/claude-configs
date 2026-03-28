# PRD v2 — ProcurementExpress Unified curl-based API Skill

## Overview

Replace the current 10 separate MCP-based skills with a **single unified skill** using progressive disclosure. One SKILL.md acts as a router/overview, with domain-specific reference files loaded on demand.

## Architecture

```
procurementexpress-api/
├── SKILL.md                          (~300 lines — routing, overview, shared conventions)
└── references/
    ├── authentication.md             (login, tokens, OAuth2, user profile)
    ├── company-users.md              (companies, employees, invites, approvers, roles)
    ├── purchase-orders.md            (CRUD, approve/reject, receiving, PDF, forward, comments)
    ├── invoices.md                   (CRUD, accept/approve/reject, lifecycle, comments)
    ├── approval-flows.md             (CRUD, publish, runs, versions, conditions schema)
    ├── budgets-departments.md        (budgets + departments CRUD, associations)
    ├── suppliers.md                  (suppliers CRUD, products, SAM.gov fields)
    ├── payments.md                   (invoice payments, PO payments)
    ├── settings.md                   (tax rates, currencies, chart of accounts, custom fields)
    └── webhooks-integrations.md      (webhooks, QBO customers/classes, email templates)
```

**Why single skill:**
- One install, one share, one version
- SKILL.md is always loaded (~300 lines, minimal tokens)
- References loaded only when the specific domain is needed
- No duplication of shared conventions across 10 frontmatters

## Base URL

```
http://localhost:3000/api/v1
```

## Authentication Headers

Required on all requests except `POST /login`:
```
authentication_token: <token>
app_company_id: <company_id>
Content-Type: application/json
```

**V3 OAuth2:** V3 API at `/api/v3/` is identical to V1 but uses `Authorization: Bearer <access_token>` instead of `authentication_token`. Always read V1 controller implementation.

## Backend Source Paths

- Controllers: `/Users/przbadu/projects/pex/po-app/app/controllers/api/v1/`
- Serializers: `/Users/przbadu/projects/pex/po-app/app/serializers/`
- Routes: `/Users/przbadu/projects/pex/po-app/config/routes.rb`

**How to verify accuracy:**
- POST/PUT params → check strong params (`_params` methods) in controllers
- GET response fields → check `*_serializer.rb` files in serializers directory

---

## SKILL.md Spec (~300 lines)

### YAML Frontmatter

```yaml
---
name: procurementexpress-api
description: >
  ProcurementExpress REST API reference for curl-based interaction. Covers the full
  procurement lifecycle: authentication, companies, purchase orders, invoices, approvals,
  suppliers, budgets, departments, payments, and settings. Use when interacting with the
  ProcurementExpress API via curl commands — creating POs, approving requests, managing
  suppliers, configuring approval flows, or any procurement operation.
  Triggers on: pex, procurement, purchase order, PO, invoice, supplier, budget, department,
  approval flow, payment, tax rate, webhook, company, authenticate, login.
---
```

### SKILL.md Body Structure

The body should contain:

1. **Quick Start** — login flow + first API call
2. **Shared Conventions** — auth headers, pagination, errors, dates, nested attributes, custom fields
3. **API Domain Index** — table routing to the right reference file
4. **Endpoint Quick Reference** — compact table of ALL endpoints (method, path, description, reference file)

#### Section 1: Quick Start

```
## Quick Start

### 1. Login
POST /login with {"email": "...", "password": "..."}
Response includes authentication_token and companies[].

### 2. Set Company
Pick a company ID from companies[] in the login response.

### 3. Make Requests
All subsequent requests need these headers:
  authentication_token: <token>
  app_company_id: <company_id>
  Content-Type: application/json
```

Include the login curl example inline.

#### Section 2: Shared Conventions

```
## Conventions

### Pagination
Endpoints accepting `page` return: { meta: { current_page, next_page, prev_page, total_pages, total_count } }

### Errors
{ "errors": ["message"] } with HTTP status code.

### Dates
Must match company's date_format from GET /companies/details → company_setting.date_format.

### Nested Attributes (Rails)
- Omit `id` → create new
- Include `id` → update existing
- Include `id` + `_destroy: true` → delete

### Custom Field Values
Available on POs, invoices, budgets, line items:
custom_field_values_attributes: [{value, custom_field_id}]
Get field IDs from GET /companies/details → custom_fields[].
```

#### Section 3: API Domain Index

```
## API Domains

| Domain | Reference | Key Operations |
|--------|-----------|----------------|
| Authentication | [authentication.md](references/authentication.md) | Login, tokens, user profile |
| Companies & Users | [company-users.md](references/company-users.md) | Company details, employees, invites, approvers |
| Purchase Orders | [purchase-orders.md](references/purchase-orders.md) | Create, approve, reject, deliver, PDF, forward |
| Invoices | [invoices.md](references/invoices.md) | Create, accept, approve, reject, PO linking |
| Approval Flows | [approval-flows.md](references/approval-flows.md) | Create flows, conditions, publish, runs |
| Budgets & Departments | [budgets-departments.md](references/budgets-departments.md) | Budget CRUD, department CRUD, associations |
| Suppliers & Products | [suppliers.md](references/suppliers.md) | Supplier CRUD, products, SKUs, top suppliers |
| Payments | [payments.md](references/payments.md) | Invoice payments, PO payments |
| Settings & Reference Data | [settings.md](references/settings.md) | Tax rates, currencies, GL codes, custom fields |
| Webhooks & Integrations | [webhooks-integrations.md](references/webhooks-integrations.md) | Webhooks, QBO, email templates |
```

#### Section 4: Endpoint Quick Reference

Compact table of ALL endpoints across all domains. This lets Claude quickly find the right endpoint without loading a reference file:

```
## Endpoint Quick Reference

| Method | Path | Description | Ref |
|--------|------|-------------|-----|
| POST | /login | Login | auth |
| GET | /currentuser | Current user | auth |
| PUT | /currentuser | Update profile | auth |
| GET | /companies | List companies | company |
| GET | /companies/details | Company details + settings | company |
| GET | /companies/employees | List employees | company |
| GET | /companies/approvers | Department approvers | company |
| POST | /companies/send_user_invite | Invite user | company |
| GET | /departments | List departments | budget-dept |
| POST | /departments | Create department | budget-dept |
| PUT | /departments/:id | Update department | budget-dept |
| GET | /budgets | List budgets | budget-dept |
| POST | /budgets | Create budget | budget-dept |
| PUT | /budgets/:id | Update budget | budget-dept |
| GET | /suppliers | List suppliers | supplier |
| POST | /suppliers | Create supplier | supplier |
| PUT | /suppliers/:id | Update supplier | supplier |
| GET | /suppliers/top | Top suppliers | supplier |
| GET | /products | List products | supplier |
| POST | /products | Create product | supplier |
| POST | /products/bulk_create | Bulk create products | supplier |
| GET | /products/skus | Search SKUs | supplier |
| GET | /purchase_orders | List POs | po |
| GET | /purchase_orders/:id | Show PO | po |
| POST | /purchase_orders | Create PO | po |
| PUT | /purchase_orders/:id | Update PO | po |
| DELETE | /purchase_orders/:id | Delete PO | po |
| POST | /purchase_orders/:id/approve | Approve PO | po |
| POST | /purchase_orders/:id/reject | Reject PO | po |
| POST | /purchase_orders/:id/override_and_approve | Finance override | po |
| PATCH | /purchase_orders/:id/cancel | Cancel PO | po |
| PATCH | /purchase_orders/:id/archive | Archive PO | po |
| GET | /purchase_orders/:id/generate_pdf | Generate PDF | po |
| POST | /purchase_orders/:id/forward | Forward to supplier | po |
| POST | /purchase_orders/:id/receiving_items | Record delivery | po |
| DELETE | /purchase_orders/:id/cancel_receiving_items | Cancel delivery | po |
| PATCH | /purchase_orders/:id/complete_delivery | Complete delivery | po |
| GET | /purchase_orders/pending_request_count | Pending approvals | po |
| POST | /purchase_orders/bulk_save | Bulk create POs | po |
| GET | /invoices | List invoices | invoice |
| GET | /invoices/:id | Show invoice | invoice |
| POST | /invoices | Create invoice | invoice |
| PUT | /invoices/:id | Update invoice | invoice |
| PATCH | /invoices/:id/accept | Accept invoice | invoice |
| PATCH | /invoices/:id/approve | Approve invoice | invoice |
| PATCH | /invoices/:id/reject | Reject invoice | invoice |
| PATCH | /invoices/:id/cancel | Cancel invoice | invoice |
| PATCH | /invoices/:id/archive | Archive invoice | invoice |
| PATCH | /invoices/:id/dearchive | Restore invoice | invoice |
| PATCH | /invoices/:id/rerun_approval_flow | Rerun approval | invoice |
| POST | /invoices/:id/create_comment | Add comment | invoice |
| GET | /approval_flows | List flows | flow |
| GET | /approval_flows/:id | Show flow | flow |
| POST | /approval_flows | Create flow | flow |
| PUT | /approval_flows/:id | Update flow | flow |
| DELETE | /approval_flows/:id | Delete flow | flow |
| POST | /approval_flows/:id/archive | Archive flow | flow |
| POST | /approval_flows/:id/publish | Publish flow | flow |
| POST | /approval_flows/:id/unpublish | Unpublish flow | flow |
| GET | /approval_flows/:id/runs | Flow run history | flow |
| POST | /approval_flows/rerun_approval_flows | Batch rerun | flow |
| GET | /npayments/:id | Show payment | payment |
| POST | /npayments | Create payment | payment |
| POST | /purchase_orders/:id/payments | PO payment | payment |
| GET | /tax_rates | List tax rates | settings |
| POST | /tax_rates | Create tax rate | settings |
| PUT | /tax_rates/:id | Update tax rate | settings |
| GET | /currencies | Company currencies | settings |
| GET | /all_currencies | All currencies | settings |
| GET | /chart_of_accounts | List GL codes | settings |
| GET | /webhooks | List webhooks | webhook |
| POST | /webhooks | Create webhook | webhook |
| PUT | /webhooks/:id | Update webhook | webhook |
| DELETE | /webhooks/:id | Delete webhook | webhook |
| GET | /qbo_customers | QBO customers | webhook |
| GET | /qbo_classes | QBO classes | webhook |
| GET | /send_to_supplier_templates | Email templates | webhook |
```

---

## Reference File Specs

Each reference file follows this structure:
1. Header with domain description
2. Endpoints with full params (from strong params)
3. Response fields (from serializers)
4. 2-3 curl examples per major operation
5. Notes on special behavior

---

### references/authentication.md

**Covers:** Login, OTP verification, user profile, logout, password reset

**Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| POST | /login | Login with email/password |
| POST | /verify_otp | Verify OTP for 2FA |
| POST | /resend_otp | Resend OTP code |
| GET | /currentuser | Get authenticated user profile |
| PUT | /currentuser | Update user profile |
| POST | /register | Register new user |
| POST | /reset_password | Reset password |
| POST | /logout | End session |

**Params:**

`POST /login`:
- `email` (required, string)
- `password` (required, string)

`POST /verify_otp`:
- `otp` (required, string)

`PUT /currentuser` (api_user_params):
- `email`, `name`, `first_name`, `last_name`, `phone_number` (all optional)

`POST /register` (user_params):
- `email` (required), `name`, `first_name`, `last_name`, `password`, `password_confirmation`, `phone_number`, `terms_of_service`

**Response Fields (UserSerializer):**
- `id`, `email`, `name`, `approver_name`, `phone_number`, `setup_incomplete`, `employer_id`, `approval_limit`
- `authentication_token` — use for subsequent requests
- `companies[]` — each: `id`, `name`, `roles[]`, `is_locked`, `in_trial`, `trial_expired`, `remaining_trial_days`, `has_unassigned_budgets`

**Curl Examples:**

```bash
# Login
curl -s -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password123"}'

# Get current user
curl -s http://localhost:3000/api/v1/currentuser \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID"

# Update profile
curl -s -X PUT http://localhost:3000/api/v1/currentuser \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID" \
  -H "Content-Type: application/json" \
  -d '{"name": "New Name", "phone_number": "+1234567890"}'
```

**Typical Workflow:**
```
1. POST /login → get authentication_token + companies[]
2. Pick company ID from companies[]
3. Use token + company_id headers for all requests
```

**Backend Source:** `users_controller.rb`, `user_serializer.rb`

---

### references/company-users.md

**Covers:** Company details, settings, employees, invitations, approvers

**Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | /companies | List user's companies |
| GET | /companies/:id | Show company |
| GET | /companies/details | Active company details + settings + custom fields |
| GET | /companies/employees | List employees |
| GET | /companies/approvers | Approvers (optionally by department) |
| GET | /companies/all_approvers | All company approvers |
| GET | /companies/invite_limit_left | Check invite slots |
| POST | /companies/send_user_invite | Invite a user |
| GET | /companies/pending_invites | List pending invites |
| POST | /companies/cancel_invite | Cancel an invite |
| POST | /companies/resend_invite | Resend an invite |

**Params:**

`GET /companies/approvers`:
- `department_id` (optional, integer)

`POST /companies/send_user_invite` (invite_user_params):
- `email` (required), `name` (required)
- `approval_limit` (optional, number)
- `roles` (optional, array) — e.g. `["companyadmin"]`
- `department_ids` (optional, integer array)

**Response Fields:**

`CompanySerializer` (list):
- `id`, `name`, `external_user_id`, `membership_archived`, `is_locked`, `is_removed`
- `approval_limit`, `in_trial`, `trial_expired`, `remaining_trial_days`, `roles[]`, `has_unassigned_budgets`

`CompanyDetailSerializer` (details):
- `id`, `name`, `employees_count`, `default_tax_rate`
- `prepaid_subscription`, `multicompany_pack`
- Feature flags: `payment_term_ff_enabled`, `scan_and_match_ff_enabled`, `approval_flow_ff_enabled`, `policy_ff_enabled`, `sam_gov_enabled`
- Relationships: `company_setting` (date_format, currency, PDF settings, etc.), `supported_currencies[]`, `custom_fields[]`, `payment_terms[]`

**Curl Examples:**

```bash
# Get company details (settings, custom fields, currencies)
curl -s http://localhost:3000/api/v1/companies/details \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID"

# List employees
curl -s http://localhost:3000/api/v1/companies/employees \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID"

# Invite user
curl -s -X POST http://localhost:3000/api/v1/companies/send_user_invite \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID" \
  -H "Content-Type: application/json" \
  -d '{"email": "new@example.com", "name": "New User", "roles": ["employee"], "department_ids": [1, 2]}'
```

**Backend Source:** `companies_controller.rb`, `company_serializer.rb`, `company_detail_serializer.rb`, `company_setting_serializer.rb`

---

### references/purchase-orders.md

**Covers:** Full PO lifecycle — CRUD, approval, delivery, PDF, forwarding, comments

**Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | /purchase_orders | List POs (paginated) |
| GET | /purchase_orders/:id | Show PO details |
| GET | /purchase_orders/new | New PO template |
| POST | /purchase_orders | Create PO |
| PUT | /purchase_orders/:id | Update PO |
| DELETE | /purchase_orders/:id | Delete PO |
| POST | /purchase_orders/:id/approve | Approve PO (token-based) |
| POST | /purchase_orders/:id/reject | Reject PO (token-based) |
| POST | /purchase_orders/:id/override_and_approve | Finance override approval |
| PATCH | /purchase_orders/:id/cancel | Cancel PO |
| PATCH | /purchase_orders/:id/archive | Archive/unarchive PO |
| GET | /purchase_orders/:id/generate_pdf | Generate PDF (returns URL) |
| POST | /purchase_orders/:id/forward | Forward PO to supplier |
| POST | /purchase_orders/:id/receiving_items | Record item delivery |
| DELETE | /purchase_orders/:id/cancel_receiving_items | Cancel delivery receipt |
| PATCH | /purchase_orders/:id/complete_delivery | Mark delivery complete |
| GET | /purchase_orders/pending_request_count | Count pending approvals |
| POST | /purchase_orders/bulk_save | Bulk create POs |
| POST | /purchase_orders/approver_list | Preview approval routing |
| GET | /purchase_orders/auto_approvers_list | Get auto-assigned approvers |

**List Filters (`GET /purchase_orders`):**
- `page` (optional, integer, default: 1)
- `search` (optional) — matches PO number, supplier name, notes, line item descriptions
- `status` (optional) — `"draft"`, `"pending"`, `"approved"`, `"rejected"`, `"cancelled"`, `"paid"`
- `delivery_status` (optional) — `"not_delivered"`, `"partially_delivered"`, `"complete_delivered"`
- `payment_status` (optional) — `"unpaid"`, `"partially_paid"`, `"paid"`, `"invoice_received"`
- `supplier_id`, `requester_id`, `budget_id`, `filter_dept_id`, `approver_id` (all optional, integer)
- `archived` (optional, boolean, default: false)
- `date_filter` (optional) — `"current_month"`, `"current_year"`, `"last_month"`, `"last_year"`
- `from`, `to` (optional) — custom date range (company date_format)
- `updated_after` (optional) — ISO datetime for incremental sync
- `sort` (optional), `direction` (optional, `"asc"` or `"desc"`)
- `requests` (optional, boolean) — include pending approval requests
- `bell` (optional, boolean) — with requests=true, show bell notification items only

**Create/Update Params (po_params):**
- `commit` (required for create) — `"Send"` (submit for approval) or `"Draft"` (save as draft)
- `creator_id` (required for create, integer) — from `GET /currentuser`
- `supplier_id` (optional, integer)
- `supplier_name` (optional, string) — display name for existing supplier
- `new_supplier_name` (optional, string) — create supplier inline
- `department_id` (optional, integer)
- `currency_id` (optional, integer) — defaults to company/user currency
- `notes` (optional, string)
- `submitted_on` (optional, string — company date_format)
- `on_behalf_of` (optional, integer) — companyadmin only
- `approver_list` (optional, integer array) — override default approvers
- `purchase_order_items_attributes` (required, array, min 1):
  - `id` (for updates), `_destroy` (to remove), `sequence_no`
  - `description` (required), `quantity` (required), `unit_price` (required)
  - `budget_id`, `vat`, `tax_rate_id`, `item_number`, `department_id`, `product_id`
  - `chart_of_account_id`, `qbo_customer_id`, `quickbooks_class_id`, `qbo_line_description`
  - `net_amount`
  - `xero_id`, `zapier_id`, `quickbooks_id`
  - `purchase_order_item_allocations_attributes`: `[{id?, _destroy?, department_id, budget_id, gl_code, percentage, amount}]`
  - `custom_field_values_attributes`: `[{id?, value, custom_field_id}]`
  - `third_party_id_mappings_attributes`: `[{service, third_party_id, realm_id}]`
- `custom_field_values_attributes` (optional, array) — PO-level: `[{id?, value, custom_field_id}]`
- `purchase_order_comments_attributes` (optional, array) — `[{comment, creator_id}]`
- `uploads_attributes` (optional, array) — `[{file, creator_id}]`

**Approve/Reject:**
- `token` (required, string) — from PO details → `approver_requests[].accept_token` or `reject_token`

**Response Fields:**

`PurchaseOrderSerializer` (list):
- `id`, `approval_key`, `creator_name`, `amount`, `status`, `supplier_name`
- `keywords`, `created_at`, `currency_id`, `currency_symbol`, `currency_iso_code`
- `total_gross_amount`, `total_net_amount`, `base_gross_amount`
- `submitted_on`, `share_key`, `department_id`, `department_name`
- `compliance_status`, `delivered_on`, `delivery_status`, `payment_status`
- `xero_export_status`, `synced_with_xero`, `xero_is_changed`
- `approver_requests[]`

`PurchaseOrderDetailsSerializer` (show): All list fields plus:
- `company_id`, `supplier_id`, `external_vendor_id`, `creator_id`, `creator_email`, `creator_network_id`
- `notes`, `updated_at`, `custom_fields`, `archived`, `conversion_rate`
- `self_approved`, `xero_id`, `xero_export_error_message`, `xero_last_export_at`
- `slug`, `aff_link`
- Permissions: `can_cancel`, `can_archive`, `can_mark_as_paid`, `can_override`, `can_receive_item`, `can_cancel_receiving_items`, `can_edit`, `can_complete_delivery`, `can_copy`, `can_justify`
- `completely_delivered`, `statuses`, `budgets`, `tax_rates`, `approvers_with_flow`
- `latest_compliance_check`, `has_global_policies`
- Relationships: `purchase_order_items[]`, `purchase_order_comments[]`, `custom_field_values[]`, `payments[]`, `uploads[]`, `invoices[]`, `compliance_checks[]`, `approver_requests[]`, `supplier`

`PurchaseOrderItemSerializer`:
- `id`, `description`, `purchase_order_id`, `budget_id`, `budget_summary`
- `gross_amount`, `vat`, `tax_rate`, `net_amount`, `quantity`, `unit_price`
- `item_number`, `base_net_amount`, `base_gross_amount`, `gross_usd_amount`
- `product_id`, `received_quantity`, `sequence_no`
- `custom_field_values[]`
- `chart_of_account` (`{id, name}`), `qbo_customer` (`{id, name}`), `quickbooks_class` (`{id, name}`)
- `qbo_line_description`, `third_party_id_mappings` (conditional)

**PO Status Flow:**
```
draft → (commit: "Send") → pending → (approve) → approved → (payment) → paid
                                   → (reject) → rejected
                                   → (cancel) → cancelled
approved → (archive) → archived
```

**Curl Examples:**

```bash
# List POs (filtered)
curl -s "http://localhost:3000/api/v1/purchase_orders?page=1&status=pending" \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID"

# Create PO
curl -s -X POST http://localhost:3000/api/v1/purchase_orders \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "commit": "Send",
    "creator_id": 1,
    "supplier_id": 5,
    "department_id": 2,
    "notes": "Office supplies Q1",
    "purchase_order_items_attributes": [
      {"description": "Printer Paper", "quantity": 10, "unit_price": 25.00, "budget_id": 1},
      {"description": "Ink Cartridges", "quantity": 5, "unit_price": 45.00, "budget_id": 1}
    ]
  }'

# Approve PO (token from PO details → approver_requests[].accept_token)
curl -s -X POST http://localhost:3000/api/v1/purchase_orders/123/approve \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID" \
  -H "Content-Type: application/json" \
  -d '{"token": "ACCEPT_TOKEN"}'

# Generate PDF
curl -s http://localhost:3000/api/v1/purchase_orders/123/generate_pdf \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID"
```

**Backend Source:** `purchase_orders_controller.rb`, `comments_controller.rb`, `purchase_order_serializer.rb`, `purchase_order_details_serializer.rb`, `purchase_order_item_serializer.rb`

---

### references/invoices.md

**Covers:** Full invoice lifecycle — CRUD, accept, approve, reject, cancel, archive, comments, PO linking

**Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | /invoices | List invoices (paginated) |
| GET | /invoices/:id | Show invoice details |
| POST | /invoices | Create invoice |
| PUT | /invoices/:id | Update invoice |
| PATCH | /invoices/:id/accept | Accept (awaiting_review → outstanding) |
| PATCH | /invoices/:id/approve | Approve invoice |
| PATCH | /invoices/:id/reject | Reject invoice |
| PATCH | /invoices/:id/cancel | Cancel invoice |
| PATCH | /invoices/:id/archive | Archive invoice |
| PATCH | /invoices/:id/dearchive | Restore archived invoice |
| PATCH | /invoices/:id/rerun_approval_flow | Rerun approval routing |
| POST | /invoices/:id/create_comment | Add comment |
| GET | /invoices/purchase_order_list | Get linkable POs |
| GET | /invoices/purchase_order_item_list | Get PO line items for linking |

**List Filters (`GET /invoices`):**
- `page` (optional, integer, default: 1)
- `per_page` (optional, integer) — allowed: 10, 20, 50, 100
- `search` (optional) — matches invoice number, supplier name
- `invoice_statuses_filter` (optional) — `"awaiting_review"`, `"outstanding"`, `"ready_to_pay"`, `"settled"`, `"cancelled"`
- `supplier_id`, `requester_id`, `approver_id`, `department_id` (all optional, integer)
- `archived` (optional, boolean, default: false)
- `invoice_date_filter` (optional) — `"last 7days"`, `"last 30days"`, `"last 60days"`, `"last 90days"`, `"last 180days"`, `"last 1year"`, `"current_month"`, `"current_year"`, `"last_month"`, `"last_year"`
- `sage_exported` (optional, boolean)
- `sort` (optional), `direction` (optional, `"asc"` or `"desc"`)

**Create/Update Params (invoice_params):**
- `invoice_number` (optional, string)
- `issue_date`, `uploaded_date`, `received_date`, `due_date`, `validation_date` (optional, string — company date_format)
- `gross_amount` (optional, number)
- `currency_id` (optional, integer)
- `supplier_id` (optional, integer)
- `standalone_invoice` (optional, boolean) — true if not linked to any PO
- `digital_invoice` (optional, boolean)
- `confidence_score` (optional, number)
- `payment_term_id` (optional, integer)
- `sage_exported` (optional, boolean)
- `selected_purchase_order_ids` (optional, integer array) — POs to link
- `invoice_line_items_attributes` (optional, array):
  - `id` (for updates), `_destroy` (to remove), `sequence_no`
  - `description`, `unit_price`, `quantity`, `vat`, `net_amount`, `base_net_amount`
  - `tax_rate_id`, `chart_of_account_id`, `qbo_customer_id`, `quickbooks_class_id`, `qbo_line_description`
  - `purchase_order_id`, `purchase_order_item_id` — link to specific PO item
  - `billable_status`
  - `custom_field_values_attributes`: `[{id?, value, custom_field_id}]`
- `custom_field_values_attributes` (optional, array) — invoice-level: `[{id?, value, custom_field_id}]`
- `supplier_invoice_uploads_attributes` (optional, array) — `[{file, _destroy?}]`

`POST /invoices/:id/create_comment`:
- `comment` (required, string)

**Response Fields:**

`InvoiceSerializer` (list):
- `id`, `invoice_number`, `status`, `issue_date`, `validation_date`, `uploaded_date`, `due_date`
- `tax_amount`, `net_amount`, `gross_amount`, `balance_amount`
- `supplier_id`, `supplier_name`, `purchase_order_references`
- `can_accept`, `can_approve`, `can_reject`, `can_cancel`, `can_archive`, `can_dearchive`
- `standalone_invoice`, `confidence_score`, `digital_invoice`
- `payment_term_id`, `payment_terms_list[]`
- `xero_export_status`, `xero_is_changed`
- Relationships: `currency`

`InvoiceDetailSerializer` (show): All list fields plus:
- `created_at`, `updated_at`, `sage_exported`, `selected_purchase_order_ids[]`
- `xero_export_error_message`, `xero_last_export_at`
- Relationships: `currency`, `supplier`, `invoice_line_items[]`, `purchase_orders[]`, `supplier_invoice_uploads[]`, `histories[]`, `comments[]`, `npayments[]`

**Invoice Status Flow:**
```
awaiting_review → (accept) → outstanding → (approve) → ready_to_pay → (payment) → settled
                                        → (reject) → rejected
                                        → (cancel) → cancelled
Any status → (archive) → archived → (dearchive) → previous status
```

**Curl Examples:**

```bash
# List outstanding invoices
curl -s "http://localhost:3000/api/v1/invoices?page=1&invoice_statuses_filter=outstanding" \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID"

# Create invoice linked to POs
curl -s -X POST http://localhost:3000/api/v1/invoices \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "invoice_number": "INV-2024-001",
    "issue_date": "2024-01-15",
    "supplier_id": 5,
    "currency_id": 1,
    "selected_purchase_order_ids": [123, 124],
    "invoice_line_items_attributes": [
      {"description": "Office Supplies", "quantity": 1, "unit_price": 500.00, "tax_rate_id": 1}
    ]
  }'

# Accept invoice
curl -s -X PATCH http://localhost:3000/api/v1/invoices/1/accept \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID"
```

**Backend Source:** `invoices_controller.rb`, `invoice_serializer.rb`, `invoice_detail_serializer.rb`

---

### references/approval-flows.md

**Covers:** Approval flow CRUD, publish/unpublish, run history, versions, condition schema

**Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | /approval_flows | List flows |
| GET | /approval_flows/:id | Show flow with steps + conditions |
| POST | /approval_flows | Create flow |
| PUT | /approval_flows/:id | Update flow |
| DELETE | /approval_flows/:id | Delete flow |
| POST | /approval_flows/:id/archive | Archive flow |
| POST | /approval_flows/:id/publish | Publish (activate) |
| POST | /approval_flows/:id/unpublish | Unpublish (deactivate) |
| GET | /approval_flows/:id/runs | List flow runs |
| GET | /approval_flows/:id/show_entity | Show entity in flow |
| GET | /approval_flows/:id/versions | List versions |
| GET | /approval_flows/:id/version_details | Version details |
| POST | /approval_flows/rerun_approval_flows | Batch rerun |

**List Filters (`GET /approval_flows`):**
- `search` (optional, string) — search by name
- `page` (optional, integer)
- `sort` (optional), `direction` (optional, `"asc"` or `"desc"`)

**Runs Filters (`GET /approval_flows/:id/runs`):**
- `keyword` (optional, string)
- `status` (optional, string)
- `date_range` (optional), `date_from`, `date_to` (optional)
- `page` (optional, integer)

**Create/Update Params (approval_flow_params):**
- `name` (required for create, string)
- `document_type` (required for create) — `"purchase_order"` or `"invoice"`
- `self_approval_allowed` (optional, boolean)
- `approval_conditions_attributes` (optional, array) — **flow-level** conditions:
  - `id` (for updates), `property`, `operator`, `value`, `custom_field_id` (for custom fields), `_destroy`
- `approval_steps_attributes` (optional, array):
  - `id` (for updates), `step_no` (required, integer), `all_should_approve` (required, boolean), `_destroy`
  - `approval_step_approvers_attributes`: `[{id?, user_id, _destroy?}]`
  - `approval_conditions_attributes`: `[{id?, property, operator, value, custom_field_id?, _destroy?}]` — **step-level** conditions

**Condition Schema:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `property` | string | Yes | What to evaluate (see below) |
| `operator` | string | Yes | How to compare (see below) |
| `value` | string | Yes | Value to compare against |
| `custom_field_id` | integer | For custom fields | Custom field ID |

**Properties:** `budget`, `department`, `supplier`, `requester`, `gross_amount`, `net_amount`, `custom_field_<id>`

**Operators:** `equals`, `not_equals`, `greater_than`, `less_than`, `is_any_of`, `is_none_of`, `exists`, `not_exists`, `contains`, `not_contains`

**Response Fields:**

`ApprovalFlowSerializer` (list):
- `id`, `name`, `document_type`, `self_approval_allowed`, `company_id`
- `version_no`, `archived`, `status`
- `in_progress_entities_count`, `completed_entities_count`, `rejected_entities_count`, `total_entities_count`
- `created_at`, `updated_at`

`ApprovalFlowDetailSerializer` (show): Same plus `approval_steps[]` (each with `approval_step_approvers[]` and `approval_conditions[]`) and flow-level `approval_conditions[]`

**Curl Examples:**

```bash
# Create 2-step approval flow
curl -s -X POST http://localhost:3000/api/v1/approval_flows \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Engineering PO Approval",
    "document_type": "purchase_order",
    "self_approval_allowed": false,
    "approval_conditions_attributes": [
      {"property": "department", "operator": "equals", "value": "5"}
    ],
    "approval_steps_attributes": [
      {
        "step_no": 1,
        "all_should_approve": false,
        "approval_step_approvers_attributes": [{"user_id": 10}],
        "approval_conditions_attributes": [
          {"property": "gross_amount", "operator": "less_than", "value": "10000"}
        ]
      },
      {
        "step_no": 2,
        "all_should_approve": true,
        "approval_step_approvers_attributes": [{"user_id": 10}, {"user_id": 11}]
      }
    ]
  }'

# Publish flow
curl -s -X POST http://localhost:3000/api/v1/approval_flows/1/publish \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID"

# List flow runs
curl -s "http://localhost:3000/api/v1/approval_flows/1/runs?page=1&status=in_progress" \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID"
```

**Backend Source:** `approval_flows_controller.rb`, `approval_flow_serializer.rb`, `approval_flow_detail_serializer.rb`

---

### references/budgets-departments.md

**Covers:** Budget and department CRUD with associations

**Department Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | /departments | List departments |
| GET | /departments/:id | Show department |
| POST | /departments | Create department |
| PUT | /departments/:id | Update department |

**Department Filters:**
- `archived` (optional, string "true"/"false")
- `company_specific` (optional, string "true"/"false")

**Department Params (department_params):**
- `name` (required for create)
- `archived` (optional, boolean)
- `contact_person`, `phone_number`, `email`, `address`, `tax_number` (all optional)
- `budget_ids` (optional, integer array)
- `user_ids` (optional, integer array)

**Department Response (DepartmentSerializer):**
- `id`, `name`, `company_id`, `archived`
- `contact_person`, `tax_number`, `phone_number`, `address`, `email`
- `supplier_ids[]`, `budget_ids[]`
- `created_at`, `updated_at`

---

**Budget Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | /budgets | List budgets |
| GET | /budgets/:id | Show budget |
| POST | /budgets | Create budget |
| PUT | /budgets/:id | Update budget |

**Budget Filters:**
- `archived` (optional, boolean)
- `department_id` (optional, integer)
- `show_mappings` (optional, boolean)

**Budget Params (budget_params):**
- `name` (required for create), `amount` (required for create, number)
- `start_date`, `end_date` (optional, string — company date_format)
- `cost_code`, `cost_type` (optional, string)
- `currency_id`, `creator_id` (optional, integer)
- `allow_anyone_to_approve_a_po` (optional, boolean)
- `chart_of_account_id` (optional, integer)
- `qbo_class` (optional, string)
- `xero_id`, `zapier_id`, `quickbooks_id` (optional, string)
- `approver_ids` (optional, integer array)
- `department_ids` (optional, integer array)
- `custom_field_values_attributes` (optional, array) — `[{id?, value, custom_field_id}]`
- `third_party_id_mappings_attributes` (optional, array) — `[{service, third_party_id, realm_id}]`

**Budget Response (BudgetSerializer):**
- `id`, `company_id`, `name`, `amount`, `cost_code`, `cost_type`, `archived`
- `currency_id`, `base_amount`, `base_rate`
- `allow_anyone_to_approve_a_po`
- `start_date`, `end_date`, `summary`, `remaining_amount`
- `creator_id`, `qbo_class`
- `department_ids[]`, `approver_ids[]`
- `chart_of_account_id`, `chart_of_account_name`
- `chart_of_account` (`{id, name}`), `quickbooks_class` (`{id, name}`)
- `third_party_id_mappings` (conditional)
- `created_at`, `updated_at`

Show also returns `approved_this_month`.

**Curl Examples:**

```bash
# Create department
curl -s -X POST http://localhost:3000/api/v1/departments \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID" \
  -H "Content-Type: application/json" \
  -d '{"name": "Engineering", "budget_ids": [1, 2], "user_ids": [5, 6]}'

# Create budget
curl -s -X POST http://localhost:3000/api/v1/budgets \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID" \
  -H "Content-Type: application/json" \
  -d '{"name": "Q1 Marketing", "amount": 50000, "start_date": "2024-01-01", "end_date": "2024-03-31", "department_ids": [1], "approver_ids": [5, 6]}'

# List budgets for a department
curl -s "http://localhost:3000/api/v1/budgets?department_id=1" \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID"
```

**Backend Source:** `departments_controller.rb`, `budgets_controller.rb`, `department_serializer.rb`, `budget_serializer.rb`, `budget_details_serializer.rb`

---

### references/suppliers.md

**Covers:** Supplier CRUD, products, SKUs, top suppliers, supplier approvals

**Supplier Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | /suppliers | List suppliers |
| GET | /suppliers/:id | Show supplier |
| POST | /suppliers | Create supplier |
| PUT | /suppliers/:id | Update supplier |
| GET | /suppliers/top | Top N suppliers by usage |

**Supplier Filters:**
- `search` (optional) — name search
- `department_id` (optional, integer) — includes suppliers with no department
- `archived` (optional, boolean, default: false)
- `page` (optional) — without: returns ALL; with: 20 per page
- `show_mappings` (optional, boolean) — include third-party IDs

**Supplier Params (supplier_params):**
- `name` (required for create, must be unique)
- `email`, `address`, `phone_number`, `notes`, `payment_details`, `tax_number`, `contact_person` (all optional)
- `archived` (optional, boolean — update only)
- `uei` (optional) — SAM.gov Unique Entity Identifier
- `cage_code` (optional) — government contracting
- `xero_id`, `zapier_id`, `quickbooks_id` (optional)
- `department_ids` (optional, integer array)
- `third_party_id_mappings_attributes` (optional, array) — `[{service, third_party_id, realm_id}]`

**Note:** If company has `add_supplier_approval` enabled and user is not `supplier_approver`, creates a pending SupplierApproval instead.

**Supplier Response (SupplierSerializer):**
- `id`, `name`, `company_id`, `archived`
- `email`, `phone_number`, `address`, `contact_person`
- `notes`, `payment_details`, `tax_number`
- `payment_terms`, `currency_id`
- `department_ids[]`, `external_vendor_id`
- `uei`, `cage_code`
- `third_party_id_mappings` (conditional)
- `created_at`, `updated_at`

---

**Product Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | /products | List products |
| GET | /products/:id | Show product |
| POST | /products | Create product |
| PUT | /products/:id | Update product |
| POST | /products/bulk_create | Bulk create products |
| GET | /products/skus | Search SKUs |

**Product Filters:**
- `supplier_id` (optional, integer)
- `archived` (optional, boolean)
- `page` (optional) — without: returns ALL; with: paginated
- `per_page` (optional, default: 20)

**Product Params (product_params):**
- `description` (required), `supplier_id` (required, integer)
- `sku` (optional, string), `unit_price` (optional, number)

**Bulk Create:** `product_item_attributes` array of `[{sku, description, unit_price}]` + `supplier_id`

**SKU Search:** `GET /products/skus?query=<search_term>`

**Product Response (ProductSerializer):**
- `id`, `supplier_id`, `sku`, `description`, `unit_price`
- `currency_id`, `archived`, `tax_rate_id`
- `created_at`, `updated_at`

**Curl Examples:**

```bash
# List suppliers (paginated)
curl -s "http://localhost:3000/api/v1/suppliers?page=1&search=acme" \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID"

# Create supplier
curl -s -X POST http://localhost:3000/api/v1/suppliers \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID" \
  -H "Content-Type: application/json" \
  -d '{"name": "Acme Corp", "email": "sales@acme.com", "department_ids": [1]}'

# Create product
curl -s -X POST http://localhost:3000/api/v1/products \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID" \
  -H "Content-Type: application/json" \
  -d '{"description": "Office Chair", "supplier_id": 1, "sku": "CH-001", "unit_price": 299.99}'
```

**Backend Source:** `suppliers_controller.rb`, `products_controller.rb`, `supplier_serializer.rb`, `product_serializer.rb`

---

### references/payments.md

**Covers:** Invoice payments (npayments) and PO-specific payments

**Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | /npayments/:id | Show payment details |
| POST | /npayments | Create payment (invoices + POs) |
| POST | /purchase_orders/:id/payments | Create PO-specific payment |

**Create Payment Params (npayment_params):**
- `reference` (optional, string) — payment reference number
- `status` (optional, string)
- `ptype` (optional, string) — payment type
- `date` (optional, string — company date_format)
- `amount` (optional, number)
- `supplier_id` (optional, integer)
- `currency_id` (optional, integer)
- `payment_mode` (optional, string)
- `user_id` (optional, integer)
- `npayment_link_orders_attributes` (optional, array) — link to POs:
  - `id`, `npayment_id`, `purchase_order_id`, `budget_id`, `gross_amount`, `_destroy`
- `npayment_invoices_attributes` (optional, array) — link to invoices:
  - `id`, `npayment_id`, `invoice_id`, `gross_amount`, `_destroy`
- `npayment_comments_attributes` (optional, array):
  - `id`, `comment`, `creator_id`, `system_generated`

**PO Payment Params (payment_params):**
- `amount` (required, number)
- `note` (optional, string)
- `purchase_order_item_payments_attributes` (optional, array):
  - `id`, `amount`, `purchase_order_item_id`

**Response Fields:**

`NpaymentSerializer` (list):
- `id`, `reference`, `status`, `ptype`, `date`, `amount`

`NpaymentDetailSerializer` (show):
- `id`, `reference`, `status`, `ptype`, `date`, `amount`
- `created_at`, `updated_at`, `payment_mode`, `archived`, `conversion_rate`
- Relationships: `currency`, `supplier`, `user`, `invoices[]`, `npayment_comments[]`

**Curl Examples:**

```bash
# Create invoice payment
curl -s -X POST http://localhost:3000/api/v1/npayments \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "reference": "PAY-2024-001",
    "date": "2024-01-20",
    "amount": 1500.00,
    "supplier_id": 5,
    "currency_id": 1,
    "payment_mode": "bank_transfer",
    "npayment_invoices_attributes": [
      {"invoice_id": 10, "gross_amount": 1500.00}
    ]
  }'

# Create PO payment (item-level)
curl -s -X POST http://localhost:3000/api/v1/purchase_orders/123/payments \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 500.00,
    "note": "Partial payment",
    "purchase_order_item_payments_attributes": [
      {"purchase_order_item_id": 1, "amount": 300.00},
      {"purchase_order_item_id": 2, "amount": 200.00}
    ]
  }'
```

**Backend Source:** `npayments_controller.rb`, `payments_controller.rb`, `npayment_serializer.rb`, `npayment_detail_serializer.rb`

---

### references/settings.md

**Covers:** Tax rates, currencies, chart of accounts (GL codes), custom fields

**Tax Rate Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | /tax_rates | List tax rates |
| GET | /tax_rates/:id | Show tax rate |
| POST | /tax_rates | Create tax rate |
| PUT | /tax_rates/:id | Update tax rate |

**Tax Rate Filters:** `archived` (optional, boolean)

**Tax Rate Params:** `name` (required), `value` (required, number — percentage), `archived` (optional)

**Tax Rate Response:** `id`, `name`, `value`, `archived`, `company_id`, `tax_type`, `tax_rate_items[]`, `created_at`, `updated_at`

---

**Currency Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | /currencies | Company currencies |
| GET | /all_currencies | All available currencies |

No params. Returns currency objects.

---

**Chart of Accounts Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | /chart_of_accounts | List GL codes |
| GET | /chart_of_accounts/:id | Show GL code |

**Filters:** `search` (optional), `page` (optional), `per_page` (optional)

**Response (ChartOfAccountSerializer):** `id`, `name`, `classification`, `account_type`, `currency_code`, `account_number`, `display_name`, `archived`, `company_id`

---

**Custom Fields:**
Custom field definitions come from `GET /companies/details` → `custom_fields[]`.
Custom field values are set on POs, invoices, budgets, and line items via `custom_field_values_attributes`.

**Curl Examples:**

```bash
# List tax rates
curl -s http://localhost:3000/api/v1/tax_rates \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID"

# Create tax rate
curl -s -X POST http://localhost:3000/api/v1/tax_rates \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID" \
  -H "Content-Type: application/json" \
  -d '{"name": "VAT 20%", "value": 20}'

# List GL codes
curl -s "http://localhost:3000/api/v1/chart_of_accounts?search=office&page=1" \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID"
```

**Backend Source:** `tax_rates_controller.rb`, `chart_of_accounts_controller.rb`, `tax_rate_serializer.rb`, `chart_of_account_serializer.rb`

---

### references/webhooks-integrations.md

**Covers:** Webhooks, QuickBooks customers/classes, email templates

**Webhook Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | /webhooks | List webhooks |
| GET | /webhooks/:id | Show webhook detail |
| POST | /webhooks | Create webhook |
| PUT | /webhooks/:id | Update webhook |
| DELETE | /webhooks/:id | Delete webhook |

**Webhook Filters:** `archived` (optional, boolean)

**Webhook Params (webhook_params):**
- `name` (required), `url` (required)
- `event_type` (required, array) — e.g. `["purchase_order_approved", "purchase_order_rejected"]`
- `authentication_header` (optional, string)
- `json_wrapper` (optional, string)
- `send_as_text` (optional, boolean)
- `basic_auth_uname`, `basic_auth_pword` (optional, string)
- `archived`, `tested` (optional, boolean)
- `webhook_attributes_attributes` (optional, array) — `[{id?, attrib_type, key, value, _destroy?}]`

**Webhook Response:**

List: `id`, `name`, `url`, `archived`, `event_type[]`, `tested`, `response_code`, `json_wrapper`

Detail: Same plus `send_as_text`, `basic_auth_uname`, `basic_auth_pword`, `webhook_attributes[]` (each: `{id, attrib_type, key, value}`)

---

**QuickBooks Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | /qbo_customers | List QBO customers |
| GET | /qbo_customers/:id | Show QBO customer |
| GET | /qbo_classes | List QBO classes |
| GET | /qbo_classes/:id | Show QBO class |

**Shared Filters:** `search` (optional), `page` (optional), `per_page` (optional)

**QBO Customer Response:** `id`, `fully_qualified_name`, `archived`, `company_id`

---

**Email Template Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | /send_to_supplier_templates | List email templates |

No params. Returns list of email templates for forwarding POs to suppliers.

**Curl Examples:**

```bash
# Create webhook
curl -s -X POST http://localhost:3000/api/v1/webhooks \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID" \
  -H "Content-Type: application/json" \
  -d '{"name": "PO Approved", "url": "https://hooks.example.com/po", "event_type": ["purchase_order_approved"]}'

# List QBO customers
curl -s "http://localhost:3000/api/v1/qbo_customers?search=acme&page=1" \
  -H "authentication_token: TOKEN" \
  -H "app_company_id: COMPANY_ID"
```

**Backend Source:** `webhooks_controller.rb`, `qbo_customers_controller.rb`, `qbo_classes_controller.rb`, `send_to_supplier_templates_controller.rb`, `webhook_serializer.rb`, `webhook_detail_serializer.rb`, `qbo_customer_serializer.rb`

---

## Implementation Instructions

### Step 1: Create the skill directory
```bash
mkdir -p procurementexpress-api/references
```

### Step 2: Generate SKILL.md
Use the SKILL.md spec above. Keep it under 300 lines. Include:
- YAML frontmatter
- Quick Start section with login curl
- Shared Conventions
- API Domain Index (table linking to references)
- Endpoint Quick Reference (compact table of ALL endpoints)

### Step 3: Generate reference files (in order)
1. `references/authentication.md`
2. `references/company-users.md`
3. `references/budgets-departments.md`
4. `references/suppliers.md`
5. `references/settings.md`
6. `references/webhooks-integrations.md`
7. `references/purchase-orders.md`
8. `references/invoices.md`
9. `references/payments.md`
10. `references/approval-flows.md`

### Step 4: Verify
1. Validate YAML frontmatter: `python3 skill-creator/scripts/quick_validate.py`
2. Test curl examples against running local server
3. Cross-check params against controllers
4. Cross-check response fields against serializers

## Migration Notes

### What to delete after migration
- All 10 existing skills in `skills/pex-*/`
- The old MCP-based frontmatters and tool references

### What carries over
- Line item schemas (adapted from `pex-purchase-orders/references/line-items.md`)
- Condition schemas (adapted from `pex-approval-flows/references/conditions.md`)
- Status flow diagrams
- All endpoint documentation (converted from MCP tool format to curl format)
