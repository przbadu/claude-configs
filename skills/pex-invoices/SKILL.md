---
name: pex:invoices
description: >
  ProcurementExpress invoice management via CLI. Covers creating, updating, accepting,
  approving, rejecting, cancelling, archiving invoices, and adding comments. Handles the
  full invoice lifecycle from receipt through approval to settlement.
  CLI commands: pex invoice list|show|create|update|accept|approve|reject|cancel|archive|
  dearchive|rerun-flow. Also: pex comment add-invoice.
  Triggers on: invoice, bill, invoice approval, invoice status, awaiting review,
  outstanding invoice, ready to pay, invoice comment, invoice line items.
---

# ProcurementExpress Invoices

## Prerequisites

Authenticate and set active company first (pex:setup skill).

## List & Show

```bash
pex invoice list --status=outstanding --page=1 --per-page=20
pex invoice list --search="INV-001" --supplier-id=10
pex invoice list --date-filter="last 30days" --sort=invoices.created_at --direction=desc
pex invoice list --department-id=5 --archived --sage-exported

pex invoice show 456
```

### Status Filter Values
`awaiting_review`, `outstanding`, `ready_to_pay`, `settled`, `cancelled`

### Date Filter Values
`last 7days`, `last 30days`, `last 60days`, `last 90days`, `last 180days`, `last 1year`, `current_month`, `current_year`, `last_month`, `last_year`

## Create

```bash
pex invoice create \
  --invoice-number="INV-2024-001" \
  --supplier-id=10 \
  --issue-date="2024-03-01" \
  --due-date="2024-04-01" \
  --gross-amount=5000 \
  --currency-id=1 \
  --po-ids=123,456 \
  --line-items='[
    {"description":"Laptops","unit_price":1200,"quantity":5,"purchase_order_id":123}
  ]'
```

- `--standalone`: flag for invoices not linked to any PO
- `--payment-term-id`: from company settings
- `--custom-fields`: JSON array of `[{"value":"x","custom_field_id":1}]`

### Line Item Fields

Each line item object supports:
- `description`, `unit_price`, `quantity`, `vat`, `net_amount`, `sequence_no`
- `tax_rate_id`, `chart_of_account_id`, `qbo_customer_id`, `quickbooks_class_id`
- `purchase_order_id`, `purchase_order_item_id` — link to PO line item
- `billable_status` — for QuickBooks

## Update

```bash
pex invoice update 456 --invoice-number="INV-2024-001-R" --due-date="2024-05-01"
pex invoice update 456 --line-items='[{"id":200,"quantity":10},{"id":201,"_destroy":true}]'
```

## Approval Lifecycle

```bash
pex invoice accept 456      # awaiting_review → outstanding
pex invoice approve 456     # outstanding → ready_to_pay
pex invoice reject 456      # → rejected
pex invoice cancel 456      # → cancelled
pex invoice archive 456     # archive
pex invoice dearchive 456   # restore from archive
pex invoice rerun-flow 456  # rerun approval flow when rules changed
```

### Status Flow

```
awaiting_review → accept → outstanding → approve → ready_to_pay → payment → settled
                                       → reject → rejected
                                       → cancel → cancelled
```

## Comments

```bash
pex comment add-invoice 456 --comment="Payment scheduled for next week"
```

## Key Response Fields

- `id`, `invoice_number`, `status`, `gross_amount`, `net_amount`, `balance_amount`
- `issue_date`, `due_date`, `supplier`, `currency`
- `standalone_invoice` — whether linked to POs
- `confidence_score`, `digital_invoice` — AI extraction info
- `invoice_line_items[]` — line items with amounts
- `purchase_orders[]` — linked PO summaries
- `comments[]`, `histories[]` — comments and status history
- `npayments[]` — payment records
- Action flags: `can_accept`, `can_approve`, `can_reject`, `can_cancel`, `can_archive`, `can_dearchive`
