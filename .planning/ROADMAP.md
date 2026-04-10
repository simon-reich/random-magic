# Roadmap: Random Magic

**Created:** 2026-04-10
**Core Value:** Tactile, swipeable MTG card discovery — always one swipe away from a new random card
**Current milestone:** v1.0 — Full feature app

## Milestone Overview

| Phase | Name | Goal | Status |
|-------|------|------|--------|
| Phase 1 | CardSwipeScreen | Working swipe UI with artwork, metadata overlay, loading & error states | 🔲 Next |
| Phase 2 | Filter Settings & Presets | Filter UI wired to Scryfall query, named preset persistence | 🔲 Pending |
| Phase 3 | Favourites | Save / browse / delete favourites with Hive CE persistence | 🔲 Pending |
| Phase 4 | Card Detail View | Full card metadata, prices, format legalities | 🔲 Pending |
| Phase 5 | Tests | 80%+ logic coverage, all screen states tested, integration test | 🔲 Pending |

---

## Phase 1: CardSwipeScreen

**Goal:** Replace the `CardSwipeScreen` placeholder with the real implementation. After this phase, users can swipe through random MTG cards with full-screen artwork, a metadata overlay, shimmer loading, and three distinct error states.

**Jira:** RM-13

**Covers:** DISC-01 through DISC-09, QA-04, QA-05, QA-06

**Depends on:** Nothing (infrastructure complete)

**Key decisions from research:**
- Swipe gesture via `GestureDetector.onHorizontalDragEnd` (velocity threshold ~300px/s) — no third-party swipe package needed for RM-13's acceptance criteria
- Loading state via `skeletonizer ^1.x` package (wraps real widget tree — no separate skeleton layout)
- Swipe disabled during loading to prevent race conditions (gate via `cardState.isLoading`)
- `AnimatedSwitcher` + `ValueKey(card.id)` for crossfade between cards
- 429 rate limit mapped to `RateLimitedFailure` (new type in `shared/failures.dart`)
- `legalities` map parsed defensively via `.toString()` conversion
- Null image URL guard before `CachedNetworkImage`

**Plans:**
1. Add `skeletonizer` to pubspec; run `flutter pub get`
2. Add `RateLimitedFailure` to `shared/failures.dart`; fix `legalities` cast in `MagicCard.fromJson()`
3. Implement `CardSwipeScreen` — artwork display, metadata overlay, swipe gesture, loading + error states

**UAT:**
- [ ] Swipe left or right loads a new random card (shimmer shown during load)
- [ ] Card artwork fills the screen; name, type line, rarity visible in bottom overlay
- [ ] Swiping while loading is ignored (no race condition)
- [ ] 404 → distinct "No cards found" state with "Adjust Filters" button
- [ ] 422 → distinct "Invalid filter settings" state with filter link
- [ ] Network error → distinct "Could not reach Scryfall" state with Retry button
- [ ] `flutter analyze --fatal-infos` passes

---

## Phase 2: Filter Settings & Presets

**Goal:** Implement the `FilterSettingsScreen` with colour/type/rarity/date filter UI, wire it to `RandomCardNotifier` via `ActiveFilterQuery`, and persist named filter presets in Hive CE.

**Covers:** FILT-01 through FILT-10, DISC-10

**Depends on:** Phase 1

**Key decisions from research:**
- `ActiveFilterQuery` provider (`keepAlive: true`) bridges filter settings to `RandomCardNotifier.build()`
- `RandomCardNotifier` watches `activeFilterQueryProvider` — filter changes auto-trigger new card fetch
- `ScryfallQueryBuilder` is a pure static class in `features/filters/data/`
- `FilterPreset` stored in Hive CE box `'filter_presets'` with `typeId: 0`
- Preset name used as box key — upsert semantics for edit; `containsKey` guard for create
- Hive boxes opened in `main()` before `runApp()` (needed here; implement in this phase)
- Colour UI: row of W/U/B/R/G/C/M toggle buttons (mana symbol icons or coloured circles)
- Type/rarity UI: Material 3 filter chips in wrap layout, multi-select
- Date range: two date picker fields (Released After / Released Before)

