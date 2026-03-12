---
name: pex:purchase-orders
description: >
  ProcurementExpress purchase order (PO) management via CLI — the core procurement workflow.
  Covers creating, updating, approving, rejecting, cancelling, archiving, and deleting POs.
  Also handles delivery tracking, PDF generation, forwarding POs to suppliers, and comments.
  CLI commands: pex purchase-order (alias: pex po) list|show|create|update|approve|reject|
  override|cancel|archive|delete|pdf|forward|receive|cancel-receiving|complete-delivery|
  pending-count. Also: pex comment add-purchase-order.
  Triggers on: purchase order, PO, create PO, approve PO, reject PO, PO delivery, PO PDF,
  forward PO, PO comment, pending approvals, line items, PO status.
---

# ProcurementExpress Purchase Orders

## Prerequisites

Authenticate and set active company first (pex:setup skill).

## List & Show

```bash
# List with filters and pagination
pex po list --status=pending --page=1
pex po list --search="laptop" --supplier-id=10
pex po list --date-filter=current_month --sort=total_gross_amount --direction=desc
pex po list --delivery-status=not_delivered --payment-status=unpaid
pex po list --department-id=5 --requester-id=12 --approver-id=8
pex po list --archived --from="2024-01-01" --to="2024-12-31"
pex po list --requests --bell  # pending approval notifications
pex po list --updated-after="2024-01-01T00:00:00Z"  # incremental sync

# Show details (accepts numeric ID, approval-key, or slug)
pex po show 12345
```

## Create

At least one line item is required. Pass line items as JSON.

```bash
pex po create \
  --commit=Send \
  --creator-id=1 \
  --supplier-id=10 \
  --department-id=5 \
  --notes="Q1 office supplies" \
  --line-items='[
    {"description":"Laptops","quantity":5,"unit_price":1200,"budget_id":3},
    {"description":"Monitors","quantity":5,"unit_price":400,"tax_rate_id":2}
  ]'
```

- `--commit`: `Send` (submit for approval) or `Draft` (save as draft)
- `--creator-id`: required — get from `pex auth whoami`
- `--supplier-id` or `--supplier-name` or `--new-supplier-name`
- `--currency-id` or `--iso-code` (e.g., USD)
- `--approver-list`: comma-separated user IDs to override default approvers
- `--on-behalf-of`: user ID (companyadmin only)
- `--custom-fields`: JSON array of `[{"value":"x","custom_field_id":1}]`

### Line Item Fields

Each line item object supports:
- `description` (required), `quantity` (required), `unit_price` (required)
- `budget_id`, `vat`, `tax_rate_id`, `item_number`, `sequence_no`
- `department_id`, `product_id`, `chart_of_account_id`
- `qbo_customer_id`, `quickbooks_class_id`
- `custom_field_values_attributes`: `[{"value":"x","custom_field_id":1}]`

## Update

```bash
pex po update 12345 --notes="Updated notes" --commit=Send
pex po update 12345 --line-items='[
  {"id":100,"quantity":10},
  {"id":101,"_destroy":true},
  {"description":"New item","quantity":1,"unit_price":50}
]'
```

For line items: include `id` to update existing, `_destroy: true` to remove, omit `id` for new.

## Approval

```bash
# First get the PO to find approval tokens
pex po show 12345  # → approver_requests[].accept_token / reject_token

pex po approve 12345 --token=<accept_token>
pex po reject 12345 --token=<reject_token>
pex po override 12345  # finance role, no token needed
```

## Lifecycle

```bash
pex po cancel 12345
pex po archive 12345       # toggle archive (call again to dearchive)
pex po delete 12345        # permanent delete
pex po pending-count       # pending approval count for current user
```

## Delivery

```bash
pex po receive 12345 \
  --items='[{"id":100,"quantity":5},{"id":101,"quantity":3}]' \
  --delivered-on="2024-03-15" \
  --notes="Partial delivery"

pex po cancel-receiving 12345    # revert all deliveries
pex po complete-delivery 12345   # mark fully delivered
```

## Communication

```bash
# PDF
pex po pdf 12345  # returns { pdf_link: "..." }

# Forward to supplier
pex po forward 12345 --emails="vendor@co.com" --note="Please confirm" --subject="PO #12345"

# Comment
pex comment add-purchase-order 12345 --comment="Approved by finance"
```

## Key Response Fields

- `id`, `status`, `notes`, `total_gross_amount`, `total_net_amount`
- `supplier_name`, `department_name`, `creator_name`
- `delivery_status`, `payment_status`, `archived`
- `purchase_order_items[]` — line items with amounts, quantities, custom fields
- `approver_requests[]` — approval status with `accept_token` / `reject_token`
- `purchase_order_comments[]` — comments with creator info
- `can_cancel`, `can_archive`, `can_override`, `can_edit` — action flags
