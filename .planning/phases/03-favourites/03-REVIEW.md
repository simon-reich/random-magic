---
phase: 03-favourites
reviewed: 2026-04-16T00:00:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - lib/features/card_discovery/presentation/card_swipe_screen.dart
  - lib/features/favourites/domain/favourite_card.dart
  - lib/features/favourites/presentation/favourite_swipe_screen.dart
  - lib/features/favourites/presentation/favourites_screen.dart
  - lib/features/favourites/presentation/providers.dart
  - lib/main.dart
  - lib/shared/models/magic_card.dart
  - lib/shared/providers/favourites_provider.dart
  - test/fixtures/fake_favourite_card.dart
  - test/unit/card_discovery/magic_card_colors_test.dart
  - test/unit/favourites/favourite_card_test.dart
  - test/unit/favourites/favourites_filter_test.dart
  - test/unit/favourites/favourites_notifier_test.dart
  - test/widgets/favourites/favourites_screen_test.dart
findings:
  critical: 0
  warning: 5
  info: 5
  total: 10
status: issues_found
---

# Phase 03: Code Review Report

**Reviewed:** 2026-04-16T00:00:00Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

The Phase 3 Favourites feature is well-structured overall. The data model, adapter,
notifier, and filter logic are cleanly separated and consistent with the patterns
established in earlier phases. The widget code correctly handles the empty, filtered-empty,
and populated states. Architecture boundaries (CLAUDE.md feature isolation) are respected
via the `shared/providers/favourites_provider.dart` re-export.

Five warnings were found — none are crashes in the happy path, but two will cause
observable bugs under reasonably common conditions (filter state mismatch in the widget
test harness; index clamping out of sync with the swiper). Five info-level items flag
missing test coverage, stub tests that are still skipped, a hardcoded magic number, and
code duplication.

No critical issues were found.

---

## Warnings

### WR-01: Widget test helper uses `List<dynamic>` instead of `List<FavouriteCard>` — type safety hole

**File:** `test/widgets/favourites/favourites_screen_test.dart:13-31`

**Issue:** `pumpScreen` accepts `List<dynamic>` for both `cards` and `filtered`, then passes
them directly to `favouritesProvider.overrideWithValue(List.from(favourites))`. Because the
list is `List<dynamic>` rather than `List<FavouriteCard>`, passing non-card objects silently
compiles. The downstream code will cast at runtime in `_buildBody`, which can produce confusing
test failures with type errors instead of a clean assertion failure. The correct API for the
provider is `List<FavouriteCard>`, and the test helper should enforce that.

**Fix:**
```dart
Future<void> pumpScreen(
  WidgetTester tester, {
  List<FavouriteCard> cards = const [],
  List<FavouriteCard>? filtered,
}) async {
  final filteredList = filtered ?? cards;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        favouritesProvider.overrideWithValue(List.from(cards)),
        filteredFavouritesProvider.overrideWithValue(List.from(filteredList)),
      ],
      child: const MaterialApp(home: FavouritesScreen()),
    ),
  );
  await tester.pump();
}
```

---

### WR-02: `FavouriteSwipeScreen` index clamp is applied to `_currentIndex` state only — swiper `initialIndex` is not updated

**File:** `lib/features/favourites/presentation/favourite_swipe_screen.dart:69-71`

**Issue:** When a card is deleted while the swipe screen is open, `_currentIndex` is clamped
to `favourites.length - 1` in the `build` method. However, `CardSwiper.initialIndex` is only
read once at construction time — it is not a live parameter. The clamped `_currentIndex` on
the Dart side drifts from the swiper's internal position counter, so `_deleteCurrent` captures
`currentCard` from `favourites[_currentIndex]` (line 73), which may now point to the wrong card
after the swiper has independently advanced. The bug is observable when the user:
1. Swipes to card N
2. Deletes card N-1 from another means (e.g., back-navigation is not possible here, but future
   routes or concurrent undo actions can restore/remove cards)
3. Taps delete — the wrong card may be removed.

The `onSwipe` callback does update `_currentIndex` via `setState`, but the clamp path bypasses
that and does not call `_swiperController` to reconcile the swiper position.

**Fix:** On clamp, use `_swiperController` to move the swiper to the new index, or rely
exclusively on the `onSwipe` callback to track current position and remove the out-of-band
clamp:
```dart
// In build(), replace the silent clamp with a post-frame controller move:
if (_currentIndex >= favourites.length) {
  final newIndex = favourites.length - 1;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      _swiperController.moveTo(newIndex);
      setState(() => _currentIndex = newIndex);
    }
  });
}
```

