# Phase 4: Card Detail View — Research

**Researched:** 2026-04-17
**Domain:** Flutter UI — detail screen, CustomScrollView/SliverAppBar, local state management, GoRouter extra, MagicCard model extension
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Navigate via `context.go('/card/${card.id}', extra: card)`. Router casts `state.extra as MagicCard`. No re-fetch.
- **D-02:** Tap target is the card image itself — `GestureDetector` wrapping `_CardFaceWidget` Stack in `CardSwipeScreen` and the equivalent widget in `FavouriteSwipeScreen`.
- **D-03:** Add `cardFaces: List<CardFace>?` to `MagicCard`. `CardFace` value class in `lib/shared/models/magic_card.dart` with fields: `imageUris` (CardImageUris), `name`, `typeLine`, `oracleText` (nullable), `manaCost` (nullable). Parse from `card_faces` JSON array. Null for single-faced cards.
- **D-04:** Flip swaps image, name, type line, oracle text. Mana cost stays front-face. Prices and legalities fixed to the card object.
- **D-05:** `CustomScrollView` + `SliverAppBar` with `expandedHeight`. Artwork fills expanded header; collapses to standard app bar on scroll. Metadata sections in `SliverList` below.
- **D-06:** Use `large` image format (672×936px) for detail screen. Fall back to `normal` if `large` is null.
- **D-07:** Section order: oracle text → flavour text (hidden if null) → set name / collector number / release date → prices (USD / USD Foil / EUR) → format legalities.
- **D-08:** Legality displayed as colored badge rows. Badge colors: green = Legal, red = Banned, grey = Not Legal / Restricted. Required formats: Standard, Modern, Legacy, Commander.

### Claude's Discretion

- Whether to use `SliverAppBar` or sticky-image + `SingleChildScrollView` (D-05 names SliverAppBar; sticky image acceptable if planner finds SliverAppBar complex)
- Exact spacing, padding, and section divider style (use `AppSpacing` constants throughout)
- Whether `flipState` is local widget state or a lightweight `StateProvider`
- Additional format rows beyond Standard / Modern / Legacy / Commander

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CARD-01 | Tapping a card in any swipe view opens a full-screen card detail view | D-01/D-02 locked; `GestureDetector` on `_CardFaceWidget` + router `extra` pattern documented |
| CARD-02 | Card detail shows: full artwork, set name, collector number, release date, mana cost, type line, oracle text, flavour text (hidden if absent) | D-05/D-06/D-07 locked; `CachedNetworkImage` with `large` URL + conditional flavour text render |
| CARD-03 | Card detail shows current price (USD non-foil, USD foil, EUR); shows "N/A" for any null price field | `CardPrices` model confirmed — all fields nullable; `?? 'N/A'` pattern |
| CARD-04 | Card detail shows format legalities (Standard, Modern, Legacy, Commander at minimum) | `legalities` Map<String,String> already on `MagicCard`; D-08 badge pattern locked |
| CARD-05 | Double-faced cards show front face by default; a flip button reveals the back face | D-03/D-04 locked; `cardFaces` field + local bool toggle; FAB pattern researched |
</phase_requirements>

---

## Summary

Phase 4 implements `CardDetailScreen` — the first purely presentational screen in this project that requires no Riverpod providers beyond receiving a `MagicCard` via GoRouter `extra`. All data is already in the card object from the Scryfall API response; no async fetch occurs in this screen.

The three non-trivial engineering decisions are: (1) extending `MagicCard` with a `CardFace` value class to expose per-face data to the flip toggle; (2) updating the router's `/card/:id` route to read from `state.extra` instead of the path parameter; (3) implementing `CustomScrollView` + `SliverAppBar` correctly so the expanded card artwork header collapses gracefully.

All existing patterns (`CachedNetworkImage`, `AppColors`, `AppSpacing`, `ConsumerStatefulWidget`) are already in the codebase and apply directly. The navigation tap pattern (`GestureDetector` wrapping the card face widget) follows the same structure used in Phase 3's `FavouriteSwipeScreen`.

