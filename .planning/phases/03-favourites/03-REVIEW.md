---
phase: 03-favourites
reviewed: 2026-04-17T00:00:00Z
depth: standard
files_reviewed: 16
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
  - test/unit/favourites/favourites_filter_test.dart
  - test/unit/favourites/favourites_notifier_test.dart
findings:
  critical: 0
  warning: 7
  info: 7
  total: 14
status: issues_found
---

# Phase 03: Code Review Report

**Reviewed:** 2026-04-17T00:00:00Z
**Depth:** standard
**Files Reviewed:** 16 (14 original + 2 unit test files reviewed in depth)
**Status:** issues_found

## Summary

The Phase 3 Favourites feature is well-structured overall. The data model, adapter,
notifier, and filter logic are cleanly separated and consistent with the patterns
established in earlier phases. The widget code correctly handles the empty, filtered-empty,
and populated states. Architecture boundaries (CLAUDE.md feature isolation) are respected.

This update adds findings from a dedicated review of the two unit test files
(`favourites_notifier_test.dart` and `favourites_filter_test.dart`). The notifier tests
are fully implemented and passing (not stubs as previously reported — IN-01 from the prior
pass is corrected below). Two new warnings were added: a Hive flush gap before close in
the persistence test, and a shared temp-dir collision risk under parallel test execution.
Two new info items cover missing edge-case tests for colourless cards and multi-colour OR
logic, plus the divergence risk in the duplicated `applyFilter` helper.

No critical issues were found.

---

## Warnings

### WR-01: Widget test helper uses `List<dynamic>` instead of `List<FavouriteCard>` — type safety hole

**File:** `test/widgets/favourites/favourites_screen_test.dart:13-31`

**Issue:** `pumpScreen` accepts `List<dynamic>` for both `cards` and `filtered`, then passes
them directly to `favouritesProvider.overrideWithValue(List.from(favourites))`. Because the
list is `List<dynamic>` rather than `List<FavouriteCard>`, passing non-card objects silently
compiles. The downstream code will cast at runtime in `_buildBody`, producing confusing type
errors instead of a clean assertion failure.

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
read once at construction time. The clamped `_currentIndex` on the Dart side drifts from the
swiper's internal position counter, so `_deleteCurrent` captures `currentCard` from
`favourites[_currentIndex]`, which may point to the wrong card after the swiper has
independently advanced.