---

### WR-03: `_deleteCurrent` captures a redundant copy — `deleted` is always identical to `card`

**File:** `lib/features/favourites/presentation/favourite_swipe_screen.dart:128-130`

**Issue:** The method assigns `final deleted = card;` on line 129 and then uses `deleted`
throughout. `card` is already an immutable value parameter — `deleted` is just an alias.
This is not a bug but the comment "Capture before removing — needed for undo closure" is
misleading: there is no mutation of `card` between lines 129 and 130 that would make a copy
necessary. If a future refactor changes `card` to be retrieved from the live list rather than
passed as a parameter, the comment would suggest a copy is still safe when it is not. The
comment should either be removed or the method restructured to make the capture intent clear.

**Fix:**
```dart
void _deleteCurrent(FavouriteCard card) {
  ref.read(favouritesProvider.notifier).remove(card.id);

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Text(_Strings.deleteMessage(card.name)),
        action: SnackBarAction(
          textColor: AppColors.primary,
          label: _Strings.undo,
          onPressed: () => ref.read(favouritesProvider.notifier).add(card),
        ),
      ),
    );
}
```

---

### WR-04: `filteredFavouritesProvider` is `autoDispose` but `favouritesFilterProvider` is also `autoDispose` — filter chips remain selected after navigating away and back, but state may silently reset mid-session

**File:** `lib/features/favourites/presentation/providers.dart:94-112`

**Issue:** The doc comment on `FavouritesFilterNotifier` (line 93) correctly states that
autoDispose causes the filter to reset when the screen is disposed. However,
`filteredFavouritesProvider` (line 122) also has `isAutoDispose: true` (confirmed in the
generated code). If the filter provider disposes while there are still listeners on the
derived provider, Riverpod will recreate the filter provider first, returning an empty
`FavouritesFilter`. This is the intended behaviour and is documented.

The actual risk is that `FavouritesScreen` watches *both* `favouritesFilterProvider` and
`filteredFavouritesProvider` independently. If the filter provider is recreated between the
two `watch` calls in a single `build` frame (which can happen when the element tree is being
rebuilt after navigation), `filter` and `filtered` will be momentarily inconsistent: `filter`
might show non-empty while `filtered` returns the full list (or vice versa). This leads to the
"No cards match your filters." empty state flashing briefly when navigating to the tab.

**Fix:** Derive `filter` from inside `filteredFavouritesProvider` rather than watching both
independently in the widget. Alternatively, add a brief `select` to avoid unnecessary rebuilds:
```dart
// In FavouritesScreen.build():
final filtered = ref.watch(filteredFavouritesProvider);
final allFavourites = ref.watch(favouritesProvider);
// Do NOT watch favouritesFilterProvider separately in the same build —
// derive filter state only when needed (e.g. to pass to the bottom sheet).
```

---

### WR-05: `rarity` string assumed non-empty when building the chip label — `rarity.substring(1)` panics on empty string

**File:** `lib/features/card_discovery/presentation/card_swipe_screen.dart:437`  
**File:** `lib/features/favourites/presentation/favourites_screen.dart:462`

**Issue:** Both files capitalise the rarity display with:
```dart
rarity[0].toUpperCase() + rarity.substring(1)
```
`filterState.rarities` contains strings set by the user via `FilterSettingsNotifier` and is
unlikely to ever be empty. However, if a corrupted preset or an unexpected API value produces
an empty rarity string, `rarity[0]` throws a `RangeError`. The same pattern in
`favourites_screen.dart` line 462 has the same risk for the bottom sheet chip labels.
Scryfall rarity values are controlled, but the code makes no guarantee the set only contains
well-known values.

**Fix:**
```dart
// Replace the raw index access with a safe helper:
String _capitalise(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
```
Use this helper in both files instead of the inline expression.

---

## Info

### IN-01: All unit tests in `favourites_filter_test.dart` and `favourites_notifier_test.dart` are stubs — zero logic is actually tested

**File:** `test/unit/favourites/favourites_filter_test.dart:7-62`  
**File:** `test/unit/favourites/favourites_notifier_test.dart:31-84`

**Issue:** Every test in both files is skipped with `skip: 'Wave 0 stub — implementation
pending'` and contains only `expect(true, true)`. The underlying logic (`filteredFavourites`,
`FavouritesNotifier.add/remove/isFavourite`, sort order) is fully implemented but has zero
unit test coverage. The CLAUDE.md definition of done requires tests to pass, not just exist.
These stubs pass vacuously and give false confidence.

