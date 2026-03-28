---
name: stripe-subscription-tester
description: >
  Interactive Stripe subscription lifecycle tester for the ProcurementExpress (po-app) Rails app.
  Simulates real Stripe webhook flows in dev environment to test subscription lock/unlock behavior.
  Use when: "test stripe", "test subscription", "test payment flow", "test incomplete subscription",
  "test payment failed", "test subscription lock", "stripe test scenario", "test billing",
  "/stripe-subscription-tester", "simulate stripe webhook", "test parent company lock",
  "test child company cascade", or any request to test Stripe subscription payment flows
  in the local development environment.
---

# Stripe Subscription Tester

Interactive, step-by-step Stripe subscription lifecycle testing for po-app dev environment.
Pause at each stage so the user can visually verify behavior in the app and terminals.

## Prerequisites Check

Before starting, verify all services are running:

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000  # Rails
pgrep -f sidekiq                                                # Sidekiq
pgrep -f "stripe listen"                                        # Stripe CLI
```

Ask the user to start any missing service. Also ask if ultrahook is running for `/stripe/webhook` (handles `invoice.payment_succeeded` unlock).

## Gather Test Parameters

### 1. Company ID

Ask: "Which company ID? If you don't have one, register at http://localhost:3000 and give me the ID."

Look up the company and report its state (status, paid_up, Stripe customer, subscriptions, child companies).

If no Stripe customer ID exists, ask the user to complete checkout or set one up.

### 2. Price / Plan

Ask: "Which plan? Provide a Stripe price ID or lookup key (e.g., `basic_monthly`)."

If lookup key given, resolve via: `stripe prices list --lookup-keys=KEY --limit=1`

### 3. Scenario

Present:

```
Which scenario?

1. incomplete -> incomplete_expired -> lock (3D Secure timeout)
2. payment_failed -> lock (card declined)
3. successful payment -> unlock (after any lock)
4. past_due -> warning only (no lock)
5. parent company lock -> child cascade
6. unpaid -> lock (all retries exhausted)
```

## Execution

Read [references/scenarios.md](references/scenarios.md) for detailed step-by-step commands for each scenario.

### Key Rules

1. **Pause after every Stripe API call** — tell the user what webhook fires and what to check in terminals, then verify DB state
2. **Always verify DB state** between steps using the check company helper
3. **Reset company** to clean state before starting a new scenario
4. **Store variables** — track customer_id, payment_method_id, subscription_id, price_id throughout
5. **Read Stripe secret key** from `config/application.yml` (`STRIPE_SECRET_KEY` or `STRIPE_PRIVATE_KEY`)

### Stripe API Pattern

```bash
curl -s -X POST https://api.stripe.com/v1/ENDPOINT \
  -u $STRIPE_SECRET_KEY: \
  -d "param=value"
```

### Webhook Endpoints

| Endpoint | Handler | Events |
|----------|---------|--------|
| `/pay/webhooks/stripe` | `SubscriptionCancellationHandler` | `customer.subscription.updated`, `customer.subscription.deleted` |
| `/stripe/webhook` | `StripeController` -> `SubscriptionWebhook` | `invoice.payment_succeeded`, `invoice.payment_failed`, `charge.succeeded` |

### Known Behaviors

- Legacy `SubscriptionWebhook` sets `paid_up = true` on success but does NOT reset `status` back to `active`
- Canceling an `incomplete` subscription transitions it to `incomplete_expired` in Stripe
- `past_due` and `unpaid` are hard to trigger in Stripe test mode — use DB simulation + handler invocation
