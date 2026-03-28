# Stripe Test Scenarios

## Table of Contents
- [Stripe Test Cards](#stripe-test-cards)
- [Scenario: incomplete -> incomplete_expired -> lock](#scenario-incomplete---incomplete_expired---lock)
- [Scenario: payment_failed -> lock](#scenario-payment_failed---lock)
- [Scenario: successful payment -> unlock](#scenario-successful-payment---unlock)
- [Scenario: past_due -> warning only](#scenario-past_due---warning-only)
- [Scenario: parent company lock -> child cascade](#scenario-parent-company-lock---child-cascade)
- [Scenario: unpaid -> lock](#scenario-unpaid---lock)
- [Helper: Reset company to clean state](#helper-reset-company-to-clean-state)
- [Helper: Check company state](#helper-check-company-state)

## Stripe Test Cards

| Token | Behavior |
|-------|----------|
| `pm_card_authenticationRequired` | Requires 3D Secure -> subscription goes `incomplete` |
| `pm_card_visa` | Always succeeds -> subscription goes `active` |
| `pm_card_chargeDeclined` | Payment declined -> triggers `invoice.payment_failed` |
| `pm_card_chargeDeclinedInsufficientFunds` | Insufficient funds decline |

## Scenario: incomplete -> incomplete_expired -> lock

Tests that subscriptions requiring 3D Secure authentication that are never completed will eventually lock the company.

### Step 1: Create incomplete subscription

```bash
# Attach 3D Secure card
stripe payment_methods attach pm_card_authenticationRequired --customer=$CUSTOMER_ID

# Set as default
curl -s -X POST https://api.stripe.com/v1/customers/$CUSTOMER_ID \
  -u $STRIPE_SECRET_KEY: \
  -d "invoice_settings[default_payment_method]=$PAYMENT_METHOD_ID"

# Create subscription with default_incomplete behavior
curl -s -X POST https://api.stripe.com/v1/subscriptions \
  -u $STRIPE_SECRET_KEY: \
  -d "customer=$CUSTOMER_ID" \
  -d "items[0][price]=$PRICE_ID" \
  -d "payment_behavior=default_incomplete" \
  -d "payment_settings[save_default_payment_method]=on_subscription"
```

**Expected**: Subscription status = `incomplete`. Company stays `active`, `paid_up: true`. Slack warning sent.

**Pause**: Ask user to verify in app and terminals.

### Step 2: Expire the incomplete subscription

```bash
# Canceling an incomplete subscription transitions it to incomplete_expired
curl -s -X DELETE https://api.stripe.com/v1/subscriptions/$SUBSCRIPTION_ID \
  -u $STRIPE_SECRET_KEY:
```

**Expected**: Subscription status = `incomplete_expired`. Company locked: `inactive_due_to_payment`, `paid_up: false`.

**Pause**: Ask user to verify company is locked in admin panel.

### Step 3: Successful payment to unlock

```bash
# Attach working card
stripe payment_methods attach pm_card_visa --customer=$CUSTOMER_ID

# Set as default
curl -s -X POST https://api.stripe.com/v1/customers/$CUSTOMER_ID \
  -u $STRIPE_SECRET_KEY: \
  -d "invoice_settings[default_payment_method]=$NEW_PM_ID"

# Create new subscription with working card
curl -s -X POST https://api.stripe.com/v1/subscriptions \
  -u $STRIPE_SECRET_KEY: \
  -d "customer=$CUSTOMER_ID" \
  -d "items[0][price]=$PRICE_ID" \
  -d "default_payment_method=$NEW_PM_ID"
```

**Expected**: Subscription status = `active`. `invoice.payment_succeeded` webhook fires. Company unlocked: `paid_up: true`.

**Note**: The legacy `SubscriptionWebhook` sets `paid_up = true` but does NOT reset `status` back to `active`. This is a known pre-existing behavior.

## Scenario: payment_failed -> lock

Tests that payment failures lock the company.

### Step 1: Create subscription with declined card

```bash
# Attach declined card
stripe payment_methods attach pm_card_chargeDeclined --customer=$CUSTOMER_ID

# Set as default
curl -s -X POST https://api.stripe.com/v1/customers/$CUSTOMER_ID \
  -u $STRIPE_SECRET_KEY: \
  -d "invoice_settings[default_payment_method]=$PAYMENT_METHOD_ID"

# Create subscription - payment will fail
curl -s -X POST https://api.stripe.com/v1/subscriptions \
  -u $STRIPE_SECRET_KEY: \
  -d "customer=$CUSTOMER_ID" \
  -d "items[0][price]=$PRICE_ID"
```

**Expected**: `invoice.payment_failed` webhook fires. Company locked via `SubscriptionWebhook#handle_pay_stripe_subscription!`.

**Pause**: Ask user to verify.

## Scenario: successful payment -> unlock

Tests that a successful payment after locking restores access.

Use the "Step 3: Successful payment to unlock" from the incomplete scenario above. This applies after any lock scenario.

## Scenario: past_due -> warning only

Tests that `past_due` status sends a warning but does NOT lock the company.

### Step 1: Create active subscription, then simulate past_due

```bash
# Create active subscription first
curl -s -X POST https://api.stripe.com/v1/subscriptions \
  -u $STRIPE_SECRET_KEY: \
  -d "customer=$CUSTOMER_ID" \
  -d "items[0][price]=$PRICE_ID" \
  -d "default_payment_method=$WORKING_PM_ID"

# Update the subscription's default payment method to a declining card
# Then wait for renewal, or manually update pay_subscription status in DB
# to simulate what happens when the handler receives past_due
```

**Alternative (DB simulation)**: Since Stripe doesn't easily let you force `past_due` in test mode:

```ruby
# In rails runner:
sub = Pay::Subscription.find_by(processor_id: "sub_xxx")
sub.update_columns(status: "past_due")

# Then simulate the webhook via handler directly:
handler = Pay::Webhooks::SubscriptionCancellationHandler.new
event = OpenStruct.new(
  type: "customer.subscription.updated",
  data: OpenStruct.new(object: OpenStruct.new(
    id: sub.processor_id,
    status: "past_due",
    customer: company.payment_processor.processor_id,
    current_period_end: 1.month.from_now.to_i
  ))
)
handler.call(event)
```

**Expected**: Company stays `active`, `paid_up: true`. Slack warning sent with "PAST_DUE...requires attention".

## Scenario: parent company lock -> child cascade

Tests that locking a parent company cascades to child companies (unless they have their own active subscription).

### Setup

```ruby
# In rails runner - find or create parent/child relationship:
parent = Company.find(PARENT_ID)
child = parent.child_companies.first  # or create one

# Verify both are active:
puts "Parent: #{parent.status}, paid_up: #{parent.paid_up}"
puts "Child: #{child.status}, paid_up: #{child.paid_up}"
puts "Child has own subscription: #{child.payment_processor&.subscriptions&.active&.exists?}"
```

### Step 1: Lock the parent via incomplete_expired

Follow the "incomplete -> incomplete_expired -> lock" scenario using the parent company's Stripe customer ID.

**Expected**:
- Parent: `inactive_due_to_payment`, `paid_up: false`
- Child WITHOUT own subscription: also locked
- Child WITH own active subscription: stays active (not locked)

**Pause**: Ask user to verify both parent and child company states.

## Scenario: unpaid -> lock

Tests that `unpaid` status (all Stripe retry attempts exhausted) locks the company.

Since Stripe doesn't easily produce `unpaid` in test mode, simulate via DB + handler:

```ruby
# In rails runner:
sub = company.payment_processor.subscriptions.last
sub.update_columns(status: "unpaid")

handler = Pay::Webhooks::SubscriptionCancellationHandler.new
event = OpenStruct.new(
  type: "customer.subscription.updated",
  data: OpenStruct.new(object: OpenStruct.new(
    id: sub.processor_id,
    status: "unpaid",
    customer: company.payment_processor.processor_id,
    current_period_end: nil
  ))
)
handler.call(event)
```

**Expected**: Company locked: `inactive_due_to_payment`, `paid_up: false`.

## Helper: Reset company to clean state

```ruby
bundle exec rails runner '
c = Company.find(COMPANY_ID)
c.update_columns(status: Company.statuses[:active], paid_up: true)
puts "Reset - Status: #{c.reload.status}, Paid up: #{c.paid_up}"
'
```

## Helper: Check company state

```ruby
bundle exec rails runner '
c = Company.find(COMPANY_ID)
puts "Company: #{c.name} (ID: #{c.id})"
puts "Status: #{c.status}"
puts "Paid up: #{c.paid_up}"
if c.payment_processor.present?
  pp = c.payment_processor
  puts "Stripe Customer: #{pp.processor_id}"
  pp.subscriptions.each do |s|
    puts "  Sub: #{s.processor_id} | status: #{s.status} | period_end: #{s.current_period_end}"
  end
end
'
```
