---
phase: 03-favourites
verified: 2026-04-17T00:00:00Z
status: passed
score: 8/8 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 6/8
  gaps_closed:
    - "Unit tests for FavouritesNotifier cover FAV-01/FAV-04/FAV-05 with real assertions — 6 tests pass, 0 skip markers"
    - "Unit tests for client-side filter cover FAV-07 with real assertions — 6 tests pass, 0 skip markers, applyFilter() helper present"
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "Swipe up on a card in the discovery screen"
    expected: "Bookmark icon fills (Icons.favorite in AppColors.error) immediately without delay; 'Saved to Favourites' Snackbar appears"
    why_human: "Animation and gesture behavior plus Snackbar timing cannot be verified programmatically without a running app"
  - test: "Tap the bookmark icon (Icons.favorite_border) on a card"
    expected: "Same save behavior as swipe-up: icon fills, Snackbar shows 'Saved to Favourites'"
    why_human: "Tap gesture and icon state transition requires a real device or integration test harness"
  - test: "Save a card, force-close and reopen the app"
    expected: "The saved card still appears in the Favourites grid (Hive CE persistence across sessions)"
    why_human: "App-restart persistence cannot be verified without running the app"
  - test: "Tap a card in the Favourites grid"
    expected: "FavouriteSwipeScreen opens starting at the tapped card (correct initialIndex seek)"
    why_human: "Navigation behavior and correct card seek requires a running app"
  - test: "Tap the delete button (trash icon) in FavouriteSwipeScreen AppBar, then tap Undo"
    expected: "Card is removed immediately; 'Undo' Snackbar appears for 3 seconds; tapping Undo restores the card"
    why_human: "Undo closure behavior and Snackbar timing requires a running app"
  - test: "Open filter bottom sheet, select a colour, and verify grid narrows"
    expected: "Only cards matching selected colour appear; 'No cards match your filters.' shown when filter eliminates all; 'Clear Filters' button resets"
    why_human: "Filter UI interaction with real data requires a running app"
---

# Phase 3: Favourites Verification Report

