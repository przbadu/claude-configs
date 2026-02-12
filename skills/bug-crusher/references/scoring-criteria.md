# Bug Scoring Criteria

## Complexity Score (1-10)

Lower = simpler to fix.

| Factor | Weight | How to Assess |
|--------|--------|---------------|
| Lines of code affected | 25% | Search codebase for referenced classes/methods. <3 lines = 1, <20 = 3, <50 = 5, <100 = 7, 100+ = 9 |
| Number of files involved | 25% | Count files that need changes. 1 file = 1, 2-3 = 3, 4-5 = 5, 6-8 = 7, 9+ = 9 |
| Dependencies/coupling | 20% | Check how many other components depend on the affected code. Isolated = 1, some coupling = 5, core system = 9 |
| Database/migration needed | 15% | No DB change = 1, data update = 4, schema migration = 7, data migration + schema = 9 |
| External service involvement | 15% | No external services = 1, uses API = 5, multiple services/webhooks = 8 |

**Final score**: Weighted average rounded to nearest integer.

## AI-Fixability Score (1-10)

Higher = more likely AI can fix autonomously.

| Factor | Weight | How to Assess |
|--------|--------|---------------|
| Clear reproduction steps | 20% | Explicit steps in issue = 10, partial = 5, vague "it's broken" = 1 |
| Isolated scope | 20% | Single file/method = 10, few files = 6, cross-cutting = 2 |
| Existing test coverage | 15% | Tests exist that fail = 10, tests exist but pass = 6, no tests = 3 |
| Error message/backtrace | 15% | Full backtrace = 10, error message = 6, no error info = 2 |
| Pattern recognition | 15% | Common bug pattern (nil check, off-by-one, missing validation) = 10, moderate = 5, novel = 2 |
| Code clarity | 15% | Clean, well-structured code = 10, moderate = 5, legacy spaghetti = 2 |

**Final score**: Weighted average rounded to nearest integer.

## Combined Priority Score

```
priority = (11 - complexity) + ai_fixability
```

Range: 2-20. Higher = better candidate for AI fix.

### Priority Tiers

| Score | Tier | Recommendation |
|-------|------|----------------|
| 16-20 | Quick Win | Fix immediately with AI agent |
| 12-15 | Good Candidate | AI can likely handle with some guidance |
| 8-11 | Moderate | AI can assist but may need human review |
| 2-7 | Complex | Human-led fix recommended, AI assists |

## Common Quick-Win Patterns

These bug patterns are almost always fixable by AI:

1. **Nil/null reference** - Missing nil checks, undefined method on nil
2. **Missing validation** - Input not validated, edge case not handled
3. **Off-by-one errors** - Array index, pagination, date ranges
4. **String formatting** - Encoding issues, incorrect format strings
5. **Permission/authorization gaps** - Missing policy checks
6. **N+1 queries** - Missing includes/eager_load
7. **Missing error handling** - Unrescued exceptions
8. **Incorrect conditionals** - Wrong boolean logic, missing cases
9. **Stale cache/state** - Cache not invalidated after update
10. **UI display bugs** - Wrong text, missing translations, formatting
