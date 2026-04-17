# Phase 4: Card Detail View — Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement `CardDetailScreen` — full card metadata display including artwork, rules text,
set info, prices, format legalities, and double-faced card flip support. Navigation wired
from both `CardSwipeScreen` and `FavouriteSwipeScreen`.

Requirements: CARD-01 through CARD-05.

</domain>

<decisions>
## Implementation Decisions

### Navigation & Data Source

- **D-01:** Navigate to detail screen by passing `MagicCard` via GoRouter `extra`:
  `context.go('/card/${card.id}', extra: card)`. The router must be updated to cast
  `state.extra as MagicCard` and pass it directly to `CardDetailScreen`. No re-fetch from
  Scryfall — all needed data is already in the card object.
- **D-02:** Tap target is the **card image itself** — `GestureDetector` wrapping the card
  face widget (`_CardFaceWidget` Stack in `CardSwipeScreen`, equivalent widget in
  `FavouriteSwipeScreen`). Same pattern in both screens.

### Double-Faced Card Model

- **D-03:** Add `cardFaces: List<CardFace>?` to `MagicCard`. `CardFace` is a new value class
  in `lib/shared/models/magic_card.dart` with fields: `imageUris` (CardImageUris), `name`
  (String), `typeLine` (String), `oracleText` (String?), `manaCost` (String?). Null for
  normal single-faced cards; 2 items for DFCs. `MagicCard.fromJson()` must be updated to
  parse `card_faces` into this list.
- **D-04:** On flip (face toggle), the detail screen swaps: **image, name, type line, oracle
  text**. Mana cost shows front-face value (Scryfall convention — back faces often lack mana
  cost). Prices and format legalities remain fixed (they belong to the card, not the face).

### Detail Screen Layout

- **D-05:** Scrollable page using `CustomScrollView` + `SliverAppBar` with `expandedHeight`.
  Card artwork fills the expanded app bar header; it collapses to a standard app bar as the
  user scrolls. Metadata sections (oracle text, flavour text, set info, prices, legalities)
  are `SliverList` content below.
- **D-06:** Use the **`large` image format** (672×936px, `CardImageUris.large`) for the
  artwork in the detail screen — noticeably sharper than `normal` for a dedicated detail view.
  Fall back to `normal` if `large` is null.
- **D-07:** Section order (top to bottom): oracle text → flavour text (hidden if absent) →
  set name / collector number / release date → prices (USD / USD Foil / EUR) → format
  legalities. Claude's discretion on spacing and dividers.

### Legality Display

- **D-08:** Format legalities displayed as **colored badge rows** — format name on the left,
  colored status badge on the right. Badge colors: green = Legal, red = Banned, grey = Not
  Legal / Restricted. Formats shown: Standard, Modern, Legacy, Commander (minimum per
  CARD-04). Claude's discretion on whether to add more formats.

### Claude's Discretion

- Whether to use `SliverAppBar` or a simpler sticky-image + `SingleChildScrollView` layout
  (D-05 names SliverAppBar as the approach; if the planner finds it complex for v1, sticky
  image is acceptable)
- Exact spacing, padding, and section divider style (use `AppSpacing` constants throughout)
- Whether to add a `flipState` as local widget state or a lightweight `StateProvider`
- Additional format rows beyond the required four (Standard / Modern / Legacy / Commander)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` §Card Detail — CARD-01 through CARD-05 (acceptance criteria)

### Model (modify)
- `lib/shared/models/magic_card.dart` — add `cardFaces: List<CardFace>?` and `CardFace`
  value class; update `MagicCard.fromJson()` to parse `card_faces` array

### Router (modify)
- `lib/core/router/app_router.dart` — update `/card/:id` route to cast `state.extra as MagicCard`
  and pass to `CardDetailScreen` instead of `cardId`

### Screens (replace placeholder / add tap handlers)
- `lib/features/card_detail/presentation/card_detail_screen.dart` — placeholder to replace;
  currently accepts `cardId: String`, must be updated to accept `card: MagicCard`
- `lib/features/card_discovery/presentation/card_swipe_screen.dart` — `_CardFaceWidget` Stack
  where `GestureDetector` tap navigates to detail (D-02)
- `lib/features/favourites/presentation/favourite_swipe_screen.dart` — same tap-to-detail
  pattern as CardSwipeScreen (D-02)

### Shared assets (reference)
- `lib/shared/models/magic_card.dart` §CardImageUris — `large` field for detail artwork (D-06)
- `lib/shared/models/magic_card.dart` §CardPrices — `usd`, `usdFoil`, `eur` fields; null → "N/A"

### Architecture
- `CLAUDE.md` §Folder Structure — `features/card_detail/domain/` and `/presentation/`
- `CLAUDE.md` §Coding Standards — `keepAlive: true` for notifiers, no hardcoded values,
  `Result<T>` for repos

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CachedNetworkImage`: already a dependency — use for `large` image in detail screen
- `AppColors`, `AppSpacing`: all spacing/colour constants available; no hardcoded values
- `_CardFaceWidget` (`card_swipe_screen.dart`): existing `Stack` + `Positioned` pattern —
  wrap with `GestureDetector` for tap-to-detail navigation (D-02)
- Phase 2 `FilterChip` + colored chip style: reuse color approach for legality badges

### Established Patterns
- `ConsumerStatefulWidget` for screens needing local state (flip toggle is local state)
- `CachedNetworkImage` with null-URL guard before passing URL
- `AppColors` / `AppSpacing` for all visual values

### Integration Points
- `lib/core/router/app_router.dart` GoRoute `/card/:id` — update `builder` to read `extra`
- `CardSwipeScreen` and `FavouriteSwipeScreen` — add `GestureDetector` to card face widget
- `MagicCard.fromJson()` — extend to populate `cardFaces` from `card_faces` JSON array

### Notable conflict resolved
- ROADMAP says `extra: card` but the existing placeholder router passes `cardId: String`.
  Decision (D-01): move to `extra: MagicCard`. The placeholder `CardDetailScreen` must be
  updated to accept `card: MagicCard` instead of `cardId: String`.

</code_context>

<specifics>
## Specific Ideas

- Flip button only appears when `card.cardFaces != null` — hidden for normal single-faced cards
- On flip, swap image + name + typeLine + oracleText; keep prices and legalities fixed (D-04)
- `large` image with fallback to `normal` if `large` is null (D-06)
- Coloured legality badges: green / red / grey per status, consistent with dark app theme (D-08)
- Flavour text hidden entirely when null — no empty space, no placeholder (per CARD-02 and
  Phase 1 pattern)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 04-card-detail-view*
*Context gathered: 2026-04-17*