**Phase Goal:** Implement the full favourites feature — save cards, view/filter/swipe favourites, persist across sessions.
**Verified:** 2026-04-17T00:00:00Z
**Status:** human_needed
**Re-verification:** Yes — after gap closure (Plan 03-06)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | FavouriteCard domain model with all 10 fields and FavouriteCardAdapter (typeId: 1) exists | VERIFIED | `lib/features/favourites/domain/favourite_card.dart` — 10 fields, typeId=1, ISO-8601 savedAt, colors list cast |
| 2 | Hive box opened in main.dart before runApp, adapter registered | VERIFIED | `lib/main.dart` — registerAdapter(FavouriteCardAdapter()) + openBox<FavouriteCard>('favourites') before runApp |
| 3 | FavouritesNotifier.add() persists card, isFavourite() returns true (FAV-01); remove() deletes (FAV-04); state sorted newest first; keepAlive: true (FAV-05) | VERIFIED | providers.dart — add(), remove(), isFavourite(), _sorted() all implemented; @Riverpod(keepAlive: true) |
| 4 | filteredFavouritesProvider applies colour/type/rarity AND logic client-side; FavouritesFilterNotifier is autoDispose (FAV-07, D-10, D-11) | VERIFIED | providers.dart — filteredFavourites with colorMatch/typeMatch/rarityMatch AND; @riverpod (autoDispose default) |
| 5 | FavouritesScreen shows 3-column SliverGrid, empty states, multi-select, filter bottom sheet (FAV-02, FAV-06, FAV-07) | VERIFIED | favourites_screen.dart — SliverGrid.count(crossAxisCount:3), PopScope, _isSelecting, filteredFavouritesProvider watched |
| 6 | FavouriteSwipeScreen shows all favourites starting at tapped card, delete with Undo (FAV-03, FAV-04) | VERIFIED | favourite_swipe_screen.dart — CardSwiper with initialIndex, _deleteCurrent with Snackbar + Undo, addPostFrameCallback guard |
| 7 | Unit tests for FavouritesNotifier cover FAV-01/FAV-04/FAV-05 with real assertions (6 tests, 0 skips) | VERIFIED | flutter test: +6 All tests passed; grep -c "skip:" returns 0 |
| 8 | Unit tests for client-side filter cover FAV-07 with real assertions (6 tests, 0 skips, applyFilter helper) | VERIFIED | flutter test: +6 All tests passed; grep -c "skip:" returns 0; applyFilter() present |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/features/favourites/domain/favourite_card.dart` | FavouriteCard model + FavouriteCardAdapter (typeId: 1) | VERIFIED | 10 fields, typeId=1, ISO-8601 savedAt, colors cast |
| `lib/features/favourites/data/favourites_repository.dart` | FavouritesRepository — Hive write-through | VERIFIED | getAll/save/delete/contains with doc comments |
| `lib/features/favourites/presentation/providers.dart` | FavouritesNotifier, FavouritesFilterNotifier, filteredFavouritesProvider | VERIFIED | keepAlive:true, autoDispose, AND filter logic |
| `lib/features/favourites/presentation/providers.g.dart` | Code-generated provider file | VERIFIED | Generated by build_runner |
| `lib/features/favourites/presentation/favourites_screen.dart` | Full FavouritesScreen with SliverGrid | VERIFIED | SliverGrid.count(3), PopScope, multi-select, filter sheet, empty states |
| `lib/features/favourites/presentation/favourite_swipe_screen.dart` | Full FavouriteSwipeScreen | VERIFIED | CardSwiper with initialIndex, delete + Undo Snackbar, empty-list guard |
| `lib/shared/providers/favourites_provider.dart` | Re-export of favouritesProvider for cross-feature access | VERIFIED | Thin export; card_discovery uses this, not favourites/presentation/ directly |
| `lib/main.dart` | Hive adapter + box init before runApp | VERIFIED | registerAdapter and openBox present before runApp |
| `test/unit/favourites/favourites_notifier_test.dart` | 6 real unit tests, 0 skip markers | VERIFIED | 6 pass, 0 skip |
| `test/unit/favourites/favourites_filter_test.dart` | 6 real unit tests, applyFilter(), 0 skip markers | VERIFIED | 6 pass, 0 skip, applyFilter() present |
| `test/fixtures/fake_favourite_card.dart` | fakeFavouriteCard() with 10 optional named params | VERIFIED | Factory exists with all D-12 fields |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/main.dart` | `favourite_card.dart` | import + registerAdapter + openBox | WIRED | Both registration and box open before runApp |
| `providers.dart` | `favourite_card.dart` | FavouriteCard type import | WIRED | Direct import; FavouriteCard used in all three providers |
| `favourites_screen.dart` | `providers.dart` | ref.watch(filteredFavouritesProvider) | WIRED | filteredFavouritesProvider and favouritesProvider both watched |
| `favourite_swipe_screen.dart` | `providers.dart` | ref.watch(favouritesProvider) | WIRED | favouritesProvider watched; remove called on delete |
| `card_swipe_screen.dart` | `shared/providers/favourites_provider.dart` | ref.read(favouritesProvider.notifier).add() | WIRED | Import at line 15; used in both save paths |
| `shared/providers/favourites_provider.dart` | `favourites/presentation/providers.dart` | export show | WIRED | Re-exports favouritesProvider and FavouritesNotifier |
| `favourites_notifier_test.dart` | `providers.dart` | container.read(favouritesProvider) | WIRED | Direct reads in all 6 tests |
| `favourites_filter_test.dart` | `providers.dart` | show FavouritesFilter | WIRED | FavouritesFilter imported; used in applyFilter() |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `favourites_screen.dart` | filtered (List<FavouriteCard>) | filteredFavouritesProvider -> favouritesProvider -> Hive box | Yes — reads from on-disk Hive store | FLOWING |
| `favourite_swipe_screen.dart` | favourites (List<FavouriteCard>) | ref.watch(favouritesProvider) -> Hive box | Yes — same Hive box | FLOWING |
| `card_swipe_screen.dart` (bookmark) | isFav (bool) | isFavourite(card.id) -> Hive.box.containsKey | Yes — synchronous in-memory Hive check | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| 6 FavouritesNotifier unit tests pass | flutter test test/unit/favourites/favourites_notifier_test.dart | +6: All tests passed | PASS |
| 6 filter unit tests pass | flutter test test/unit/favourites/favourites_filter_test.dart | +6: All tests passed | PASS |
| 5 widget tests pass | flutter test test/widgets/favourites/ | +5: All tests passed | PASS |
| Zero skip markers in unit test files | grep -c "skip:" test/unit/favourites/*.dart | 0/0 | PASS |
| Full unit/favourites suite: 21 tests | flutter test test/unit/favourites/ | +21: All tests passed | PASS |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| FAV-01 | 03-00, 03-03 | User can save card to Favourites (swipe up or button) | SATISFIED | Both save paths implemented in card_swipe_screen.dart; unit test "add() stores card and isFavourite() returns true" passes |
| FAV-04 | 03-00, 03-05 | User can remove card from Favourites via delete button | SATISFIED | _deleteCurrent in favourite_swipe_screen.dart; unit test "remove() deletes card" passes |
| FAV-05 | 03-00, 03-01, 03-02 | Favourites persist across sessions (Hive CE) | SATISFIED | Hive box opened in main.dart; keepAlive:true; unit test "Hive box persists after close and reopen" passes |
| FAV-07 | 03-00, 03-02, 03-04 | Filter Favourites grid by colour/type/rarity | SATISFIED | filteredFavouritesProvider AND logic; filter bottom sheet in favourites_screen.dart; 6 filter unit tests pass |
| D-10 | 03-02, 03-04 | Filter state resets on tab leave (autoDispose) | SATISFIED | FavouritesFilterNotifier annotated @riverpod (autoDispose default in Riverpod 3.x) |
| D-11 | 03-02, 03-04 | Derived provider watches both state sources | SATISFIED | filteredFavourites watches both favouritesProvider and favouritesFilterProvider |

### Anti-Patterns Found

None. No TODO/FIXME/placeholder comments found in production files. No empty return stubs. No hardcoded empty data passed to rendering paths.

### Human Verification Required

The following behaviors require a running app to verify. All automated checks pass.

#### 1. Swipe-up save gesture

**Test:** On the card discovery screen, swipe a card upward.
**Expected:** Bookmark icon fills immediately (Icons.favorite, AppColors.error). 'Saved to Favourites' Snackbar appears for ~2 seconds.
**Why human:** Gesture velocity thresholds, animation timing, and Snackbar visual appearance cannot be verified programmatically.

#### 2. Bookmark button tap

**Test:** Tap the bookmark icon (Icons.favorite_border, bottom-right corner of card) on an unsaved card.
**Expected:** Icon fills; 'Saved to Favourites' Snackbar appears. Tapping the filled icon has no effect (onPressed: null).
**Why human:** Touch interaction and icon state transition requires a running device.

#### 3. App-restart persistence

**Test:** Save one or more cards to Favourites. Force-close and reopen the app.
**Expected:** All saved cards appear in the Favourites grid after restart.
**Why human:** Hive CE persistence across full app lifecycle cannot be verified without running the app.

#### 4. Grid tap navigation and initial card seek

**Test:** With multiple favourites saved, tap the second card in the grid.
**Expected:** FavouriteSwipeScreen opens and the second card (by savedAt order) is the starting card — not the first.
**Why human:** Navigation routing and correct initialIndex resolution requires a running app.

#### 5. Delete + Undo flow

**Test:** Open a card in FavouriteSwipeScreen. Tap the delete button (trash icon, AppBar). Within 3 seconds, tap 'Undo'.
**Expected:** Card disappears from grid immediately; Snackbar shows "{card.name} removed" with Undo action; tapping Undo restores the card.
**Why human:** Snackbar timing, closure capture, and state restoration requires a running app.

#### 6. Filter bottom sheet interaction

**Test:** Open Favourites screen with cards of different colours. Tap the filter icon. Select 'Red' colour chip. Close sheet.
**Expected:** Grid narrows to only red cards. If no red cards exist, 'No cards match your filters.' appears with 'Clear Filters' button. Tapping 'Clear Filters' restores full grid.
**Why human:** Filter UI interaction with real persisted data requires a running app.

### Gaps Summary

No gaps remain. Both gaps from the initial verification are closed:

- `favourites_notifier_test.dart`: 6 real assertions, 0 skip markers (closed by Plan 03-06)
- `favourites_filter_test.dart`: 6 real assertions, 0 skip markers, applyFilter() helper present (closed by Plan 03-06)

All production code was fully verified in the initial verification report. Status is `human_needed` because 6 runtime behaviors (gesture animation, app-restart persistence, navigation seek, Snackbar timing, filter UI) cannot be confirmed programmatically and were already identified in the first verification pass.

---

_Verified: 2026-04-17T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
_Re-verification: Yes — after Plan 03-06 gap closure_
