---
name: pex:departments
description: >
  ProcurementExpress department management via CLI. Use when listing, viewing, creating, or
  updating departments (organizational units). CLI commands: pex department list|show|create|
  update. Also: pex company approvers --department-id for department-specific approvers.
  Triggers on: department, division, organizational unit, department users, department budgets.
---

# ProcurementExpress Departments

## Prerequisites

Authenticate and set active company first (pex:setup skill).

## Commands

```bash
# List (user-accessible departments by default)
pex department list
pex department list --archived --company-specific  # all company departments

# Show
pex department show 5

# Create
pex department create --name="Engineering" \
  --contact-person="Jane Smith" --email="eng@co.com" \
  --budget-ids=1,2,3 --user-ids=10,20,30

# Update
pex department update 5 --name="Product Engineering" --archived
```

### Create/Update Options

- `--name` (required for create)
- `--contact-person`, `--phone-number`, `--email`, `--address`, `--tax-number`
- `--budget-ids` — comma-separated budget IDs
- `--user-ids` — comma-separated user IDs
- `--archived` — archive flag (update only)

## Key Response Fields

- `id`, `name`, `company_id`, `archived`
- `contact_person`, `phone_number`, `email`, `address`, `tax_number`
- `supplier_ids[]`, `budget_ids[]`

## Relationships

- Departments contain users and budgets
- Departments can restrict which suppliers are available
- POs and invoices can be filtered by department
- Approvers can be filtered by department: `pex company approvers --department-id=5`