**Primary recommendation:** Implement in four sequential plans: (1) model extension + router update, (2) `CardDetailScreen` scaffold + artwork section, (3) metadata sections + prices + legalities, (4) flip button + DFC logic + navigation wire-up in swipe screens.

---

## Standard Stack

### Core (all already in pubspec.yaml)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_riverpod | ^3.0.0 | State for flip toggle (local StateProvider option) | Already used throughout — `ConsumerStatefulWidget` for local state is the established pattern |
| go_router | ^17.2.0 | Navigation via `state.extra` | Already wired; only the `/card/:id` builder needs updating |
| cached_network_image | ^3.4.1 | `large` image in expanded SliverAppBar | Already used in `CardSwipeScreen` and `FavouriteSwipeScreen` |

No new packages required. [VERIFIED: pubspec.yaml in codebase]

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter_test (dev) | sdk | Widget tests for `CardDetailScreen` | Existing test infrastructure; `test/widgets/card_detail/` directory to create |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Local `bool _showBack` on `ConsumerStatefulWidget` | Lightweight `StateProvider` | Local state is simpler — flip state is view-only, not shared across widgets |
| `SliverAppBar` + `CustomScrollView` | `SingleChildScrollView` with sticky `Stack` | SliverAppBar is more idiomatic and collapses automatically; sticky Stack requires manual scroll listener |

**Installation:** No new packages required. All dependencies already resolved.

---

## Architecture Patterns

### Recommended Project Structure

Phase touches these existing files and creates one new directory:

```
lib/
├── shared/models/
│   └── magic_card.dart              # ADD: CardFace value class + cardFaces field on MagicCard
├── core/router/
│   └── app_router.dart              # UPDATE: /card/:id builder reads state.extra
├── features/card_detail/
│   └── presentation/
│       └── card_detail_screen.dart  # REPLACE placeholder with full implementation
├── features/card_discovery/
│   └── presentation/
│       └── card_swipe_screen.dart   # ADD: GestureDetector on _CardFaceWidget
└── features/favourites/
    └── presentation/
        └── favourite_swipe_screen.dart  # ADD: GestureDetector on _FavouriteCardFace

test/
└── widgets/
    └── card_detail/                 # CREATE: new directory
        └── card_detail_screen_test.dart
```

[VERIFIED: directory structure from codebase inspection]

### Pattern 1: GoRouter `extra` Passing

**What:** Pass a full `MagicCard` object as GoRouter `extra` — avoids re-fetching from Scryfall, no ID lookup needed.
**When to use:** When data is already in scope at the call site (swipe screen holds the current card).

```dart
// Source: existing app_router.dart pattern + D-01

// Caller (CardSwipeScreen / FavouriteSwipeScreen):
context.go('/card/${card.id}', extra: card);

// Router builder:
GoRoute(
  path: AppRoutes.cardDetail,
  builder: (context, state) {
    final card = state.extra as MagicCard;
    return CardDetailScreen(card: card);
  },
),
```

**Important:** GoRouter does not serialize `extra` — it is held in memory. If the user backgrounds the app and the OS kills it, the `extra` is lost. For this app (no deep links to card detail, always navigated from a swipe screen), this is acceptable. [ASSUMED — standard GoRouter behavior from training knowledge]

### Pattern 2: SliverAppBar with Expanded Artwork

**What:** `CustomScrollView` with a `SliverAppBar` that expands to show the card image and collapses to a standard app bar showing the card name.
**When to use:** Detail screens where a hero image should dominate the top and collapse as the user scrolls through content.

```dart
// Source: Flutter docs SliverAppBar pattern [ASSUMED — verified conceptually via codebase]
CustomScrollView(
  slivers: [
    SliverAppBar(
      expandedHeight: 420,    // Approx card height at screen width
      pinned: true,           // AppBar stays visible when collapsed
      flexibleSpace: FlexibleSpaceBar(
        title: Text(card.name),
        background: _CardArtwork(imageUrl: card.imageUris.large ?? card.imageUris.normal),
      ),
    ),
    SliverList(
      delegate: SliverChildListDelegate([
        _OracleTextSection(card: currentFace),
        if (card.flavorText != null) _FlavorTextSection(card: card),
        _SetInfoSection(card: card),
        _PricesSection(prices: card.prices),
        _LegalitiesSection(legalities: card.legalities),
      ]),
    ),
  ],
)
```

