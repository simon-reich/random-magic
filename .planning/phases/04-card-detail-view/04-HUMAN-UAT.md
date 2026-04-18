---
status: partial
phase: 04-card-detail-view
source: [04-VERIFICATION.md]
started: 2026-04-18T00:00:00Z
updated: 2026-04-18T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Tap-to-detail from CardSwipeScreen
expected: Tapping a card in the swipe screen navigates to CardDetailScreen with full artwork visible, SliverAppBar collapses on scroll, and all metadata sections render correctly.
result: [pending]

### 2. Tap-to-detail from FavouriteSwipeScreen
expected: Tapping a favourite card navigates to CardDetailScreen after an async getCardById fetch. If the fetch fails, a SnackBar error message appears and navigation does not occur.
result: [pending]

### 3. Double-faced card flip
expected: For a DFC card (e.g. Delver of Secrets), a flip FAB is visible. Tapping it swaps front/back artwork and oracle text. Flipping back works correctly.
result: [pending]

### 4. Null flavour text layout
expected: For a card with no flavour text, no empty space or blank section appears where flavour text would be — the section is hidden entirely.
result: [pending]

### 5. Null prices live sanity check
expected: For a basic land or other card with no market data, all price fields display "N/A" rather than blank or crashing.
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
