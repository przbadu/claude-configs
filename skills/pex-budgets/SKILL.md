---
name: pex:budgets
description: >
  ProcurementExpress budget management via CLI. Use when listing, viewing, creating, or
  updating budgets (cost centers). CLI commands: pex budget list|show|create|update.
  Triggers on: budget, cost center, spending limit, budget allocation, remaining budget,
  budget approvers.
---

# ProcurementExpress Budgets

## Prerequisites

Authenticate and set active company first (pex:setup skill).

## Commands

```bash
# List
pex budget list
pex budget list --department-id=5 --archived --show-mappings

# Show
pex budget show 123

# Create
pex budget create --name="Q1 Marketing" --amount=50000 \
  --currency-id=1 --start-date="2024-01-01" --end-date="2024-03-31" \
  --department-ids=5,6 --approver-ids=10,20 \
  --cost-code="MKT-Q1" --chart-of-account-id=15

# Update
pex budget update 123 --amount=75000 --end-date="2024-06-30"
```

### Create/Update Options

- `--name`, `--amount` (required for create)
- `--currency-id` — defaults to company currency
- `--creator-id`, `--cost-code`, `--cost-type`
- `--start-date`, `--end-date` — must match company `date_format`
- `--allow-anyone-to-approve` — bypass approver restrictions
- `--chart-of-account-id` — GL code
- `--qbo-class` — QuickBooks class
- `--approver-ids` — comma-separated approver user IDs
- `--department-ids` — comma-separated department IDs
- `--custom-fields` — JSON array: `[{"value":"x","custom_field_id":1}]`

## Key Response Fields

- `id`, `name`, `amount`, `remaining_amount`, `currency_id`
- `cost_code`, `cost_type`, `archived`
- `start_date`, `end_date`, `approved_this_month`
- `approver_ids[]`, `department_ids[]`
- `chart_of_account_id`, `chart_of_account_name`

## Date Format

All date fields must match the company's `date_format` setting. Get it via:
```bash
pex company details  # → company_setting.date_format
```
