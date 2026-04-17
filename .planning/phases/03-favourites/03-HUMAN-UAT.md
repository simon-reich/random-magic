---
status: partial
phase: 03-favourites
source: [03-VERIFICATION.md]
started: 2026-04-17T00:00:00Z
updated: 2026-04-17T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Swipe-up save gesture
expected: Swipe a card upward in the discovery screen — bookmark icon fills immediately (Icons.favorite, red), 'Saved to Favourites' Snackbar appears for ~2 seconds.
result: [pending]

### 2. Bookmark button tap
expected: Tap the bookmark icon (bottom-right of card) on an unsaved card — icon fills, 'Saved to Favourites' Snackbar appears. Tapping a filled icon has no effect.
result: [pending]

### 3. App-restart persistence
expected: Save one or more cards, force-close and reopen the app — all saved cards reappear in the Favourites grid.
result: [pending]

### 4. Grid tap navigation and initial card seek
expected: Tap the second card in the Favourites grid — FavouriteSwipeScreen opens starting at that card (not the first).
result: [pending]

### 5. Delete + Undo flow
expected: Tap delete (trash icon) in FavouriteSwipeScreen AppBar — card disappears, Snackbar shows "{name} removed" with Undo; tapping Undo within 3 seconds restores the card.
result: [pending]

### 6. Filter bottom sheet interaction
expected: Open filter sheet, select a colour chip — grid narrows to matching cards. If none match, 'No cards match your filters.' + 'Clear Filters' button shown. Clearing restores full grid.
result: [pending]

## Summary

total: 6
passed: 0
issues: 0
pending: 6
skipped: 0
blocked: 0

## Gaps
