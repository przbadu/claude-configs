# PRD Template Selection & Customization Guide

## Template Decision Tree

```
GitHub Issue received
  │
  ├─ Has labels: bug, typo, hotfix, chore?
  │   └─ YES → Standard template (unless 2+ complex signals)
  │
  ├─ Has labels: feature, enhancement, epic, refactor?
  │   └─ YES → +1 complex signal
  │
  ├─ Body > 500 chars with detailed requirements?
  │   └─ YES → +1 complex signal
  │
  ├─ Mentions multiple models, services, or controllers?
  │   └─ YES → +1 complex signal
  │
  ├─ Has >= 3 acceptance criteria items?
  │   └─ YES → +1 complex signal
  │
  └─ Requires database migration?
      └─ YES → +1 complex signal

If complex signals >= 2 → RPG template
Otherwise → Standard template
```

## Standard Template Example

For a bug fix issue like "Fix N+1 query in purchase orders index":

```markdown
<context>
# Overview
The purchase orders index API endpoint has an N+1 query problem when loading
approvers for each purchase order, causing slow response times.

# Core Features
- Optimize the purchase orders index query to eager-load approvers
- Maintain existing API response format
- Ensure no regression in approval flow behavior

# User Experience
- API consumers see faster response times on GET /api/v1/purchase_orders
- No change to response payload structure
</context>
<PRD>
# Technical Architecture
- Model: PurchaseOrder with has_many :approvals association
- Controller: Api::V1::PurchaseOrdersController#index
- Serializer: PurchaseOrderSerializer includes approver data
- Fix: Add `.includes(:approvals, :approver)` to the query scope

# Development Roadmap
Phase 1: Add eager loading to the query
Phase 2: Verify serializer output unchanged
Phase 3: Add RSpec test for query count

# Logical Dependency Chain
1. Identify the exact query causing N+1 (use Bullet gem output)
2. Add includes to the scope
3. Test that response payload is identical
4. Verify query count reduced

# Risks and Mitigations
- Risk: Eager loading too many associations bloats memory
  Mitigation: Only include the specific associations needed
- Risk: Changing query breaks existing filters
  Mitigation: Run full controller spec suite

# Appendix
- Related: Bullet gem configuration in config/environments/development.rb
</PRD>
```

## RPG Template Example

For a feature issue like "Add three-way matching for invoices":

```markdown
<rpg-method>
# RPG Method PRD
</rpg-method>

<overview>
## Problem Statement
Invoice approval currently requires manual comparison between purchase orders,
invoices, and goods receipts. This is error-prone and time-consuming.

## Target Users
- Finance team members who approve invoices
- Company admins who configure matching rules

## Success Metrics
- 90% of invoices auto-matched without manual intervention
- < 2% false positive match rate
</overview>

<functional-decomposition>
## Capability Tree

### Capability: Invoice Matching Engine
Core logic for comparing PO, invoice, and receipt data.

#### Feature: Line-item matching
- **Description**: Match invoice line items to PO line items by item code and quantity
- **Inputs**: Invoice line items, PO line items
- **Outputs**: Match results with confidence scores
- **Behavior**: Fuzzy match on description, exact match on amounts within tolerance

#### Feature: Tolerance configuration
- **Description**: Allow configurable tolerance thresholds per company
- **Inputs**: Company settings, match type
- **Outputs**: Tolerance rules
- **Behavior**: Default 2% tolerance, configurable per company

### Capability: Match Review UI
Interface for reviewing and resolving match discrepancies.

#### Feature: Match dashboard
- **Description**: Show pending matches with discrepancy highlights
- **Inputs**: Unresolved matches
- **Outputs**: Rendered dashboard view
- **Behavior**: Sort by severity, allow bulk approve
</functional-decomposition>

<structural-decomposition>
## Module Definitions

### Module: ThreeWayMatch Service
- **Maps to capability**: Invoice Matching Engine
- **Responsibility**: Execute matching logic
- **File structure**:
  ```
  app/services/three_way_match/
  ├── matcher_service.rb
  ├── line_item_comparator.rb
  └── tolerance_calculator.rb
  ```

### Module: Match API
- **Maps to capability**: Match Review UI (API layer)
- **File structure**:
  ```
  app/controllers/api/v1/three_way_matches_controller.rb
  app/serializers/three_way_match_serializer.rb
  ```
</structural-decomposition>

<dependency-graph>
## Dependency Chain

### Foundation Layer (Phase 0)
- **ThreeWayMatchConcern**: Base model concern (already partially exists)
- **Company tolerance settings**: Migration + model changes

### Core Layer (Phase 1)
- **MatcherService**: Depends on [ThreeWayMatchConcern, tolerance settings]
- **LineItemComparator**: Depends on [ThreeWayMatchConcern]

### API Layer (Phase 2)
- **ThreeWayMatchesController**: Depends on [MatcherService]
- **ThreeWayMatchSerializer**: Depends on [MatcherService]
</dependency-graph>

<implementation-roadmap>
## Development Phases

### Phase 0: Foundation
**Goal**: Data model and configuration ready
**Tasks**:
- [ ] Add tolerance columns to company_settings
- [ ] Extend ThreeWayMatchConcern with new matching methods
**Exit Criteria**: Migration runs, tolerance settings configurable

### Phase 1: Matching Engine
**Goal**: Core matching logic works
**Tasks**:
- [ ] Implement MatcherService (depends on Phase 0)
- [ ] Implement LineItemComparator (depends on Phase 0)
**Exit Criteria**: Service returns correct match results in specs

### Phase 2: API
**Goal**: Frontend can consume match data
**Tasks**:
- [ ] Build controller + serializer (depends on Phase 1)
- [ ] Add Pundit policy for match access control
**Exit Criteria**: API returns match data, authorized correctly
</implementation-roadmap>

<test-strategy>
## Critical Test Scenarios

### MatcherService
**Happy path**: PO, invoice, and receipt all match within tolerance
**Edge cases**: Zero-quantity lines, foreign currency amounts
**Error cases**: Missing PO reference, duplicate invoice numbers
</test-strategy>
```

## Tips for Better PRDs

1. **Read the codebase first** — check existing models, services, and concerns before writing structural decomposition
2. **Reference existing patterns** — if the project uses service objects, your PRD should define service objects
3. **Keep it atomic** — each feature should be independently implementable and testable
4. **Include the issue number** — always reference `#<issue_number>` in the PRD title for traceability
