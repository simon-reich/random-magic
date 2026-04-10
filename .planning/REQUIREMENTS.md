# Requirements: Random Magic

**Defined:** 2026-04-10
**Core Value:** Tactile, swipeable MTG card discovery — always one swipe away from a new random card

## Existing Baseline (pre-GSD)

Infrastructure already shipped and working:

- ✓ Flutter project with feature-first Clean Architecture
- ✓ Dio HTTP client + ScryfallApiClient + `Result<T>` error handling
- ✓ `MagicCard` domain model with double-faced card support
- ✓ `CardRepository` + `RandomCardNotifier` (Riverpod `AsyncNotifier`)
- ✓ GoRouter navigation with bottom-tab shell and named routes
- ✓ Dark `AppTheme` with `AppColors` / `AppSpacing` constants
- ✓ GitHub Actions CI (analyze → test → build-apk)

---

## v1 Requirements

### Discovery (Swipe Screen)

- [ ] **DISC-01**: Swiping left or right on the card loads the next random card
- [ ] **DISC-02**: Card artwork is displayed full-screen using `CachedNetworkImage`
- [ ] **DISC-03**: Card name, mana cost, type line, and rarity are shown in an overlay at the bottom of the card
- [ ] **DISC-04**: A shimmer/skeleton loading state is shown while the image and data load
- [ ] **DISC-05**: A "No cards found" empty state is shown when Scryfall returns 404 (no matches for current filters), with an "Adjust Filters" button
- [ ] **DISC-06**: An "Invalid filter settings" error state is shown for Scryfall 422 responses, with a link to filter settings
- [ ] **DISC-07**: A "Could not reach Scryfall" network error state is shown for timeouts/connectivity failures, with a Retry button
- [ ] **DISC-08**: The screen auto-fetches a card on first load without user interaction
- [ ] **DISC-09**: All three error states are visually distinct from each other and from the loading state
- [ ] **DISC-10**: An active filter summary bar shows currently active filter chips above the card; tapping a chip removes that filter

### Filters

- [ ] **FILT-01**: User can configure a filter by card colour (W/U/B/R/G/C/M), multi-select
- [ ] **FILT-02**: User can configure a filter by card type (Creature, Instant, Sorcery, Enchantment, Artifact, Land, Planeswalker, Battle), multi-select
- [ ] **FILT-03**: User can configure a filter by rarity (Common, Uncommon, Rare, Mythic), multi-select
- [ ] **FILT-04**: User can configure a "Released After" date and a "Released Before" date
- [ ] **FILT-05**: Applying filters immediately changes what random cards are returned (via `ActiveFilterQuery` → `RandomCardNotifier`)
- [ ] **FILT-06**: User can save the current filter settings as a named preset
- [ ] **FILT-07**: User can select and apply a previously saved preset
- [ ] **FILT-08**: User can delete a saved preset
- [ ] **FILT-09**: Saving a preset with a name that already exists is blocked with inline validation (no duplicate names)
- [ ] **FILT-10**: An empty filter (no selections) produces an unrestricted random card query

### Favourites

- [ ] **FAV-01**: User can save the current card to Favourites (swipe up or via a button)
- [ ] **FAV-02**: The Favourites screen shows a 3-column grid of saved cards using `artCrop` images
- [ ] **FAV-03**: Tapping a card in the grid opens a swipe-through view (`FavouriteSwipeScreen`) starting at that card
- [ ] **FAV-04**: User can remove a card from Favourites via a delete button in the swipe view
- [ ] **FAV-05**: Favourites are persisted locally via Hive CE and survive app restarts
- [ ] **FAV-06**: An empty state is shown in the grid when no cards are saved
- [ ] **FAV-07**: User can filter the Favourites grid by colour, type, and rarity (via a bottom sheet)

### Card Detail

- [ ] **CARD-01**: Tapping a card in any swipe view opens a full-screen card detail view
- [ ] **CARD-02**: Card detail shows: full artwork, set name, collector number, release date, mana cost, type line, oracle text, flavour text (hidden if absent)
- [ ] **CARD-03**: Card detail shows current price (USD non-foil, USD foil, EUR); shows "N/A" for any null price field
- [ ] **CARD-04**: Card detail shows format legalities (Standard, Modern, Legacy, Commander at minimum)
- [ ] **CARD-05**: Double-faced cards show the front face by default; a flip button reveals the back face

### Quality & Error Handling

