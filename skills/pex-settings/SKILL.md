---
name: pex:settings
description: >
  ProcurementExpress settings, reference data, and integrations via CLI. Covers tax rates,
  webhooks, currencies, chart of accounts (GL codes), QuickBooks customers/classes, and
  send-to-supplier templates. CLI commands: pex tax-rate, pex webhook, pex currency,
  pex chart-of-account, pex qbo-customer, pex qbo-class, pex template, pex company details.
  Triggers on: tax rate, VAT, webhook, currency, chart of accounts, GL code, QuickBooks,
  QBO customer, QBO class, accounting integration, company settings, custom fields, templates.
---

# ProcurementExpress Settings & Reference Data

## Prerequisites

Authenticate and set active company first (pex:setup skill).

## Company Settings & Custom Fields

```bash
pex company details  # full settings, custom fields, currencies, payment terms
```

Key settings in `company_setting`:
- `date_format` — date format for all date fields across the API
- `currency_id` — default currency
- `gross_or_net` — whether amounts are gross or net
- `approval_flow_enabled`, `invoice_enabled`

## Tax Rates

```bash
pex tax-rate list
pex tax-rate list --archived
pex tax-rate show 5
pex tax-rate create --name="VAT 20%" --value=20
pex tax-rate update 5 --value=21 --archived
```

## Currencies

```bash
pex currency list       # company-enabled currencies
pex currency list-all   # all available currencies globally
```

## Webhooks

Webhooks fire HTTP POST on PO lifecycle events.

```bash
pex webhook list
pex webhook show 8
pex webhook create --name="Slack Notify" \
  --url="https://hooks.slack.com/..." \
  --event-type=new_po,po_approved,po_cancelled \
  --basic-auth-uname=user --basic-auth-pword=pass

pex webhook update 8 --event-type=new_po,po_approved --archived
pex webhook delete 8
```

### Event Types
`new_po`, `po_approved`, `po_delivered`, `po_paid`, `po_cancelled`, `po_update`

### Options
- `--name`, `--url`, `--event-type` (required for create, comma-separated)
- `--json-wrapper` — root key for JSON payload
- `--send-as-text` — send as text instead of JSON
- `--basic-auth-uname`, `--basic-auth-pword` — basic auth
- `--attributes` — JSON array: `[{"attrib_type":"header","key":"X-Custom","value":"val"}]`

## Chart of Accounts (GL Codes)

Used for accounting classification on PO/invoice line items.

```bash
pex chart-of-account list --search="office" --page=1 --per-page=50
pex chart-of-account show 15
```

## QuickBooks Integration

```bash
# Customers
pex qbo-customer list --search="acme"
pex qbo-customer show 20

# Classes
pex qbo-class list --search="consulting"
pex qbo-class show 12
```

## Send-to-Supplier Templates

```bash
pex template list  # email templates for forwarding POs
```

## Where Reference Data Is Used

| Data | Used In |
|------|---------|
| Tax rates | PO line items (`tax_rate_id`), invoice line items, products |
| Currencies | Budgets, POs, invoices, payments, suppliers |
| Chart of accounts | PO line items, invoice line items, budgets |
| QBO customers | PO line items, invoice line items |
| QBO classes | PO line items, invoice line items, budgets |
| Custom fields | POs, invoices, budgets, line items — from `pex company details` |
