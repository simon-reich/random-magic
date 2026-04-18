---
phase: 04-card-detail-view
reviewed: 2026-04-17T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - lib/core/router/app_router.dart
  - lib/core/theme/app_theme.dart
  - lib/features/card_detail/presentation/card_detail_screen.dart
  - lib/features/card_discovery/data/card_repository_impl.dart
  - lib/features/card_discovery/data/scryfall_api_client.dart
  - lib/features/card_discovery/domain/card_repository.dart
  - lib/features/card_discovery/presentation/card_swipe_screen.dart
  - lib/features/favourites/presentation/favourite_swipe_screen.dart
  - lib/shared/models/magic_card.dart
  - test/fixtures/fake_magic_card.dart
  - test/widgets/card_detail/card_detail_screen_test.dart
  - test/widgets/card_discovery/card_swipe_screen_tap_test.dart
findings:
  critical: 1
  warning: 4
  info: 3
  total: 8
status: issues_found
---

# Phase 04: Code Review Report

**Reviewed:** 2026-04-17
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

The card detail feature is well-structured overall. The DFC flip logic, null-card error state,
legality badge colouring, and image fallback chain are all correctly implemented. The `Result`
pattern is used consistently and error states are wired up throughout the API client. Architecture
layer boundaries are respected — no presentation layer makes direct HTTP calls.

Three categories of issues were found:

1. **Unhandled JSON cast** in `MagicCard.fromJson` and `CardFace.fromJson` that will crash at
   runtime if Scryfall omits or nulls `type_line` (confirmed real for some token cards).
2. **Unguarded null-assertion** on `response.data!` in `ScryfallApiClient` that escapes the
   `DioException` catch block.
3. A set of lower-severity issues: an index access without a length guard, a missing loading
   state during async card fetch from `FavouriteSwipeScreen`, and a completely empty
   tap-to-detail test file.

---

## Critical Issues

### CR-01: `MagicCard.fromJson` crashes on missing `type_line` field

**File:** `lib/shared/models/magic_card.dart:143`
**Issue:** `json['type_line'] as String` throws a `TypeError` (not a `DioException`) when
Scryfall omits or nulls `type_line`. This occurs on token cards and some split cards in
production Scryfall data. The error escapes the `try/on DioException` block in
`ScryfallApiClient` because it is a Dart cast error — it propagates as an unhandled exception
to the Riverpod provider, producing a broken UI with no user-visible error message. The same
pattern exists in `CardFace.fromJson` at line 36.

**Fix:**
```dart
// magic_card.dart line 143 — in MagicCard.fromJson
typeLine: (json['type_line'] as String?) ?? '',

// magic_card.dart line 36 — in CardFace.fromJson
typeLine: (json['type_line'] as String?) ?? '',
```

Alternatively, wrap the entire `MagicCard.fromJson` body in a broad `try/catch` that maps
parse errors to a `Failure` result (requires moving parsing inside `ScryfallApiClient`).

---

## Warnings

### WR-01: Null-assertion on `response.data` escapes `DioException` catch block

**File:** `lib/features/card_discovery/data/scryfall_api_client.dart:35` (also line 54)
**Issue:** `response.data!` and `MagicCard.fromJson(response.data!)` can throw
`Null check operator used on a null value` or a `TypeError` if Scryfall returns HTTP 200 with
a null or malformed body. These are `Error`/`Exception` subtypes, not `DioException`, so they
are not caught by `on DioException catch (e)` and propagate as unhandled exceptions.

**Fix:**
```dart
Future<Result<MagicCard>> getRandomCard({String? query}) async {
  try {
    final response = await _dio.get<Map<String, dynamic>>(
      '/cards/random',
      queryParameters: _buildQueryParams(query),
    );
    final data = response.data;
    if (data == null) return Failure(NetworkFailure(message: 'Empty response'));
    final card = MagicCard.fromJson(data);
    return Success(card);
  } on DioException catch (e) {
    return Failure(_mapDioException(e));
  } catch (e) {
    return Failure(NetworkFailure(message: e.toString()));
  }
}
```
Apply the same change to `getCardById`.

### WR-02: Index access on `cardFaces[0]` without length guard

**File:** `lib/features/card_detail/presentation/card_detail_screen.dart:60`
**Issue:** `card.cardFaces?[0].manaCost` accesses index 0 without a length check. The current
`fromJson` only sets `cardFaces` when `rawFaces.length >= 2`, but the `cardFaces` field type is
`List<CardFace>?` with no minimum-length guarantee enforced by the type. If `cardFaces` is ever
assigned a list with fewer than 2 elements by any code path, this crashes with a `RangeError`.
The code also uses `!` elsewhere in the DFC section relying on the same implicit contract.