Key `SliverAppBar` properties:
- `pinned: true` — keeps the collapsed bar visible (back button accessible)
- `expandedHeight` — sets the full expansion size; approximately `MediaQuery.of(context).size.width * (88/63)` gives a card-ratio height, but a fixed value like 400–440px is simpler and more predictable
- `flexibleSpace: FlexibleSpaceBar` — handles the expand/collapse animation automatically

[ASSUMED — standard Flutter API; behavior confirmed from project's existing use of AppBar patterns]

### Pattern 3: Conditional Section Rendering (Flavour Text)

**What:** Render a widget only when its backing data is non-null. No empty space, no placeholder.
**When to use:** Flavour text, optional card fields.

```dart
// Established pattern from CONTEXT.md code_context section
if (card.flavorText != null)
  _FlavorTextSection(flavorText: card.flavorText!),
```

This is identical to the `if (filterState.releasedAfter != null)` pattern in `_ActiveFilterBar`. [VERIFIED: card_swipe_screen.dart line 429]

### Pattern 4: Legality Badge Row

**What:** A `Row` with a format name label on the left and a colored `Container` badge on the right.
**Badge colors:** derive from `card.legalities[formatKey]` string value.

```dart
// Source: D-08 decision; AppColors palette [VERIFIED: app_theme.dart]
Color _legalityColor(String? status) {
  return switch (status) {
    'legal'      => const Color(0xFF4CAF50), // green — add AppColors.legal if needed
    'banned'     => AppColors.error,          // red (0xFFCF6679)
    _            => AppColors.onSurfaceMuted, // grey for 'not_legal', 'restricted'
  };
}
```

Note: `AppColors` does not currently have a `legal` green. Options:
1. Add `AppColors.legal` constant (cleanest — follows CLAUDE.md no-hardcoded-colours rule)
2. Inline via `Color(0xFF4CAF50)` with a comment (violates CLAUDE.md standard)

**Recommendation: add `AppColors.legal = Color(0xFF4CAF50)` in `app_theme.dart` as part of Wave 0.** [VERIFIED: app_theme.dart does not contain a green color; CLAUDE.md §No magic numbers applies]

### Pattern 5: Double-Faced Card Flip (Local State)

**What:** A `bool _showBack` field on `ConsumerStatefulWidget` toggles which face's data is displayed. The flip button is a `FloatingActionButton` visible only when `card.cardFaces != null`.

```dart
// Source: D-03, D-04, D-05 decisions
class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    // Derive active-face display values
    final face = (_showBack && card.cardFaces != null)
        ? card.cardFaces![1]
        : null; // null = use top-level card fields
    final displayName       = face?.name       ?? card.name;
    final displayTypeLine   = face?.typeLine   ?? card.typeLine;
    final displayOracleText = face?.oracleText ?? card.oracleText;
    final displayImageUrl   = (_showBack && card.cardFaces != null)
        ? (card.cardFaces![1].imageUris.large ?? card.cardFaces![1].imageUris.normal ?? '')
        : (card.imageUris.large ?? card.imageUris.normal ?? '');
    // Mana cost always shows front face (D-04)
    final displayManaCost = card.manaCost ?? card.cardFaces?[0].manaCost;
    ...
  }
}
```

Flip FAB:
```dart
floatingActionButton: card.cardFaces != null
    ? FloatingActionButton(
        onPressed: () => setState(() => _showBack = !_showBack),
        tooltip: _showBack ? 'Show front face' : 'Show back face',
        child: const Icon(Icons.flip),
      )
    : null,
```

[ASSUMED — standard Flutter StatefulWidget pattern; D-04 decision locked]

### Pattern 6: MagicCard.cardFaces Model Extension

**What:** Add `CardFace` value class and `cardFaces: List<CardFace>?` field to `MagicCard`.

```dart
// Source: D-03 decision + existing MagicCard.fromJson() in magic_card.dart

/// A single face of a double-faced Magic card.
class CardFace {
  const CardFace({
    required this.imageUris,
    required this.name,
    required this.typeLine,
    this.oracleText,
    this.manaCost,
  });

  final CardImageUris imageUris;
  final String name;
  final String typeLine;
  final String? oracleText;
  final String? manaCost;

  factory CardFace.fromJson(Map<String, dynamic> json) {
    return CardFace(
      imageUris: CardImageUris.fromJson(
        (json['image_uris'] as Map<String, dynamic>?) ?? {},
      ),
      name: json['name'] as String,
      typeLine: json['type_line'] as String,
      oracleText: json['oracle_text'] as String?,
      manaCost: json['mana_cost'] as String?,
    );
  }
}
```

`MagicCard.fromJson()` update — add to existing factory:
```dart
// After the rawImageUris extraction:
final rawFaces = json['card_faces'] as List<dynamic>?;
final cardFaces = rawFaces != null && rawFaces.length >= 2
    ? rawFaces
        .cast<Map<String, dynamic>>()
        .map(CardFace.fromJson)
        .toList()
    : null;
```

And pass `cardFaces: cardFaces` to the `MagicCard(...)` constructor call.

**Critical:** The `MagicCard` placeholder constructor used in `_buildLoadingCard()` (card_swipe_screen.dart line 122) must be updated to include `cardFaces: null`. Since it's a `const` constructor call, ensure `cardFaces` defaults to `null` (nullable optional param). [VERIFIED: magic_card.dart — current constructor uses `this.flavorText` and `this.prices` as optional nullable params; same pattern applies]

### Anti-Patterns to Avoid

- **Calling `state.extra as MagicCard` without a null guard:** If the `/card/:id` route is ever accessed without `extra` (e.g., direct deep link), this crashes. Guard with `state.extra is MagicCard ? state.extra as MagicCard : null` and show an error widget. [ASSUMED — GoRouter behavior]
- **Hardcoded green color for legality badge:** Must be `AppColors.legal` (to be added), not `Color(0xFF...)` inline.
- **`setState` inside `ConsumerWidget`:** Use `ConsumerStatefulWidget` for the flip toggle. [VERIFIED: CLAUDE.md rule — Avoid `setState` — use Riverpod `ConsumerWidget` or `ConsumerStatefulWidget`]
- **Passing `imageUrl: ''` to `CachedNetworkImage`:** An empty string URL causes a load error; guard before passing. [VERIFIED: existing pattern in `card_swipe_screen.dart` line 283]
- **Using `card_faces` JSON array for `imageUris` in `fromJson` while also populating `cardFaces`:** The existing `_firstFaceImageUris` helper already reads from `card_faces[0]` for the top-level `imageUris` field. The new `cardFaces` parsing must read the same array separately — do not remove `_firstFaceImageUris`. [VERIFIED: magic_card.dart lines 103-108]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Collapsing image header | Manual scroll listener + Transform | `SliverAppBar` + `FlexibleSpaceBar` | Flutter's sliver machinery handles pinning, collapse animation, and status bar overlay correctly |
| Network image with loading/error states | Custom FutureBuilder + Image.network | `CachedNetworkImage` (already in pubspec) | Disk cache, placeholder, error widget all built-in |
| Legality color derivation | Complex if-else chain | Dart `switch` expression on string values | Clean, exhaustive, readable |
| Flip animation | Custom AnimationController | `setState()` + `AnimatedSwitcher` (optional) | Simple bool toggle is sufficient; no animation required per decisions |

**Key insight:** This screen has no async operations and no Riverpod providers — all data arrives via GoRouter `extra`. The complexity is entirely in layout composition and the `MagicCard` model extension.

---

## Common Pitfalls

### Pitfall 1: SliverAppBar `expandedHeight` Clipping

**What goes wrong:** The `FlexibleSpaceBar.background` image is cropped or the collapsed title overlaps the artwork.
**Why it happens:** `expandedHeight` is set without accounting for the system status bar height, or `title` text appears over the expanded image.
**How to avoid:** Use `FlexibleSpaceBar(titlePadding: ...)` or set `title` to null in expanded state (Flutter handles the collapse automatically). Set `expandedHeight` to a value derived from the card aspect ratio: `MediaQuery.sizeOf(context).width * (88/63)` gives a perfect MTG card height, but requires `context` in the sliver — safer to use a fixed value like `440.0`. [ASSUMED]
**Warning signs:** Image is cropped on wide devices or in landscape mode.

### Pitfall 2: GoRouter `extra` Lost After App Restart

**What goes wrong:** The `/card/:id` route is open, user backgrounds the app, OS kills it, and on restore `state.extra` is null.
**Why it happens:** GoRouter `extra` is in-memory only — not serialized to the route state. [ASSUMED]
**How to avoid:** Guard with `if (state.extra is! MagicCard)` and redirect or show an error. For this app, the simplest fix is to pop back to the discovery screen if `extra` is null.
**Warning signs:** Null cast exception on `state.extra as MagicCard` in release builds.

### Pitfall 3: Double-Faced Card `_firstFaceImageUris` Interaction

**What goes wrong:** Adding `cardFaces` parsing breaks the existing top-level `imageUris` extraction for DFCs.
**Why it happens:** Both the existing code and the new code read from `card_faces` array. If the new code consumes/modifies the list before `_firstFaceImageUris` runs, the fallback breaks.
**How to avoid:** Keep `_firstFaceImageUris` as-is. Parse `cardFaces` after `rawImageUris` is already resolved. The JSON map is not consumed — both paths read from it independently. [VERIFIED: `fromJson` reads `json['card_faces']` in `_firstFaceImageUris` and the new code reads the same key — both are safe reads from the same immutable map]

### Pitfall 4: `MagicCard` Const Constructor Breakage

**What goes wrong:** Adding `cardFaces` to `MagicCard` breaks the `const MagicCard(...)` placeholder in `_buildLoadingCard()` in `card_swipe_screen.dart`.
**Why it happens:** If `cardFaces` is added as a required parameter, or if the default value is non-const.
**How to avoid:** Add `cardFaces` as an optional nullable parameter: `this.cardFaces,`. Its absence defaults to `null` — the `const` constructor call in `_buildLoadingCard` (line 122) remains valid. [VERIFIED: magic_card.dart line 6-23 — constructor uses this pattern for `flavorText` and `prices`]

### Pitfall 5: Legality Map Key Casing

**What goes wrong:** Looking up `card.legalities['Standard']` returns null when Scryfall uses `'standard'` (lowercase).
**Why it happens:** Scryfall uses snake_case lowercase for all legality keys. [ASSUMED — consistent with existing `legalities` parsing in `magic_card.dart` line 93 which does no key transformation]
**How to avoid:** Use lowercase keys: `card.legalities['standard']`, `card.legalities['modern']`, `card.legalities['legacy']`, `card.legalities['commander']`.
**Warning signs:** All legality badges show grey "N/A" for every card.

### Pitfall 6: `FavouriteSwipeScreen` Uses `FavouriteCard`, Not `MagicCard`

**What goes wrong:** Adding tap-to-detail from `FavouriteSwipeScreen` requires a `MagicCard` object, but `_FavouriteCardFace` only holds a `FavouriteCard`.
**Why it happens:** `FavouriteCard` is a reduced model — it does not have `legalities`, `prices`, `oracleText`, etc. needed for `CardDetailScreen`. [VERIFIED: `favourite_card.dart` — confirmed by `FavouriteSwipeScreen` import and `_FavouriteCardFace` class]
**How to avoid:** Two options:
  1. Tap from `FavouriteSwipeScreen` navigates to a separate "favourite detail" screen with the limited data available (out of scope — CONTEXT.md D-02 says same pattern as CardSwipeScreen).
  2. `FavouriteCard` stores enough data to construct a partial `MagicCard`, OR the tap fetches from Scryfall by ID before navigating (D-01 locks out re-fetching).

**Resolution per decisions:** D-01 says "no re-fetch", D-02 says "same GestureDetector pattern in both screens." This means `FavouriteSwipeScreen` must pass a `MagicCard` — which it cannot, since it only has `FavouriteCard`. **The planner must resolve this.** Options:
  - Option A: `FavouriteCard` stores a serialised `MagicCard` JSON blob or `MagicCard` reference — out of scope for Phase 4 (would require Phase 3 data model changes).
  - Option B: The tap from `FavouriteSwipeScreen` is deferred / shows a "Card Detail not available" message from favourites view. Not per UAT.
  - Option C: Construct a partial `MagicCard` from `FavouriteCard` fields, accept that prices/legalities/oracle text will be missing or shown as placeholders. Then navigate with that partial object.
  - Option D: Fetch from Scryfall by `card.id` before navigating (contradicts D-01, but D-01 may be referring only to the detail screen itself not re-fetching).

**Most likely intended resolution:** D-01 says the detail screen doesn't re-fetch — the tap handler in the swipe screen may legitimately call `ScryfallApiClient.fetchById(card.id)` before navigating, storing the result in `extra`. This is consistent with D-01's intent (the screen receives a fully populated card). Flag this for planner decision. [ASSUMED]

---

## Code Examples

### GestureDetector Wrapping Card Face (CARD-01)

```dart
// Source: D-02 decision; pattern from existing _CardFaceWidget in card_swipe_screen.dart
// Wrap the existing Stack in GestureDetector — no layout changes needed
GestureDetector(
  onTap: () => context.go('/card/${card.id}', extra: card),
  child: _CardFaceWidget(card: card, swipePercentX: percentThresholdX / 100.0),
)
```

### Price Row with N/A Fallback (CARD-03)

```dart
// Source: D-07; CardPrices model in magic_card.dart (all fields nullable)
_PriceRow(label: 'USD', value: card.prices?.usd ?? 'N/A'),
_PriceRow(label: 'USD Foil', value: card.prices?.usdFoil ?? 'N/A'),
_PriceRow(label: 'EUR', value: card.prices?.eur ?? 'N/A'),
```

### Legality Badge Row (CARD-04)

```dart
// Source: D-08 decision; AppColors palette in app_theme.dart
_LegalityRow(format: 'Standard',  status: card.legalities['standard']),
_LegalityRow(format: 'Modern',    status: card.legalities['modern']),
_LegalityRow(format: 'Legacy',    status: card.legalities['legacy']),
_LegalityRow(format: 'Commander', status: card.legalities['commander']),

// Badge widget:
class _LegalityRow extends StatelessWidget {
  const _LegalityRow({required this.format, required this.status});
  final String format;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'legal'      => AppColors.legal,         // new constant to add
      'banned'     => AppColors.error,
      'restricted' => AppColors.primaryVariant,
      _            => AppColors.onSurfaceMuted, // 'not_legal', null
    };
    final label = switch (status) {
      'legal'      => 'Legal',
      'banned'     => 'Banned',
      'restricted' => 'Restricted',
      _            => 'Not Legal',
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(format, style: Theme.of(context).textTheme.bodyMedium),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(AppSpacing.xs),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `state.pathParameters['id']` → fetch card by ID | `state.extra as MagicCard` → use existing object | Phase 4 decision D-01 | No network call, instant detail screen load |
| Placeholder `CardDetailScreen(cardId: String)` | Full `CardDetailScreen(card: MagicCard)` | Phase 4 | Replaces placeholder entirely |

**Deprecated/outdated:**
- `CardDetailScreen(cardId: String)`: the placeholder constructor — replaced by `CardDetailScreen(card: MagicCard)`.
- `GoRoute` builder for `/card/:id` reading `state.pathParameters['id']`: replaced by `state.extra as MagicCard` cast.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | GoRouter `extra` is in-memory only and lost after OS kill | Pitfall 2 | Low — this app does not support deep links to card detail, so a null guard suffices |
| A2 | `SliverAppBar` `expandedHeight` fixed value of ~440px is safe for all screen sizes | Pattern 2 | Low — can use `MediaQuery.sizeOf` for adaptive height if needed |
| A3 | D-01 "no re-fetch" refers to the detail screen itself, not to the tap handler in `FavouriteSwipeScreen` | Pitfall 6 | HIGH — if wrong, `FavouriteSwipeScreen` cannot provide a `MagicCard` to navigate with; planner must resolve |
| A4 | Scryfall legality map keys are always lowercase (e.g. `'standard'`) | Pitfall 5 | Medium — existing `legalities` parsing in `fromJson` does not lowercase keys; a wrong key lookup silently returns null |
| A5 | `FlexibleSpaceBar.title` appears in both expanded and collapsed state by default | Pattern 2 | Low — can hide title in expanded state with `collapseMode` or opacity trick |

---

## Open Questions

1. **FavouriteSwipeScreen tap-to-detail data source (HIGH PRIORITY)**
   - What we know: `FavouriteSwipeScreen` holds `FavouriteCard` objects, which do not contain `legalities`, `prices`, `oracleText`, or `releasedAt` — all required by `CardDetailScreen`.
   - What's unclear: D-01 says "no re-fetch" but doesn't address the favourites tap path. D-02 says "same pattern in both screens."
   - Recommendation: Planner should decide between (A) fetching by ID in the tap handler before navigating, or (B) constructing a partial `MagicCard` with nil prices/legalities and showing "N/A" / empty for missing fields. Option A gives correct data; Option B is simpler but shows incomplete detail for favourites. If the planner chooses Option A, the plan must include `ScryfallApiClient.getCard(id)` method (check if it exists already).

2. **`AppColors.legal` addition**
   - What we know: `AppColors` has no green. Legality badge needs green for "Legal" status.
   - What's unclear: Whether to add `AppColors.legal` or use a local constant in `card_detail_screen.dart`.
   - Recommendation: Add `AppColors.legal = Color(0xFF4CAF50)` in `app_theme.dart` per CLAUDE.md no-hardcoded-colours rule.

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies — all packages already in pubspec.yaml; no new CLI tools or services required).

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (sdk bundled) |
| Config file | analysis_options.yaml (lints only); no separate test config |
| Quick run command | `flutter test test/widgets/card_detail/ --no-pub` |
| Full suite command | `flutter test --no-pub` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CARD-01 | Tapping card image navigates to detail screen | Widget | `flutter test test/widgets/card_discovery/ --no-pub` | ❌ Wave 0 |
| CARD-02 | Detail screen renders name, type line, oracle text, set info, hidden flavour text | Widget | `flutter test test/widgets/card_detail/ --no-pub` | ❌ Wave 0 |
| CARD-03 | Prices shown with N/A fallback | Widget | `flutter test test/widgets/card_detail/ --no-pub` | ❌ Wave 0 |
| CARD-04 | Legality rows visible for Standard/Modern/Legacy/Commander | Widget | `flutter test test/widgets/card_detail/ --no-pub` | ❌ Wave 0 |
| CARD-05 | Flip button hidden for single-faced; visible + functional for DFC | Widget | `flutter test test/widgets/card_detail/ --no-pub` | ❌ Wave 0 |
| TEST-02 | `MagicCard.fromJson()` covers DFC card_faces parsing | Unit | `flutter test test/unit/card_discovery/ --no-pub` | ❌ Wave 0 (extend existing test) |

### Sampling Rate

- **Per task commit:** `flutter test test/widgets/card_detail/ --no-pub && flutter analyze --fatal-infos`
- **Per wave merge:** `flutter test --no-pub && flutter analyze --fatal-infos`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/widgets/card_detail/card_detail_screen_test.dart` — covers CARD-02, CARD-03, CARD-04, CARD-05
- [ ] `test/fixtures/fake_magic_card.dart` — shared `fakeMagicCard()` helper with DFC variant (required by widget tests)
- [ ] Extend `test/unit/card_discovery/magic_card_colors_test.dart` to cover `cardFaces` parsing (TEST-02 / CARD-05)
- [ ] CARD-01 tap-to-detail: widget test on `card_swipe_screen` (can be a skip-stub, actual implementation in Phase 5)

---

## Security Domain

No authentication, no user input validation, no network calls from this screen. Scryfall data is already fetched and trusted before reaching this screen. Security domain: NOT APPLICABLE for this phase.

---

## Project Constraints (from CLAUDE.md)

| Directive | Impact on Phase 4 |
|-----------|-------------------|
| Every public class/method/provider must have `///` doc comment | `CardDetailScreen`, `CardFace`, all private section widgets need doc comments |
| No hardcoded colors — use `AppColors` | Must add `AppColors.legal` for green legality badge |
| No hardcoded magic numbers — use `AppSpacing` | All padding/spacing via `AppSpacing.xs/sm/md/lg/xl` |
| No direct Scryfall calls from presentation layer | `CardDetailScreen` must not call `ScryfallApiClient` directly; if fetch-by-ID needed for FAV tap path, it goes through a repository/provider |
| `GoRouter` for all navigation — no `Navigator.push` | `context.go('/card/${card.id}', extra: card)` — confirmed |
| `ConsumerStatefulWidget` for local state | Flip toggle: `ConsumerStatefulWidget` with `bool _showBack` |
| `flutter analyze --fatal-infos` must pass | No warnings permitted; all imports must be used; all nullable fields guarded |
| Features must not import from each other's `data/` or `presentation/` layers | `card_detail/presentation` must not import from `card_discovery/data` or `favourites/data` |
| Cross-feature shared types go in `shared/models/` | `MagicCard` and `CardFace` belong in `lib/shared/models/magic_card.dart` |

---

## Sources

### Primary (HIGH confidence)

- Codebase: `lib/shared/models/magic_card.dart` — verified `MagicCard` constructor, `CardImageUris`, `CardPrices`, existing `_firstFaceImageUris` helper
- Codebase: `lib/core/router/app_router.dart` — verified current router structure, `/card/:id` GoRoute, `state.pathParameters` usage to replace
- Codebase: `lib/features/card_discovery/presentation/card_swipe_screen.dart` — verified `_CardFaceWidget` Stack structure, `CachedNetworkImage` pattern, `GestureDetector` insertion point
- Codebase: `lib/features/favourites/presentation/favourite_swipe_screen.dart` — verified `_FavouriteCardFace` holds `FavouriteCard` (not `MagicCard`), confirming the open question on data source
- Codebase: `lib/core/theme/app_theme.dart` — verified `AppColors` palette; confirmed no green color exists
- Codebase: `lib/core/constants/spacing.dart` — verified `AppSpacing` constants
- Codebase: `pubspec.yaml` — verified all required packages already present; no new dependencies needed
- Codebase: `test/` structure — verified existing test directories and fixture patterns

### Secondary (MEDIUM confidence)

- CONTEXT.md decisions D-01 through D-08 — user-locked decisions, high authority

### Tertiary (LOW confidence)

- GoRouter `extra` in-memory-only behavior: [ASSUMED from training knowledge]
- `SliverAppBar` `expandedHeight` behavior: [ASSUMED from training knowledge]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages verified in pubspec.yaml; no new deps
- Architecture: HIGH — all patterns verified from existing codebase; decisions locked in CONTEXT.md
- Pitfalls: HIGH for items verified in code; MEDIUM for GoRouter/SliverAppBar behavior (training knowledge)
- Open question (Pitfall 6 / FavouriteSwipeScreen): HIGH priority — must be resolved before planning completes

**Research date:** 2026-04-17
**Valid until:** 2026-05-17 (stable Flutter ecosystem; packages not on major version boundary)