**Plans:**
1. Initialize Hive CE in `main.dart` (open boxes before `runApp`); create `FilterPreset` domain model + Hive adapter
2. Implement `ScryfallQueryBuilder.fromPreset()` + `ActiveFilterQuery` provider + `FilterPresetsNotifier`
3. Update `RandomCardNotifier` to `ref.watch(activeFilterQueryProvider)` in `build()`
4. Implement `FilterSettingsScreen` — filter chips, date pickers, preset save/select/delete
5. Add active filter summary bar to `CardSwipeScreen`

**UAT:**
- [ ] Setting colour + type filter and returning to swipe screen fetches cards matching those filters
- [ ] Empty filter → unrestricted random card (no `q` param)
- [ ] Save preset → appears in preset list → selecting it restores filter state
- [ ] Duplicate preset name blocked with inline error
- [ ] Delete preset → removed from list
- [ ] Active filter chips visible on swipe screen; tapping X removes that filter
- [ ] `flutter analyze --fatal-infos` passes

---

## Phase 3: Favourites

**Goal:** Implement the full favourites feature — save cards from the swipe screen, browse in a grid, swipe through saved cards, filter within favourites, and delete.

**Covers:** FAV-01 through FAV-07

**Depends on:** Phase 2 (Hive CE initialized, box lifecycle established)

**Key decisions from research:**
- `FavouriteCard` projection in `features/favourites/domain/` — do NOT persist full `MagicCard`; include only display fields + `savedAt` timestamp
- `FavouriteCard` stored in Hive CE box `'favourites'` with `typeId: 1`; card ID as box key
- `FavouritesNotifier` (`keepAlive: true`) — write-through pattern (no stream needed)
- Save action: swipe up OR tap bookmark button; icon state is local UI state (not async)
- Favourites grid: 3-column `SliverGrid`, `artCrop` image URLs, ~2px gaps
- Filtering within favourites: bottom sheet with colour/type/rarity chips; filter applied client-side to `_box.values`

**Plans:**
1. Implement `FavouriteCard` domain model + Hive adapter (typeId: 1); add box to `main.dart` initialization
2. Implement `FavouritesNotifier` with `add` / `remove` / `isFavourite` methods
3. Add swipe-up gesture and bookmark button to `CardSwipeScreen` → wires to `FavouritesNotifier`
4. Implement `FavouritesScreen` — 3-column grid, empty state, filter bottom sheet
5. Implement `FavouriteSwipeScreen` — full image swipe view, delete button

**UAT:**
- [ ] Swiping up (or tapping bookmark) saves card; bookmark icon fills immediately
- [ ] Card appears in Favourites grid after saving
- [ ] Saved cards persist after app restart
- [ ] Tapping grid card opens swipe view starting at that card
- [ ] Delete button in swipe view removes card; grid updates
- [ ] Empty state shown when no favourites saved
- [ ] Filter within favourites narrows grid correctly
- [ ] `flutter analyze --fatal-infos` passes

---

## Phase 4: Card Detail View

**Goal:** Implement `CardDetailScreen` showing full card metadata — artwork, rules text, set info, prices, format legalities, and double-faced card flip support.

**Covers:** CARD-01 through CARD-05

**Depends on:** Phase 1 (navigation from swipe screen)

**Key decisions from research:**
- Double-faced card flip: `MagicCard` model already populates `cardFaces`; a flip FAB/button toggles between `card_faces[0]` and `card_faces[1]` image URLs
- Price display: `USD`, `USD Foil`, `EUR` fields — show "N/A" for null; no async fetch needed (prices in `MagicCard` JSON from Scryfall)
- Legalities: derive `MagicCard.legalities` map; show Standard / Modern / Legacy / Commander rows
- Flavour text: hidden entirely when null (do not show empty space)
- Navigation: `context.go(AppRoutes.cardDetail, extra: card)` — card passed as `extra`, not by ID

