# Phase 3: Favourites — Context

**Gathered:** 2026-04-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement the full Favourites feature: save cards from the swipe screen (swipe-up or button),
browse saved cards in a 3-column grid, swipe through individual saved cards, filter within
favourites by colour/type/rarity, and delete cards (individually with undo, or in batch via
multi-select).

Requirements: FAV-01 through FAV-07.

</domain>

<decisions>
## Implementation Decisions

### Save Action (FAV-01)

- **D-01:** Bookmark button sits as an **overlay on the card** (bottom-right corner, `Positioned`
  inside the `Stack` in `_CardFaceWidget`). Icon: `Icons.favorite_border` (♡) when not saved.
- **D-02:** **Swipe-up also saves** — both mechanisms active. `flutter_card_swiper` top-direction
  triggers the same save action as the button tap.
- **D-03:** On save, show a brief **Snackbar** ("Saved to Favourites") for discoverability
  feedback. No modal, no blocking UI.

### Already-Saved Indicator

- **D-04:** When the currently displayed random card is already in Favourites, the icon shows
  **filled** (`Icons.favorite`, ♥). Tapping the filled icon does nothing (no toggle, no remove).
  This requires `FavouritesNotifier.isFavourite(cardId)` watched per displayed card.

### Favourites Grid (FAV-02)

- **D-05:** 3-column `SliverGrid` with `artCrop` image URLs, ~2px gaps between cells.
  (`GridView.builder` or `SliverGrid` inside `CustomScrollView`.)
- **D-06:** **Long-press on any grid card** enters multi-select mode. Selected cards show a
  checkmark overlay. A top app bar appears with a delete button and a "X selected" count.
- **D-07:** Multi-select mode is exited via **Back-Button or second long-press** (no timeout).
  Exiting without deleting deselects all and returns to normal grid.

### Delete (FAV-04)

- **D-08:** Delete in `FavouriteSwipeScreen` is **immediate** — card removed from Hive on tap.
  A **Snackbar with Undo** (~3 seconds) allows reverting the deletion.
- **D-09:** **Batch delete** from multi-select grid mode also uses the same immediate +
  Undo Snackbar pattern. Single undo restores ALL cards deleted in that batch.

### Favourites Filter (FAV-07)

- **D-10:** Filter state is **in-memory only** — resets when the user leaves the Favourites tab.
  No Hive persistence for the filter. Implemented as a local Riverpod provider scoped to the
  Favourites feature (`autoDispose` is acceptable here).
- **D-11:** Filter is applied client-side against the full `FavouritesNotifier` list. Bottom
  sheet shows colour/type/rarity chips (same chip style as Phase 2 FilterSettingsScreen).

### Data Model

- **D-12:** `FavouriteCard` is a **projection** — persist only fields needed for display and
  filtering. Do not persist full `MagicCard`. Fields to include:
  - `id` (String) — Hive box key, uniqueness guard
  - `name` (String)
  - `typeLine` (String) — for type filtering
  - `rarity` (String) — for rarity filtering
  - `setCode` (String)
  - `artCropUrl` (String?) — for grid thumbnail
  - `normalImageUrl` (String?) — for swipe view
  - `manaCost` (String?) — for display in swipe view
  - `savedAt` (DateTime) — for sort order
  - `colors` (List\<String\>) — Scryfall color identity for colour filtering
- **D-13:** `FavouriteCardAdapter` uses **typeId: 1** (typeId: 0 is taken by `FilterPresetAdapter`).
  Box name: `'favourites'`.

### Claude's Discretion

- Navigation from grid to `FavouriteSwipeScreen`: passing card ID via route param is already
  set up in the router. The swipe screen should load ALL favourites and seek to the card matching
  the passed ID. Implementation detail left to planner/executor.
- Sort order in grid: newest-saved first (use `savedAt` descending). Claude's discretion.
- `FavouritesNotifier` marked `keepAlive: true` — consistent with Phase 1/2 notifier pattern.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` §Favourites — FAV-01 through FAV-07 (acceptance criteria)

### Phase 2 Patterns (reuse)
- `lib/features/filters/domain/filter_preset.dart` — Hive CE adapter pattern (typeId: 0);
  FavouriteCard adapter MUST use typeId: 1
- `lib/main.dart` — Hive box initialization pattern (register adapter + openBox before runApp)
- `lib/features/filters/presentation/filter_settings_screen.dart` — chip style to reuse for
  Favourites bottom sheet filter

### Existing Code Integration Points
- `lib/core/router/app_router.dart` — `/favourites` and `/favourites/:id` routes already exist;
  `FavouriteSwipeScreen` already receives `favouriteId` param
- `lib/features/card_discovery/presentation/card_swipe_screen.dart` — `_CardFaceWidget` Stack
  where bookmark overlay button is added (D-01)
- `lib/shared/models/magic_card.dart` — `CardImageUris.artCrop` (grid) and `.normal` (swipe view)
  fields; `MagicCard.id` used as Hive box key

### Architecture
- `CLAUDE.md` §Folder Structure — `features/favourites/data/`, `/domain/`, `/presentation/`
- `CLAUDE.md` §Coding Standards — `keepAlive: true` for notifiers, `Result<T>` pattern for repos

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `_CardFaceWidget` (`card_swipe_screen.dart`): existing `Stack` + `Positioned` overlay pattern
  (used by REVEAL label) — bookmark button slots in cleanly as another `Positioned`
- `CardSwiper` (`card_swipe_screen.dart`): already configured with `onSwipe` callback; add
  `CardSwiperDirection.top` handling for swipe-up save
- `CachedNetworkImage`: already a dependency — use for `artCrop` thumbnails in grid
- `AppColors`, `AppSpacing`: all spacing and colour constants available
- Phase 2 `FilterChip` + `Wrap` pattern: reuse for Favourites bottom sheet filter chips

### Established Patterns
- Riverpod `AsyncNotifier` with `keepAlive: true` — follow `RandomCardNotifier` pattern
- Hive CE write-through: read box → mutate → write back (no streams needed)
- `Result<T>` sealed class for repository method return types
- `ConsumerStatefulWidget` for screens with local + provider state

### Integration Points
- `CardSwipeScreen` build() → `_CardFaceWidget` Stack: add bookmark `Positioned` overlay
- `FavouritesScreen` placeholder (bare `Scaffold`) → replace with full grid implementation
- `FavouriteSwipeScreen` placeholder → replace with swipe-through implementation
- `main.dart` → add `FavouriteCardAdapter` registration + `openBox<FavouriteCard>('favourites')`

</code_context>

<specifics>
## Specific Ideas

- Bookmark button bottom-right on card, `Icons.favorite_border` / `Icons.favorite` toggle
  (filled when saved, no action on tap if already saved — D-04)
- Multi-select grid mode: checkmark overlay on selected cells + count app bar (D-06/D-07) —
  standard iOS/Android pattern, user specifically requested this
- Undo Snackbar for both single delete and batch delete (D-08/D-09) — single undo restores
  entire batch

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 03-favourites*
*Context gathered: 2026-04-16*
