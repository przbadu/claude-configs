---
name: pex:suppliers
description: >
  ProcurementExpress supplier and product management via CLI. Use when listing, viewing,
  creating, or updating suppliers (vendors) and their products (catalog items).
  CLI commands: pex supplier list|show|create|update|top and pex product list|show|create|
  update. Triggers on: supplier, vendor, product, catalog, SKU, top suppliers, supplier
  search, product list.
---

# ProcurementExpress Suppliers & Products

## Prerequisites

Authenticate and set active company first (pex:setup skill).

## Supplier Commands

```bash
# List (all or paginated with search)
pex supplier list --search="acme" --page=1
pex supplier list --department-id=5 --archived --show-mappings

# Top suppliers (most frequently used)
pex supplier top --top=10

# Show
pex supplier show 42

# Create
pex supplier create --name="Acme Corp" \
  --email="orders@acme.com" --phone-number="+1-555-0100" \
  --contact-person="John Doe" --payment-details="Wire: ACME-BANK-123" \
  --department-ids=5,6

# Update
pex supplier update 42 --address="123 Main St" --archived
```

### Create/Update Options

- `--name` (required for create, must be unique)
- `--email`, `--address`, `--notes`, `--payment-details`
- `--phone-number`, `--tax-number`, `--contact-person`
- `--department-ids` — comma-separated, restrict to departments
- `--archived` — archive flag (update only)

## Product Commands

Products are catalog items associated with a supplier. Use `product_id` on PO line items to auto-fill description, SKU, and unit price.

```bash
# List
pex product list --supplier-id=42 --page=1 --per-page=50
pex product list --archived

# Show
pex product show 99

# Create
pex product create --description="Widget A" --supplier-id=42 \
  --sku="WDG-A-001" --unit-price=9.99

# Update
pex product update 99 --unit-price=12.99
```

## Key Supplier Response Fields

- `id`, `name`, `company_id`, `archived`
- `email`, `phone_number`, `address`, `contact_person`
- `notes`, `payment_details`, `tax_number`, `payment_terms`
- `currency_id`, `department_ids[]`, `external_vendor_id`

## Key Product Response Fields

- `id`, `supplier_id`, `sku`, `description`, `unit_price`
- `currency_id`, `archived`, `tax_rate_id`
