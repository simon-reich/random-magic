---
phase: 04-card-detail-view
plan: "01"
subsystem: card-detail
tags: [model, router, theme, repository, test-fixtures]
dependency_graph:
  requires: []
  provides:
    - CardFace value class in shared/models/magic_card.dart
    - cardFaces field on MagicCard (List<CardFace>?)
    - AppColors.legal constant in app_theme.dart
    - Updated /card/:id router builder (state.extra as MagicCard)
    - CardDetailScreen accepting MagicCard? with null error state
    - getCardById on CardRepository interface + ScryfallApiClient + CardRepositoryImpl
    - test/fixtures/fake_magic_card.dart (fakeMagicCard, fakeDfcMagicCard)
    - test/widgets/card_detail/card_detail_screen_test.dart (8 stubs + null-card test)
  affects:
    - lib/shared/models/magic_card.dart
    - lib/core/theme/app_theme.dart
    - lib/core/router/app_router.dart
    - lib/features/card_detail/presentation/card_detail_screen.dart
    - lib/features/card_discovery/domain/card_repository.dart
    - lib/features/card_discovery/data/scryfall_api_client.dart
    - lib/features/card_discovery/data/card_repository_impl.dart
tech_stack:
  added: []
  patterns:
    - GoRouter state.extra guarded cast (state.extra is MagicCard before cast)
    - CardFace value class for DFC face data
key_files:
  created:
    - test/fixtures/fake_magic_card.dart
    - test/widgets/card_detail/card_detail_screen_test.dart
  modified:
    - lib/shared/models/magic_card.dart
    - lib/core/theme/app_theme.dart
    - lib/core/router/app_router.dart
    - lib/features/card_detail/presentation/card_detail_screen.dart
    - lib/features/card_discovery/domain/card_repository.dart
    - lib/features/card_discovery/data/scryfall_api_client.dart
    - lib/features/card_discovery/data/card_repository_impl.dart
decisions:
  - "GoRouter extra guarded cast: state.extra is MagicCard check before cast prevents crash on OS-kill route restore"
  - "CardFace.fromJson handles absent image_uris with empty map fallback — matches existing _firstFaceImageUris pattern"
  - "skip parameter in testWidgets uses bool (true), not String — Dart test API accepts only bool?"
metrics:
  duration: "~15 minutes"
  completed: "2026-04-17"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 7
---

# Phase 04 Plan 01: Foundation — MagicCard model + router + repository contracts Summary

CardFace value class, cardFaces field on MagicCard, AppColors.legal, GoRouter extra-passing router update, getCardById on repository/API layer, and Wave 0 test fixtures — all contracts Plans 02 and 03 depend on.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Extend MagicCard model + update router + add AppColors.legal | ec4e068 | magic_card.dart, app_theme.dart, app_router.dart, card_detail_screen.dart |
| 2 | Add getCardById to repository + test fixtures + stub widget tests | c3b6c9d | card_repository.dart, scryfall_api_client.dart, card_repository_impl.dart, fake_magic_card.dart, card_detail_screen_test.dart |

## What Was Built

- **CardFace value class** in `lib/shared/models/magic_card.dart` with `imageUris`, `name`, `typeLine`, `oracleText?`, `manaCost?` fields and `CardFace.fromJson()` factory
- **cardFaces field** (`List<CardFace>?`) added to `MagicCard` constructor and `fromJson()` — parses `card_faces` JSON array when >= 2 entries present; null for single-faced cards
- **AppColors.legal** (`Color(0xFF4CAF50)`) added to `AppColors` in `app_theme.dart` for legality badge use in CardDetailScreen
- **Router update**: `/card/:id` builder now reads `state.extra` as `MagicCard` (with `is MagicCard` guard), passes `card:` to `CardDetailScreen`
- **CardDetailScreen** updated from simple `cardId:` placeholder to `ConsumerStatefulWidget` accepting `MagicCard?`; shows error widget with back button when card is null
- **getCardById(String id)** added to `CardRepository` interface, implemented in `ScryfallApiClient` (calls `GET /cards/$id` with existing `_mapDioException` error mapping), and delegated in `CardRepositoryImpl`
- **test/fixtures/fake_magic_card.dart** with `fakeMagicCard()` (all-optional params) and `fakeDfcMagicCard()` (2-face DFC)
- **test/widgets/card_detail/card_detail_screen_test.dart** with 8 skip-stubs (CARD-02 through CARD-05) and one active null-card error test

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed skip parameter type in testWidgets stubs**
- **Found during:** Task 2 test run
- **Issue:** Plan specified `skip: 'Stub — full implementation in plan 04-02'` but `testWidgets` `skip` parameter in this Dart/Flutter version only accepts `bool?`, not `String`
- **Fix:** Changed all 8 stub `skip:` values from the string literal to `true`
- **Files modified:** `test/widgets/card_detail/card_detail_screen_test.dart`
- **Commit:** c3b6c9d

## Known Stubs

| Stub | File | Reason |
|------|------|--------|
| 8 `skip: true` testWidgets cases (CARD-02 through CARD-05) | test/widgets/card_detail/card_detail_screen_test.dart | Full CardDetailScreen UI not yet built — delivered by plan 04-02 |
| `body: const Center(child: CircularProgressIndicator())` | lib/features/card_detail/presentation/card_detail_screen.dart | Placeholder body — full implementation in plan 04-02 |

These stubs are intentional and tracked per the plan. Plans 04-02 and 04-03 will fill them.

## Threat Surface Scan

No new threat surface beyond what the plan's threat model covers. T-04-01 (guarded cast) and T-04-02 (DioException mapping) are both mitigated as planned.

## Self-Check: PASSED

- `lib/shared/models/magic_card.dart` — exists, contains `class CardFace`, `final List<CardFace>? cardFaces`, `factory CardFace.fromJson`, `cardFaces: cardFaces`
- `lib/core/theme/app_theme.dart` — exists, contains `static const Color legal = Color(0xFF4CAF50)`
- `lib/core/router/app_router.dart` — exists, contains `state.extra is MagicCard`, `CardDetailScreen(card: card)`
- `lib/features/card_detail/presentation/card_detail_screen.dart` — exists, contains `final MagicCard? card`, `Card not available`
- `lib/features/card_discovery/domain/card_repository.dart` — exists, contains `Future<Result<MagicCard>> getCardById(String id)`
- `lib/features/card_discovery/data/scryfall_api_client.dart` — exists, contains `getCardById`, `/cards/$id`
- `lib/features/card_discovery/data/card_repository_impl.dart` — exists, contains `_client.getCardById(id)`
- `test/fixtures/fake_magic_card.dart` — exists, contains `fakeMagicCard`, `fakeDfcMagicCard`
- `test/widgets/card_detail/card_detail_screen_test.dart` — exists, 9 test cases, null-card test passes
- Commits ec4e068 and c3b6c9d — verified in git log
- `flutter analyze --fatal-infos` — clean on all modified files
- `flutter test --no-pub` — 72 passed, 19 skipped, 0 failed