- [ ] **QA-01**: `flutter analyze --fatal-infos` passes with zero warnings
- [ ] **QA-02**: All async operations have loading, success, and error states handled in the UI
- [ ] **QA-03**: No hardcoded colours or magic numbers — all from `AppColors` / `AppSpacing`
- [ ] **QA-04**: Null card image URLs are guarded before passing to `CachedNetworkImage`
- [ ] **QA-05**: HTTP 429 (rate limited) is mapped to a typed `RateLimitedFailure` and shown to the user with a meaningful message
- [ ] **QA-06**: `legalities` map parsing is defensive (`.toString()` conversion, not `.cast<String, String>()`)

### Tests

- [ ] **TEST-01**: Unit tests for `ScryfallQueryBuilder.fromPreset()` covering all filter combinations
- [ ] **TEST-02**: Unit tests for `MagicCard.fromJson()` covering normal cards, double-faced cards, null prices, null oracle text
- [ ] **TEST-03**: Widget tests for `CardSwipeScreen` covering loading, success, and all three error states
- [ ] **TEST-04**: Widget tests for `FilterSettingsScreen` and `FavouritesScreen` (loading, success, empty)
- [ ] **TEST-05**: Unit tests for `FavouritesNotifier` and `FilterPresetsNotifier` with Hive CE in temp directory
- [ ] **TEST-06**: Integration test covering: swipe → new card loads → save to favourites → card appears in grid

---

## v2 Requirements

### Discovery Polish

- **DISC-V2-01**: Tinder-style drag animation — card rotates proportionally to drag distance; directional overlays (SAVE / PASS) fade in during drag
- **DISC-V2-02**: Card stack depth — 2–3 cards visible behind the active card at 0.95 / 0.90 scale
- **DISC-V2-03**: Pre-fetch buffer — next card fetched while current card is displayed to eliminate loading gap between swipes
- **DISC-V2-04**: Mana cost rendered as symbol icons (not raw `{2}{R}{R}` text) using the `mtg` package

### Filters

- **FILT-V2-01**: Inline warning in filter settings when selected combination is likely to return very few cards

### Testing

- **TEST-V2-01**: Favourites performance test with 500+ cards in grid

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| Backend server / API proxy | Scryfall is open, no auth required; proxy = unnecessary infrastructure (ADR-005) |
| User accounts / cloud sync | No backend; all data is local — out of scope for v1 |
| Deck-building features | Explicitly deferred from v1 (Confluence open questions) |
| Light mode / theme switcher | Dark mode only for v1 |
| Offline card image pre-cache | `cached_network_image` handles in-memory caching; pre-fetching not scoped |
| Web / desktop targets | iOS and Android only |
| Card trading / marketplace | Not relevant to discovery app scope |

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DISC-01 | Phase 1 | Pending |
| DISC-02 | Phase 1 | Pending |
| DISC-03 | Phase 1 | Pending |
| DISC-04 | Phase 1 | Pending |
| DISC-05 | Phase 1 | Pending |
| DISC-06 | Phase 1 | Pending |
| DISC-07 | Phase 1 | Pending |
| DISC-08 | Phase 1 | Pending |
| DISC-09 | Phase 1 | Pending |
| DISC-10 | Phase 2 | Pending |
| FILT-01 | Phase 2 | Pending |
| FILT-02 | Phase 2 | Pending |
| FILT-03 | Phase 2 | Pending |
| FILT-04 | Phase 2 | Pending |
| FILT-05 | Phase 2 | Pending |
| FILT-06 | Phase 2 | Pending |
| FILT-07 | Phase 2 | Pending |
| FILT-08 | Phase 2 | Pending |
| FILT-09 | Phase 2 | Pending |
| FILT-10 | Phase 2 | Pending |
| FAV-01 | Phase 3 | Pending |
| FAV-02 | Phase 3 | Pending |
| FAV-03 | Phase 3 | Pending |
| FAV-04 | Phase 3 | Pending |
| FAV-05 | Phase 3 | Pending |
| FAV-06 | Phase 3 | Pending |
| FAV-07 | Phase 3 | Pending |
| CARD-01 | Phase 4 | Pending |
| CARD-02 | Phase 4 | Pending |
| CARD-03 | Phase 4 | Pending |
| CARD-04 | Phase 4 | Pending |
| CARD-05 | Phase 4 | Pending |
| QA-01 | All Phases | Pending |
| QA-02 | All Phases | Pending |
| QA-03 | All Phases | Pending |
| QA-04 | Phase 1 | Pending |
| QA-05 | Phase 1 | Pending |
| QA-06 | Phase 1 | Pending |
| TEST-01 | Phase 5 | Pending |
| TEST-02 | Phase 5 | Pending |
| TEST-03 | Phase 5 | Pending |
| TEST-04 | Phase 5 | Pending |
| TEST-05 | Phase 5 | Pending |
| TEST-06 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 38 total
- Mapped to phases: 38
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-10*
*Last updated: 2026-04-10 after initial definition (brownfield — infrastructure baseline excluded)*
