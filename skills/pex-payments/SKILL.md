---
name: pex:payments
description: >
  ProcurementExpress payment management via CLI. Use when creating or viewing payments to
  settle invoices and purchase orders. CLI commands: pex payment show|create|create-po-payment.
  Triggers on: payment, pay invoice, pay purchase order, settle, bank transfer, payment
  record, payment type.
---

# ProcurementExpress Payments

## Prerequisites

Authenticate and set active company first (pex:setup skill).

## Commands

### Show Payment

```bash
pex payment show 789
```

### Create Payment (settle invoices and/or POs)

```bash
pex payment create \
  --supplier-id=10 \
  --ptype=bank_transfer \
  --date="2024-03-15" \
  --currency-id=1 \
  --amount=5000 \
  --reference="PAY-2024-001" \
  --invoices='[{"invoice_id":456,"gross_amount":3000}]' \
  --purchase-orders='[{"purchase_order_id":123,"gross_amount":2000}]' \
  --comments='[{"comment":"Q1 settlement"}]'
```

#### Payment Types (`--ptype`)
`bank_transfer`, `card`, `credit_card`, `check`, `cash`, `one_time_card`, `letter_of_credit`, `other`

### Create PO Payment (simpler, for a single PO)

```bash
pex payment create-po-payment 12345 --amount=1200 --note="Partial payment"

# With item-level breakdown
pex payment create-po-payment 12345 \
  --item-payments='[
    {"purchase_order_item_id":100,"amount":800},
    {"purchase_order_item_id":101,"amount":400}
  ]'
```

## Key Response Fields

- `id`, `reference`, `status`, `ptype`, `date`, `amount`
- `currency` — currency details
- `supplier` — supplier summary
- `user` — creator details
- `invoices[]` — linked invoices
- `npayment_comments[]` — comments

## Workflows

### Settle an Invoice
```
1. pex invoice show 456          # get supplier_id, gross_amount
2. pex payment create --supplier-id=10 --ptype=bank_transfer \
     --date="2024-03-15" --currency-id=1 --amount=5000 \
     --invoices='[{"invoice_id":456,"gross_amount":5000}]'
```

### Pay a Purchase Order
```
Option A: pex payment create-po-payment 12345 --amount=1200
Option B: pex payment create --supplier-id=10 ... --purchase-orders='[...]'
```