**Fix:**
```dart
// Replace line 60
final displayManaCost = card.manaCost ??
    ((card.cardFaces?.isNotEmpty ?? false) ? card.cardFaces![0].manaCost : null);
```

### WR-03: Multiple concurrent `getCardById` requests possible from `FavouriteSwipeScreen`

**File:** `lib/features/favourites/presentation/favourite_swipe_screen.dart:142-165`
**Issue:** The `onTap` callback is `async` but there is no guard to prevent the user from
tapping the same card multiple times before the first `getCardById` response arrives. Each tap
fires an independent network request. If two requests complete in different orders, the user
could navigate to an unexpected card detail screen. There is also no loading indicator during
the fetch, so the UI appears unresponsive for the duration of the call.

**Fix:** Add a local `bool _isLoading` state variable and guard the `onTap` body:
```dart
// In _FavouriteSwipeScreenState — add field
bool _isFetchingDetail = false;

// In cardBuilder onTap
onTap: () async {
  if (_isFetchingDetail) return;
  setState(() => _isFetchingDetail = true);
  try {
    final result = await ref.read(cardRepositoryProvider).getCardById(card.id);
    // ... existing switch ...
  } finally {
    if (mounted) setState(() => _isFetchingDetail = false);
  }
},
```

### WR-04: CARD-01 tap-to-detail test is entirely unimplemented

**File:** `test/widgets/card_discovery/card_swipe_screen_tap_test.dart:9-27`
**Issue:** Both test cases in the file are `skip: true` with empty bodies and TODO comments.
CARD-01 (tap card opens detail screen) is a primary acceptance criterion for this phase. The
navigation path through `context.go('/card/${card.id}', extra: card)` in
`CardSwipeScreen._buildSwipeStack` and the `getCardById` fetch path in `FavouriteSwipeScreen`
are completely untested. A crash or regression in either path would not be caught by CI.

**Fix:** Implement both tests before this phase is marked Done, per the project's Definition of
Done. Minimum coverage needed:
- Pump `CardSwipeScreen` with a mocked `cardRepositoryProvider` returning a known card.
- Simulate a tap on `_CardFaceWidget`.
- Assert GoRouter navigated to `/card/<id>` and `state.extra` is the correct `MagicCard`.
- Pump `FavouriteSwipeScreen` with a mocked repository.
- Simulate a tap, assert navigation to `/card/<id>`.

---

## Info

### IN-01: Hardcoded text style values in `FlexibleSpaceBar.title`

**File:** `lib/features/card_detail/presentation/card_detail_screen.dart:89-93`
**Issue:** `fontSize: 16` and `fontWeight: FontWeight.w600` are hardcoded inline rather than
derived from `Theme.of(context).textTheme`. This deviates from the project rule "no magic
numbers" and the convention of using `Theme.of(context)` for all text styles.

**Fix:**
```dart
title: Text(
  displayName,
  style: Theme.of(context).textTheme.titleMedium?.copyWith(
    color: AppColors.onBackground,
  ),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
),
```

### IN-02: `fakeMagicCard` default legalities map is missing the `pauper` key

**File:** `test/fixtures/fake_magic_card.dart:55-63`
**Issue:** `_LegalitiesSection` in `CardDetailScreen` explicitly renders a row for `'pauper'`
(line 397 of `card_detail_screen.dart`). The default legalities map in `fakeMagicCard` does not
include `'pauper'`. Tests that assert on badge counts or specific badge text for pauper using
`fakeMagicCard()` without override will silently test an incomplete legalities set.

**Fix:** Add `'pauper': 'legal'` (or a representative value) to the default legalities map in
`fakeMagicCard`:
```dart
legalities: legalities ??
    const {
      'standard': 'not_legal',
      'modern': 'legal',
      'legacy': 'legal',
      'commander': 'legal',
      'pioneer': 'not_legal',
      'vintage': 'legal',
      'pauper': 'legal', // add this
    },
```

### IN-03: `rarity[0]` string index in `_ActiveFilterBar` without empty-string guard

**File:** `lib/features/card_discovery/presentation/card_swipe_screen.dart:416`
**Issue:** `rarity[0].toUpperCase() + rarity.substring(1)` throws a `RangeError` if `rarity`
is an empty string. Scryfall always provides a non-empty rarity, but the project pattern
throughout is to guard against unexpected API values rather than rely on Scryfall spec
compliance.

**Fix:**
```dart
label: Text(
  rarity.isNotEmpty
      ? rarity[0].toUpperCase() + rarity.substring(1)
      : rarity,
  style: chipLabelStyle,
),
```

---

_Reviewed: 2026-04-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