**Fix:** On clamp, use `_swiperController` to move the swiper to the new index, or rely
exclusively on the `onSwipe` callback to track current position and remove the out-of-band
clamp:
```dart
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

### WR-03: `_deleteCurrent` captures a redundant copy — misleading comment creates future maintenance risk

**File:** `lib/features/favourites/presentation/favourite_swipe_screen.dart:128-130`

**Issue:** `final deleted = card;` is an alias, not a copy. The comment "Capture before
removing — needed for undo closure" implies there is a mutation of `card` between capture and
use, which is false for an immutable value parameter. If a future refactor changes `card` to
be retrieved from the live list rather than passed as a parameter, the comment would
incorrectly suggest a copy is still sufficient.

**Fix:** Remove the alias and use `card` directly throughout the method body, and remove or
rewrite the misleading comment.

---

### WR-04: `filteredFavouritesProvider` and `favouritesFilterProvider` both `autoDispose` — momentary state inconsistency on tab reentry

**File:** `lib/features/favourites/presentation/providers.dart:94-143`

**Issue:** `FavouritesScreen` watches both `favouritesFilterProvider` and
`filteredFavouritesProvider` in the same `build` call. When the filter provider is recreated
after autoDispose (on tab reentry), `filter` and `filtered` can be momentarily inconsistent
within a single frame: `filter` might show non-empty while `filtered` returns the full list,
causing the "No cards match your filters." empty state to flash briefly.

**Fix:** Do not watch `favouritesFilterProvider` independently in the widget for the purpose
of passing to `_buildBody`. Derive filter state inside `filteredFavouritesProvider` or use a
single derived provider, and only watch `favouritesFilterProvider` where its state is needed
as discrete chip values (e.g. in the bottom sheet).

---

### WR-05: `rarity.substring(1)` panics on empty rarity string

**File:** `lib/features/card_discovery/presentation/card_swipe_screen.dart:437`
**File:** `lib/features/favourites/presentation/favourites_screen.dart:462`

**Issue:** Both files capitalise the rarity display with:
```dart
rarity[0].toUpperCase() + rarity.substring(1)
```
If a corrupted preset or unexpected API value produces an empty rarity string, `rarity[0]`
throws a `RangeError`. Scryfall values are controlled but the code makes no guarantee.

**Fix:**
```dart
String _capitalise(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
```
Use this helper in both files instead of the inline expression.

---

### WR-06: Persistence test calls `Hive.close()` without flushing — written card may not reach disk

**File:** `test/unit/favourites/favourites_notifier_test.dart:96-116`

**Issue:** The test at line 96 adds a card via `notifier.add(card)` (line 98), then
immediately calls `container.dispose()` and `await Hive.close()` (lines 101-102) without an
intermediate `await box.flush()`. Hive CE's `put()` is synchronous in-memory, but the actual
file write is buffered. `Hive.close()` does flush before closing, so this is likely safe in
practice — however the documented Hive CE contract is that `flush()` should be called
explicitly before `close()` when write persistence is the thing being tested. If a future Hive
CE version changes flush-on-close behaviour, this test will silently pass while `reopened` is
empty, giving a false `containsKey` failure instead of a clear assertion.

**Fix:**
```dart
// After notifier.add(card) and before Hive.close():
await Hive.box<FavouriteCard>('favourites').flush();
container.dispose();
await Hive.close();
```

---

### WR-07: Hive initialised to `Directory.systemTemp.path` — shared across parallel test processes, causing box file collisions

**File:** `test/unit/favourites/favourites_notifier_test.dart:15`

**Issue:** `Hive.init(Directory.systemTemp.path)` uses the system temporary directory, which
is the same path used by `test/unit/filters/filter_presets_notifier_test.dart:17`. When
`flutter test` runs with `--concurrency > 1` (the default on multi-core machines), both test
files run in separate isolates that share the same filesystem path. If both initialise Hive
at `/tmp` simultaneously and one opens a box with a name that clashes (unlikely here since
`'favourites'` vs `'filter_presets'` are different), the box files are fine — but if the same
test file is run twice concurrently (e.g. in watch mode or CI retry), the two processes will
fight over `/tmp/favourites.hive`, producing flaky failures or corrupt box state.

**Fix:** Use an isolated temp subdirectory per test run:
```dart
setUp(() async {
  final dir = await Directory.systemTemp.createTemp('hive_test_');
  Hive.init(dir.path);
  // ...
});

tearDown(() async {
  container.dispose();
  await Hive.close();
  // Optionally delete dir.path to avoid temp accumulation.
});
```
Store `dir` in a `late Directory _testDir` field so tearDown can delete it.

---

## Info

### IN-01: (CORRECTED) Unit tests in `favourites_notifier_test.dart` are fully implemented — prior report was incorrect

**File:** `test/unit/favourites/favourites_notifier_test.dart`

**Issue:** The prior review pass (2026-04-16) incorrectly reported all tests in this file as
skipped stubs. The current file contains five fully-implemented, non-skipped tests covering:
initial state, add/isFavourite, remove/isFavourite, sort order, add-idempotency, and Hive
persistence across close/reopen. No corrective action is required for this item — it is
recorded here to correct the earlier finding.

---

### IN-02: `applyFilter()` in test file duplicates production logic — divergence risk with no enforcement mechanism

**File:** `test/unit/favourites/favourites_filter_test.dart:12-31`

**Issue:** The `applyFilter()` helper at lines 12-31 is an explicit copy of the `where`
block inside `filteredFavourites` in `providers.dart:130-143`. The doc comment (line 8) notes
that this "MUST stay in sync with the production provider (FAV-07)". However, there is no
automated mechanism to enforce this — a future change to the production filter logic will not
fail the test suite unless it also breaks the test's expected outputs, which may not happen if
the new logic only affects edge cases not exercised by the existing three test cards.

**Fix (option A — preferred):** Extract the filter predicate into a standalone pure function
in the production code (e.g. `lib/features/favourites/domain/favourites_filter_helper.dart`)
and import it in both `providers.dart` and the test. The test then exercises the actual
production function rather than a copy.

**Fix (option B — lighter weight):** Add a comment to `filteredFavourites` in `providers.dart`
cross-referencing the test helper and require both to be updated atomically in code review.

---

### IN-03: No test for multi-colour card where only one colour matches the filter (OR logic)

**File:** `test/unit/favourites/favourites_filter_test.dart`

**Issue:** The color filter tests (line 65-70) only test single-colour cards. The OR logic
`card.colors.any((c) => filter.colors.contains(c))` is the key behaviour for multi-colour
cards (e.g. a ['R', 'G'] card should match a filter of {'R'}). This path is not exercised.
If the implementation were accidentally changed to AND logic, the existing tests would not
catch it.

**Fix:** Add a test case:
```dart
test('color filter matches multi-colour card if any color matches', () {
  final gruulCard = fakeFavouriteCard(
    id: 'rg-card',
    colors: ['R', 'G'],
  );
  final filter = FavouritesFilter(colors: {'R'});
  final result = applyFilter([gruulCard], filter);
  expect(result.length, equals(1));
});
```

---

### IN-04: No test for colourless card behaviour when a colour filter is active

**File:** `test/unit/favourites/favourites_filter_test.dart`

**Issue:** A colourless card has `colors: []`. When a colour filter is active,
`card.colors.any(...)` on an empty list always returns `false`, so colourless cards are
always excluded. This is consistent with Magic: The Gathering semantics (colourless is not
a colour), but it is untested and undocumented. If the intent were ever to treat colourless as
a separate selectable option (common in filter UIs), the silent exclusion would be a bug.

**Fix:** Add a test that documents the intended behaviour:
```dart
test('colourless card is excluded when any colour filter is active', () {
  final colourless = fakeFavouriteCard(id: 'clrless', colors: []);
  final filter = FavouritesFilter(colors: {'R'});
  final result = applyFilter([colourless], filter);
  expect(result, isEmpty);
});
```

---

### IN-05: Intentional code duplication between two save-card methods in `card_swipe_screen.dart` is brittle

**File:** `lib/features/card_discovery/presentation/card_swipe_screen.dart:152-179` and `327-358`

**Issue:** Both methods are identical in logic. The comment "Intentional duplication" is
present but the two call sites can diverge silently in future changes (e.g., adding a
confirmation dialog, changing the snackbar duration). The justification for the duplication
is not explained.

**Fix:** Extract into a top-level or static helper that accepts `(WidgetRef ref, BuildContext
context, MagicCard card)` so both sites delegate to a single implementation.

---

### IN-06: Magic number `24` for check-circle icon size in multi-select overlay

**File:** `lib/features/favourites/presentation/favourites_screen.dart:294`

**Issue:**
```dart
const Icon(Icons.check_circle, color: AppColors.onBackground, size: 24),
```
`24` is a hardcoded size. The rest of the widget codebase uses `AppSpacing` constants
consistently. This single magic number breaks that pattern.

**Fix:**
```dart
const Icon(Icons.check_circle, color: AppColors.onBackground, size: AppSpacing.lg),
```
Verify that `AppSpacing.lg` resolves to 24 before substituting.

---

### IN-07: `_FavouritesFilterSheet` accepts `widgetRef` constructor parameter that is unused

**File:** `lib/features/favourites/presentation/favourites_screen.dart:353-359`

**Issue:** `_FavouritesFilterSheet` is a `ConsumerWidget` and receives its own `WidgetRef ref`
in `build`, but the constructor also accepts a `widgetRef` from the parent. The parent ref is
only passed to allow notifier calls — but since the sheet is a `ConsumerWidget`, `ref` from
`build` is sufficient for all reads and writes. The `widgetRef` field is unused in practice.

**Fix:** Remove the `widgetRef` constructor parameter and `final WidgetRef widgetRef;` field.
Use the sheet's own `ref` (from `ConsumerWidget.build`) for all operations, and update the
call site to `builder: (sheetContext) => const _FavouritesFilterSheet()`.

---

_Reviewed: 2026-04-17T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
