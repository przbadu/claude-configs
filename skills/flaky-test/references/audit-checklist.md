# Test Suite Audit Checklist

## 1. Duplicated Tests

Find tests that verify identical behavior across files:

```bash
# Find tests with identical names across spec/ and test/
grep -rn "it ['\"].*['\"]" spec/ --include="*.rb" | awk -F"'" '{print $2}' | sort | uniq -d
grep -rn "def test_" test/ --include="*.rb" | awk -F"def " '{print $2}' | sort | uniq -d

# Find specs that test the same model/service in both frameworks
diff <(ls spec/models/ 2>/dev/null | sed 's/_spec.rb//') <(ls test/models/ 2>/dev/null | sed 's/_test.rb//')
```

**Action:** Consolidate into the RSpec version (project convention for new tests). Keep only the more comprehensive version.

## 2. Outdated Tests

Tests for features/code that no longer exists:

```bash
# Find test files for models that don't exist
for f in spec/models/*_spec.rb test/models/*_test.rb; do
  model=$(basename "$f" | sed 's/_spec.rb\|_test.rb//' | ruby -e 'puts ARGF.read.split("_").map(&:capitalize).join')
  grep -rq "class $model" app/models/ || echo "ORPHAN: $f (no $model model found)"
done

# Find test files for controllers that don't exist
for f in spec/controllers/*_spec.rb test/controllers/*_test.rb; do
  ctrl=$(basename "$f" | sed 's/_spec.rb\|_test.rb//')
  grep -rq "class.*${ctrl}" app/controllers/ || echo "ORPHAN: $f"
done

# Find tests referencing removed methods
grep -rn "\.should_receive\|expect.*to receive" spec/ --include="*.rb" | while read line; do
  method=$(echo "$line" | grep -oP "(?:should_receive|receive)\(:\K\w+")
  file=$(echo "$line" | cut -d: -f1)
  # Check if method still exists in source
done
```

**Action:** Remove orphaned test files. Update tests for renamed methods.

## 3. Slow Tests (>2 seconds each)

```bash
# Profile RSpec
bundle exec rspec --profile 50 --format progress 2>&1 | grep "seconds"

# Profile Minitest
bundle exec rails test TESTOPTS="--profile" 2>&1 | grep -E "^\s+[0-9]+\.[0-9]+ seconds"
```

Common slow test causes:
- **Heavy factory setup** — Use `build_stubbed` when DB isn't needed
- **N+1 in setup** — Use `includes` in test setup or reduce created records
- **Missing test indexes** — Add indexes for columns used in test queries
- **Unnecessary before(:each)** — Move to `before(:all)` for read-only setup
- **Large file I/O** — Stub file operations in unit tests

**Action:** Target tests over 2s. Goal: 95th percentile under 1s.

## 4. Factory Efficiency

```bash
# Count create vs build vs build_stubbed usage
echo "create: $(grep -rc 'FactoryBot\.create\|create(' spec/ test/ --include='*.rb' | awk -F: '{sum+=$2}END{print sum}')"
echo "build:  $(grep -rc 'FactoryBot\.build\b\|build(' spec/ test/ --include='*.rb' | awk -F: '{sum+=$2}END{print sum}')"
echo "stubbed: $(grep -rc 'build_stubbed' spec/ test/ --include='*.rb' | awk -F: '{sum+=$2}END{print sum}')"
```

**Target ratio:** At least 30% of factory calls should be `build` or `build_stubbed`.

## 5. Test Isolation

```bash
# Tests modifying global state
grep -rn "Rails\.cache\|Rails\.application\.config" spec/ test/ --include="*.rb" | grep "="

# Tests without proper cleanup
grep -rn "after\(:each\)\|teardown" spec/ test/ --include="*.rb" | wc -l

# Shared mutable state
grep -rn "let!\|before\(:all\)" spec/ --include="*.rb"
```

**Action:** Ensure all global state modifications are cleaned up in `after` blocks.

## 6. Missing Test Coverage

```bash
# Models without any test file
for f in app/models/*.rb; do
  base=$(basename "$f" .rb)
  [ -f "spec/models/${base}_spec.rb" ] || [ -f "test/models/${base}_test.rb" ] || echo "UNTESTED: $f"
done

# Services without tests
for f in app/services/**/*.rb; do
  base=$(basename "$f" .rb)
  find spec/ test/ -name "*${base}*" -print -quit | grep -q . || echo "UNTESTED: $f"
done
```

**Action:** Report untested files but don't create new tests (out of scope for flaky-test skill).

## 7. CI Performance Analysis

```bash
# Get recent CI run times
gh run list --limit 10 --json databaseId,conclusion,updatedAt,createdAt | \
  jq '.[] | {id: .databaseId, status: .conclusion, duration: ((.updatedAt | fromdate) - (.createdAt | fromdate)) / 60 | floor | tostring + " min"}'

# Get CI job breakdown
gh run view $(gh run list --limit 1 --json databaseId -q '.[0].databaseId') --json jobs | \
  jq '.jobs[] | {name: .name, duration: ((.completedAt | fromdate) - (.startedAt | fromdate)) / 60 | floor | tostring + " min"}'
```

**Target:** Total CI time under 10 minutes. Individual jobs under 7 minutes.

## 8. Test File Organization

Check for misplaced tests:

```bash
# RSpec files in test/ directory
find test/ -name "*_spec.rb" 2>/dev/null

# Minitest files in spec/ directory
find spec/ -name "*_test.rb" 2>/dev/null

# Test files not matching standard naming
find spec/ -name "*.rb" ! -name "*_spec.rb" ! -path "*/support/*" ! -path "*/factories/*" ! -path "*/shared_*" ! -name "spec_helper.rb" ! -name "rails_helper.rb" 2>/dev/null
find test/ -name "*.rb" ! -name "*_test.rb" ! -path "*/support/*" ! -path "*/factories/*" ! -name "test_helper.rb" 2>/dev/null
```

## Audit Report Template

After running all checks, produce a summary:

```markdown
# Test Suite Health Audit

**Date:** YYYY-MM-DD
**Total test files:** N (spec: X, test: Y)
**Total test cases:** N

## Findings

| Category | Count | Severity | Action |
|----------|-------|----------|--------|
| Flaky (timezone) | N | High | Fix with travel_to |
| Flaky (hardcoded ID) | N | High | Use sequences |
| Slow (>2s) | N | Medium | Optimize |
| Duplicated | N | Low | Consolidate |
| Outdated | N | Low | Remove |
| Missing coverage | N | Info | Backlog |

## Top 10 Slowest Tests
[List with file:line and duration]

## Recommendations
[Prioritized list of actions]

## Estimated Impact
- Current CI time: Xm
- Projected CI time after fixes: Ym
- Tests to fix: N
- Tests to remove: N
```
