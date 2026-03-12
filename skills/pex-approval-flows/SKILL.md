---
name: pex:approval-flows
description: >
  ProcurementExpress approval flow configuration via CLI. Use when creating, updating,
  publishing, or managing approval flows and their steps, conditions, and runs. Approval
  flows automate the routing of POs and invoices to the right approvers based on conditions.
  CLI commands: pex approval-flow list|show|create|update|delete|archive|publish|unpublish|
  runs|entity|versions|version-details|rerun.
  Triggers on: approval flow, approval workflow, approval steps, approval conditions,
  approval routing, publish flow, flow runs, flow version, rerun approval.
---

# ProcurementExpress Approval Flows

## Prerequisites

Authenticate and set active company first (pex:setup skill).
Company must have approval flows enabled (`pex company details` → `approval_flow_ff_enabled`).

## List & Show

```bash
pex approval-flow list --search="standard" --page=1 --per-page=20
pex approval-flow show 10
```

## Create

```bash
pex approval-flow create \
  --name="Standard PO Approval" \
  --document-type=0 \
  --self-approval-allowed \
  --steps='[
    {"step_no":1,"all_should_approve":false,"approver_user_ids":[10,20]},
    {"step_no":2,"all_should_approve":true,"approver_user_ids":[30],
     "conditions":[{"property":"gross_amount","operator":"greater_than","value":"10000"}]}
  ]' \
  --conditions='[
    {"property":"department","operator":"equals","value":"5"}
  ]'
```

- `--document-type`: `0` = purchase order, `1` = invoice
- `--self-approval-allowed`: flag to allow PO creator to self-approve
- `--steps`: JSON array of approval steps (executed in `step_no` order)
- `--conditions`: JSON array of flow-level conditions

### Step Fields

- `step_no` (required) — execution order
- `all_should_approve` (required) — `true` = all must approve, `false` = any one suffices
- `approver_user_ids` (required) — array of approver user IDs
- `conditions` (optional) — step-level conditions

### Condition Fields

- `property`: `budget`, `department`, `supplier`, `requester`, `gross_amount`, `net_amount`, or `custom_field_<id>`
- `operator`: `equals`, `not_equals`, `greater_than`, `less_than`, `is_any_of`, `is_none_of`, `exists`, `not_exists`, `contains`, `not_contains`
- `value`: single ID or comma-separated IDs
- `custom_field_id`: required when property is `custom_field_<id>`

### Flow-Level vs Step-Level Conditions

- **Flow-level**: determine WHICH documents match this flow (e.g., "only POs from Engineering")
- **Step-level**: determine WHICH steps activate (e.g., "step 2 only if amount > $10,000")

## Update

```bash
pex approval-flow update 10 --name="Updated Flow" \
  --steps='[
    {"id":1,"step_no":1,"all_should_approve":false,"approver_user_ids":[10,20]},
    {"id":2,"_destroy":true,"step_no":2,"all_should_approve":true,"approver_user_ids":[]},
    {"step_no":3,"all_should_approve":true,"approver_user_ids":[40,50]}
  ]'
```

Include `id` to update existing steps, `_destroy: true` to remove, omit `id` for new steps.

## Lifecycle

```bash
pex approval-flow publish 10     # make active
pex approval-flow unpublish 10   # deactivate
pex approval-flow archive 10     # soft-delete
pex approval-flow delete 10      # permanent delete
```

## Runs & History

```bash
# List documents that went through this flow
pex approval-flow runs 10 --status=in_progress --date-range=30d
pex approval-flow runs 10 --keyword="laptop" --date-from="2024-01-01" --date-to="2024-03-31"

# Entity details
pex approval-flow entity 10 --entity-id=12345

# Version history
pex approval-flow versions 10
pex approval-flow version-details 10 --version-id=3

# Rerun flows for specific POs/invoices
pex approval-flow rerun --order-ids=123,456 --invoice-ids=789
```

## Key Response Fields

- `id`, `name`, `document_type` (0=PO, 1=invoice), `status`, `version_no`
- `self_approval_allowed`, `archived`
- `approval_steps[]` — steps with approvers and conditions
- `approval_conditions[]` — flow-level conditions
- Counts: `in_progress_entities_count`, `completed_entities_count`, `rejected_entities_count`
