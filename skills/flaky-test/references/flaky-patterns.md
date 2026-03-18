# Flaky Test Pattern Library

## Detection Patterns

Search queries to find common flaky test causes in Rails projects.

### Timezone Issues

```bash
# Direct time references (should use travel_to or freeze_time)
grep -rn "Time.now\|Time.current\|Date.today\|DateTime.now" spec/ test/ --include="*.rb"

# Date boundary comparisons
grep -rn "\.to_date\|\.beginning_of_day\|\.end_of_day\|\.beginning_of_month" spec/ test/ --include="*.rb"

# Relative time assertions
grep -rn "ago\|from_now\|since\|until" spec/ test/ --include="*.rb" | grep -i "expect\|assert"
```

### Hardcoded IDs

```bash
# Explicit ID assignment in factories
grep -rn "id: [0-9]" spec/factories/ test/factories/ --include="*.rb"

# ID comparisons in tests
grep -rn "\.id == \|\.id\.should\|expect.*\.id\)" spec/ test/ --include="*.rb" | grep "[0-9]"

# Hardcoded foreign keys
grep -rn "_id: [0-9]\|_id => [0-9]" spec/ test/ --include="*.rb"
```

### Order Dependence

```bash
# Relying on implicit ordering
grep -rn "\.first\b\|\.last\b" spec/ test/ --include="*.rb" | grep -v "factory\|FactoryBot\|#"

# Tests using .all without ordering
grep -rn "\.all\b" spec/ test/ --include="*.rb" | grep "expect\|assert"
```

### Timing & Sleep

```bash
# Explicit sleep calls
grep -rn "\bsleep\b" spec/ test/ --include="*.rb"

# Timecop without blocks (leaked state)
grep -rn "Timecop\.freeze\|Timecop\.travel" spec/ test/ --include="*.rb" | grep -v "do$\|do |"
```

### Non-deterministic Data

```bash
# Random values
grep -rn "\brand\b\|Random\|SecureRandom\|\.sample\|\.shuffle" spec/ test/ --include="*.rb"

# UUID/token comparisons
grep -rn "uuid\|token\|SecureRandom" spec/ test/ --include="*.rb" | grep "expect\|assert\|eq\|eql"
```

### External Dependencies

```bash
# HTTP calls without stubs
grep -rn "Net::HTTP\|HTTParty\|Faraday\|RestClient\|open-uri" spec/ test/ --include="*.rb"

# Missing VCR/WebMock
grep -rL "VCR\|WebMock\|stub_request" spec/ test/ --include="*.rb" | xargs grep -l "Net::HTTP\|HTTParty\|Faraday" 2>/dev/null
```

### Shared State / Leaky Tests

```bash
# Global variable mutation
grep -rn '\$\w\+\s*=' spec/ test/ --include="*.rb"

# Class variable mutation in tests
grep -rn "@@\w\+\s*=" spec/ test/ --include="*.rb"

# ENV mutation without restore
grep -rn "ENV\[" spec/ test/ --include="*.rb" | grep "="

# Missing after/teardown cleanup
grep -rn "before\|setup" spec/ test/ --include="*.rb" | head -20
```

### Slow Test Indicators

```bash
# Large record creation
grep -rn "\.times\s*do\|\.times\s*{" spec/ test/ --include="*.rb" | grep -E "[0-9]{2,}"

# create_list with large counts
grep -rn "create_list.*[0-9][0-9]" spec/ test/ --include="*.rb"

# Missing build_stubbed opportunities
grep -rn "FactoryBot\.create\b\|create(:" spec/ test/ --include="*.rb" | wc -l
grep -rn "build_stubbed\|build(:" spec/ test/ --include="*.rb" | wc -l
```

## Fix Templates

### Timezone Fix
```ruby
# Wrap time-sensitive tests
travel_to Time.zone.parse("2024-06-15 12:00:00 UTC") do
  # test code here
end

# Or for Minitest with Timecop
Timecop.freeze(Time.zone.parse("2024-06-15 12:00:00 UTC")) do
  # test code here
end
```

### Hardcoded ID Fix
```ruby
# Replace hardcoded IDs with sequences
factory :widget do
  sequence(:id)  # Only if ID is truly needed
end

# Better: don't specify ID at all, let DB assign
factory :widget do
  name { "Widget" }
  # No id specification
end

# In tests, reference objects instead of IDs
expect(result.widget_id).to eq(widget.id)  # Not eq(42)
```

### Order Fix
```ruby
# Add explicit ordering
expect(Widget.order(:id).first).to eq(expected_widget)

# Or query by unique attribute
expect(Widget.find_by(name: "Target")).to eq(expected_widget)

# Or use contain_exactly for unordered comparisons
expect(Widget.all).to contain_exactly(w1, w2, w3)
```

### External Dependency Fix
```ruby
# RSpec with WebMock
before do
  stub_request(:get, "https://api.example.com/data")
    .to_return(status: 200, body: '{"result": "ok"}')
end

# Or with VCR
it "fetches data", vcr: { cassette_name: "api/fetch_data" } do
  result = ApiClient.fetch_data
  expect(result).to be_present
end
```

### Slow Factory Fix
```ruby
# Replace create with build_stubbed when DB isn't needed
let(:user) { build_stubbed(:user) }

# Use traits to minimize associations
factory :purchase_order do
  trait :minimal do
    association :company, factory: :company, strategy: :build_stubbed
  end
end

# Reduce bulk creation
# BAD: create_list(:item, 100)
# GOOD: create_list(:item, 3)  # Unless testing pagination/bulk behavior
```
