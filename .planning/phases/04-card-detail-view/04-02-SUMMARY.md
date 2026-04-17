---
phase: 04-card-detail-view
plan: "02"
subsystem: card-detail
tags: [ui, sliver, flip, prices, legalities, widget-tests]
dependency_graph:
  requires:
    - CardFace value class (04-01)
    - MagicCard.cardFaces field (04-01)
    - AppColors.legal (04-01)
    - fakeMagicCard / fakeDfcMagicCard fixtures (04-01)
    - CardDetailScreen stub accepting MagicCard? (04-01)
  provides:
    - Full CardDetailScreen implementation (CARD-02 through CARD-05)
    - SliverAppBar with 440px artwork area and FlexibleSpaceBar
    - Double-faced card flip logic with _showBack state
    - _CardArtwork, _OracleTextSection, _FlavorTextSection
    - _SetInfoSection, _InfoRow, _PricesSection, _PriceRow
    - _LegalitiesSection, _LegalityRow with colored badges
    - 15 passing widget tests for CARD-02 through CARD-05
  affects:
    - lib/features/card_detail/presentation/card_detail_screen.dart
    - test/widgets/card_detail/card_detail_screen_test.dart
    - test/fixtures/fake_magic_card.dart
tech_stack:
  added:
    - cached_network_image (already in pubspec; now used in card detail)
  patterns:
    - SliverAppBar + CustomScrollView for collapsible artwork header
    - ConsumerStatefulWidget with bool _showBack for flip state
    - Sentinel pattern in test fixture (Object? prices = _kDefaultPrices) for explicit null override
    - Tall viewport in widget tests (800x2400) so SliverList content renders without scrolling
key_files:
  created: []
  modified:
    - lib/features/card_detail/presentation/card_detail_screen.dart
    - test/widgets/card_detail/card_detail_screen_test.dart
    - test/fixtures/fake_magic_card.dart
decisions:
  - "Tall test viewport (800x2400): SliverList content below 440px SliverAppBar would not render in default 800x600 test viewport; setting physicalSize ensures all sections are laid out without scrolling"
  - "Sentinel pattern for prices fixture: Dart nullable named params with ?? fallback cannot distinguish null from absent; Object? sentinel + identical() check solves this cleanly without breaking existing callers"
  - "7 legality formats shown: Standard/Modern/Legacy/Commander required by CARD-04; Pioneer/Vintage/Pauper added at discretion per CONTEXT.md"
metrics:
  duration: "~15 minutes"
  completed: "2026-04-17"
  tasks_completed: 2
  tasks_total: 2
  files_created: 0
  files_modified: 3
---

# Phase 04 Plan 02: Full CardDetailScreen implementation Summary

Full CardDetailScreen with SliverAppBar (440px artwork), flip FAB for DFCs, colored legality badges, N/A price fallbacks, and 15 passing widget tests covering CARD-02 through CARD-05.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Implement full CardDetailScreen with SliverAppBar + flip logic | 216d76e | card_detail_screen.dart |
| 2 | Fill in widget tests for CARD-02 through CARD-05 | 45597a3 | card_detail_screen_test.dart, fake_magic_card.dart |

## What Was Built

- **CardDetailScreen** fully replaced from stub: `ConsumerStatefulWidget` with `bool _showBack` flip state, `SliverAppBar(expandedHeight: 440.0, pinned: true)`, `FlexibleSpaceBar` with card name title and `_CardArtwork` background
- **_CardArtwork**: `CachedNetworkImage` with `ColoredBox` placeholder and `Icons.broken_image_outlined` error widget; empty-URL guard (`imageUrl.isEmpty ? ColoredBox : CachedNetworkImage`) per threat T-04-06
- **_OracleTextSection**: plain body text for rules text of the active face
- **_FlavorTextSection**: italic body text, rendered only when `card.flavorText != null` (no gap when absent)
- **_SetInfoSection / _InfoRow**: set name, collector number, released date as label/value rows
- **_PricesSection / _PriceRow**: USD, USD Foil, EUR with `prices?.usd ?? 'N/A'` fallback (CARD-03)
- **_LegalitiesSection / _LegalityRow**: colored badge container per format; `switch` on Scryfall legality string → AppColors.legal / .error / .primaryVariant / .onSurfaceMuted (CARD-04)
- **Flip FAB**: `FloatingActionButton` shown only when `card.cardFaces != null`; tapping toggles `_showBack`, swapping name/typeLine/oracleText/imageUrl to back face; mana cost locked to front face (CARD-05)
- **15 widget tests**: all 8 stubs replaced + 1 null-card test retained; 0 skipped, 0 failures

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] SliverList content off-screen in default test viewport**
- **Found during:** Task 2 test run
- **Issue:** Default Flutter test viewport (800×600) places the SliverList content below the 440px SliverAppBar, so set info / prices / legalities sections were not rendered and `find.text(...)` returned 0 matches
- **Fix:** Set `tester.view.physicalSize = const Size(800, 2400)` with teardown in `pumpDetail()` helper so all sections are laid out in one frame without scrolling
- **Files modified:** `test/widgets/card_detail/card_detail_screen_test.dart`
- **Commit:** 45597a3

**2. [Rule 1 - Bug] fakeMagicCard fixture cannot accept explicit null prices**
- **Found during:** Task 2 — `fakeMagicCard(prices: null)` test showed 0 N/A widgets
- **Issue:** `prices: prices ?? const CardPrices(...)` in the fixture body means passing `prices: null` explicitly still triggers the `??` fallback — null cannot be distinguished from "not provided"
- **Fix:** Sentinel pattern: `const Object _kDefaultPrices = CardPrices(...)` as top-level constant; parameter declared `Object? prices = _kDefaultPrices`; assignment uses `identical(prices, _kDefaultPrices)` to decide whether to use default or cast to `CardPrices?`
- **Files modified:** `test/fixtures/fake_magic_card.dart`
- **Commit:** 45597a3

## Known Stubs

None — all sections are fully implemented and wired. Plan 04-02 resolves the stubs tracked in 04-01 SUMMARY.

## Threat Surface Scan

No new threat surface. T-04-06 (empty-URL guard for CachedNetworkImage) is mitigated in `_CardArtwork.build()` via the `imageUrl.isEmpty ? ColoredBox(...)` guard — empty string never reaches the network library.

## Self-Check: PASSED

- `lib/features/card_detail/presentation/card_detail_screen.dart` — contains `class _CardArtwork`, `class _LegalityRow`, `class _PriceRow`, `_kDetailArtworkHeight = 440.0`, `bool _showBack = false`, `AppColors.legal`, `prices?.usd ?? 'N/A'`, `legalities['standard']`, `legalities['commander']`, `if (card.flavorText != null)`
- `test/widgets/card_detail/card_detail_screen_test.dart` — 15 tests, 0 skipped
- `test/fixtures/fake_magic_card.dart` — sentinel pattern present, `fakeMagicCard(prices: null)` returns null prices
- Commits 216d76e and 45597a3 — verified in git log
- `flutter analyze --fatal-infos` — clean on all modified files
- `flutter test --no-pub` — 86 passed, 11 skipped (pre-existing), 0 failed