**Plans:**
1. Implement `CardDetailScreen` layout — artwork, gradient overlay, metadata sections
2. Add price section — USD / EUR with "N/A" fallback; add legalities table
3. Add double-faced card flip button (only shown when `cardFaces` is non-null)
4. Wire navigation: "tap card" action from `CardSwipeScreen` and `FavouriteSwipeScreen`

**UAT:**
- [ ] Tapping card in swipe view navigates to detail screen
- [ ] Name, type line, oracle text, set name, collector number, release date all visible
- [ ] USD and EUR prices shown; "N/A" for null prices
- [ ] Flavour text shown when present; hidden when absent (no empty gap)
- [ ] Standard / Modern / Legacy / Commander legality rows visible
- [ ] Flip button appears for double-faced cards; tapping switches to back face artwork
- [ ] `flutter analyze --fatal-infos` passes

---

## Phase 5: Tests

**Goal:** Achieve 80%+ test coverage on all business logic, widget tests for all screens in all states (loading / success / error / empty), and a key integration test covering the core user flow.

**Covers:** TEST-01 through TEST-06, QA-01 through QA-03

**Depends on:** Phases 1–4 (all features implemented)

**Key decisions from research:**
- Widget tests always override `cardRepositoryProvider` with `FakeCardRepository` — never make real HTTP calls
- Hive CE in tests: `Hive.init(tempDir.path)` (NOT `Hive.initFlutter()`); `tearDown` calls `Hive.close()`
- `ProviderContainer.test()` for unit tests (auto-disposes)
- Test all three `AsyncValue` states explicitly in `CardSwipeScreen` widget tests
- GoRouter-dependent screens: wrap in minimal `MaterialApp.router` with a test router
- Fixtures in `test/fixtures/`: `fake_card.dart`, `fake_double_faced_card.dart`, `fake_preset.dart`

**Plans:**
1. Create test fixtures; write unit tests for `ScryfallQueryBuilder` and `MagicCard.fromJson()`
2. Write unit tests for `RandomCardNotifier`, `FilterPresetsNotifier`, `FavouritesNotifier`
3. Write widget tests for `CardSwipeScreen` (loading / success / all 3 error states)
4. Write widget tests for `FilterSettingsScreen` and `FavouritesScreen`
5. Write integration test: swipe → new card → save → favourites grid → delete

**UAT:**
- [ ] `flutter test` passes with zero failures
- [ ] `flutter test --coverage` shows 80%+ coverage on `lib/features/` + `lib/shared/` logic classes
- [ ] All edge cases covered: double-faced card, null price, null flavour text, empty filter, 404/422/network errors

---

## Research Findings Applied

Key decisions from research that influenced this roadmap:

| Finding | Decision |
|---------|----------|
| `flutter_card_swiper` vs `GestureDetector` | GestureDetector for Phase 1 (sufficient for RM-13 AC); flutter_card_swiper deferred to v2 for drag animations |
| `shimmer` vs `skeletonizer` | `skeletonizer ^1.x` — reuses real widget tree, actively maintained, dark mode built-in |
| Filter → notifier wiring | `ref.watch(activeFilterQueryProvider)` in `RandomCardNotifier.build()` — reactive, no manual invalidation |
| Hive CE box lifecycle | Open all boxes in `main()` before `runApp()`, never close during session |
| `FavouriteCard` vs persisting `MagicCard` | `FavouriteCard` projection only — keeps adapter small, avoids versioning complex model |
| `ref.invalidateSelf()` vs manual state | Manual `state = AsyncLoading()` for swipe — immediate feedback, no stale card flash |
| `cached_network_image` maintenance | Keep `^3.4.1` for now; document `cached_network_image_ce` as migration path if issues arise |

---
*Roadmap created: 2026-04-10*
*Last updated: 2026-04-10 after initial creation*
