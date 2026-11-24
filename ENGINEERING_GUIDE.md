# FinTrack — Local-first finance engineering guide

The [README](README.md) documents a Flutter expense journal using Provider, shared preferences and integer minor currency units. This guide explains that design and proposes further acceptance tests. FinTrack is not a bank, investment service or payment processor.

## Expense lifecycle

~~~mermaid
flowchart TD
 A[Enter amount category and date] --> B[Validate fields]
 B --> C{Valid?}
 C -->|No| D[Show correction]
 C -->|Yes| E[Create or edit expense record]
 E --> F[Update Provider state]
 F --> G[Serialize to local storage]
 G --> H[Refresh dashboard and category totals]
 G --> I[Storage failure state]
~~~

A record's identity should remain stable when edited so totals do not count an old and new entry simultaneously. A successful storage operation and an updated interface are different events. A proposed failure-handling policy should make unsaved edits obvious rather than implying permanent persistence.

## Integer arithmetic

Store Indian rupee amounts in paise. For a hypothetical journal with ₹125.50 and ₹49.25 entries, integer storage uses 12550 and 4925 paise; the total is 17475 paise or ₹174.75. This avoids typical binary floating-point rounding differences. Decimal parsing should validate precision before conversion and preserve the user's currency assumptions. If multiple currencies are later supported, totals must not mix currencies without an explicit conversion policy.

## Analytics mechanism

~~~mermaid
flowchart LR
 L[Saved records] --> F[Date and category filter]
 F --> G[Group by category]
 G --> S[Sum integer amounts]
 S --> V[Format currency and draw chart]
~~~

A category share is the category subtotal divided by the total for the same filter. An empty or zero-total result requires a meaningful empty state, not division by zero. Charts should have textual alternatives and must agree with transaction lists. Test month boundaries, local timezone, category changes and large valid amounts.

## Data durability

Local-first design avoids requiring an online account, but it is not the same as encrypted storage or automatic backup. Shared preferences can be cleared by platform operations. A future export/import mechanism should document schema version, validate all records before import, detect duplicates, allow preview and prevent accidental overwrite. Use synthetic data for screenshots and test fixtures.

## Verification matrix

| Test | Expected invariant |
| --- | --- |
| Add a valid amount | One new record and exact total |
| Edit category | Old category decreases, new increases |
| Restart app | Saved records load consistently |
| Malformed saved JSON | Recoverable error state |
| Empty list | No invalid chart ratios |
| Theme change | Data unchanged |
| Narrow screen | Amounts and controls remain legible |

Run `flutter analyze` and `flutter test` using the documented SDK. Test real device persistence separately from widget rendering. A web build is not evidence of a published website. Keep screenshots and release notes tied to the tested version.