**Fix:** Implement the tests per the TODO comments. The `favourite_card_test.dart` file
provides a working Hive round-trip harness that can be reused directly in
`favourites_notifier_test.dart`. The filter logic in `providers.dart:130-143` is pure and
can be tested without Hive at all.

---

### IN-02: Intentional code duplication between `_CardSwipeScreenState._saveCardToFavourites` and `_CardFaceWidget._saveToFavourites` is brittle

**File:** `lib/features/card_discovery/presentation/card_swipe_screen.dart:152-179` and `327-358`

**Issue:** Both methods are identical in logic. The comment "Intentional duplication" is
present but the two call sites can diverge silently in future changes (e.g., adding a
confirmation dialog, changing the snackbar duration). The justification for the duplication
is not explained in the comment.

**Fix:** Extract into a top-level or static helper that accepts `(WidgetRef ref, BuildContext
context, MagicCard card)` so both sites delegate to a single implementation:
```dart
void _doSaveCardToFavourites(BuildContext context, WidgetRef ref, MagicCard card) {
  final notifier = ref.read(favouritesProvider.notifier);
  if (notifier.isFavourite(card.id)) return;
  notifier.add(FavouriteCard(/* ... */));
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(/* ... */);
}
```

---

### IN-03: Magic number `24` for the check-circle icon size in the multi-select overlay

**File:** `lib/features/favourites/presentation/favourites_screen.dart:294`

**Issue:**
```dart
const Icon(Icons.check_circle, color: AppColors.onBackground, size: 24),
```
`24` is a hardcoded size. The rest of the widget codebase uses `AppSpacing` constants
consistently (e.g., `AppSpacing.md`, `AppSpacing.xxl`). This single magic number breaks
that pattern and will not scale with any future `AppSpacing` audit.

**Fix:**
```dart
const Icon(Icons.check_circle, color: AppColors.onBackground, size: AppSpacing.lg),
```
(Assuming `AppSpacing.lg` resolves to 24, which is typical for this type of spacing scale.
Verify the actual constant value.)

---

### IN-04: `favourite_card_test.dart` does not test `FavouriteCardAdapter.write` field ordering directly

**File:** `test/unit/favourites/favourite_card_test.dart:83-88`

**Issue:** The adapter typeId is tested (`typeId is 1`) but the field ordering of
`FavouriteCardAdapter.write` (fields 0–9) is only tested implicitly via round-trip. If the
write order is changed (e.g., a new field inserted between existing ones), the round-trip
test will fail — but only after data has already been written to disk in production. The
round-trip test does catch the regression, but there is no test asserting the field positions
match the documented contract in the class comment.

**Fix:** Add a test that writes a card, reads back raw bytes via `BinaryReader`, and asserts
field values at their documented positions. This is a belt-and-suspenders guard against the
migration risk documented in the adapter class comment.

---

### IN-05: `_FavouritesFilterSheet` passes parent `WidgetRef` instead of using its own `ref`

**File:** `lib/features/favourites/presentation/favourites_screen.dart:353-359`

**Issue:** `_FavouritesFilterSheet` is a `ConsumerWidget` and therefore receives its own
`WidgetRef ref` in `build`. However, the constructor also accepts `widgetRef` from the parent
and the sheet uses `ref.watch(favouritesFilterProvider)` on its own ref (line 391) while also
holding the parent ref in `widgetRef`. The parent ref `widgetRef` is only passed to allow
`_openFilterSheet` to call `favouritesFilterProvider.notifier` — but since the sheet is a
`ConsumerWidget`, it can use `ref` directly for all reads and writes. The `widgetRef` field is
unused in practice and the field is unnecessary.

**Fix:** Remove the `widgetRef` constructor parameter and `final WidgetRef widgetRef;` field.
The sheet's own `ref` (from `ConsumerWidget.build`) is sufficient for all operations:
```dart
class _FavouritesFilterSheet extends ConsumerWidget {
  const _FavouritesFilterSheet(); // No widgetRef parameter needed

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(favouritesFilterProvider);
    final notifier = ref.read(favouritesFilterProvider.notifier);
    // ...
  }
}

// In _openFilterSheet:
builder: (sheetContext) => const _FavouritesFilterSheet(),
```

---

_Reviewed: 2026-04-16T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
