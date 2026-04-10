# Feature & UX Research: Random Magic

**Domain:** MTG card discovery mobile app (Flutter)
**Researched:** 2026-04-10
**Data layer status:** Complete (MagicCard model, ScryfallApiClient, CardRepository, Hive CE wired)

---

## 1. Card Swipe UX Patterns

### The canonical feel (Tinder-style)

The interaction consists of three linked behaviours that must work together:

**Real-time drag following.** The card tracks the finger with zero perceptible lag. Any debounce or async operation between gesture and card position is immediately noticeable and feels broken. Flutter's `GestureDetector.onPanUpdate` + a single `Transform` widget achieves this without triggering layout passes.

**Proportional rotation.** Rotation is calculated from horizontal drag distance relative to screen width, not a fixed angular delta. The formula used across implementations is:

```
angle = (dragX / screenWidth) * maxAngle
```

`maxAngle` of **12–15 degrees** produces the natural feel. Values above 20 feel cartoonish. Values below 8 feel flat and unresponsive. The pivot point should be at the top-centre of the card (as if held at the top), not the geometric centre — this is what makes it feel like holding a physical card.

**Snap or fly-off decision.** On release, the card either returns to centre or animates off-screen. Two conditions independently trigger a fly-off:
- **Distance threshold:** horizontal drag exceeds ~40% of card width (not screen width)
- **Velocity threshold:** finger velocity exceeds ~800 px/s at release

Either condition alone is sufficient. Requiring both makes the interaction feel sluggish. The flutter_card_swiper package exposes `percentThresholdX` and `percentThresholdY` in the `cardBuilder` callback, which are exactly these ratios.

### Package recommendation: `flutter_card_swiper`

This is the right choice for this project. Reasons:

- Exposes `percentThresholdX` / `percentThresholdY` directly in the builder, which is needed to drive the overlay opacity (save/pass labels)
- `AllowedSwipeDirection` can restrict to horizontal-only, appropriate here (up/down not needed for MTG discovery)
- `CardSwiperController` allows programmatic swipe from buttons (needed for accessibility and the "save to favourites" action button)
- Active maintenance, iOS/Android/Web support
- Already used in the Flutter ecosystem for card-game adjacent apps

`appinio_swiper` is a valid alternative but its builder renders only two cards at a time and its API surface is slightly less ergonomic for the overlay-feedback pattern.

### Direction semantics for this app

Right swipe = **Save to favourites**. Left swipe = **Pass** (discard and fetch next). Do not implement up/down swipe — it adds cognitive overhead with no UX benefit for a discovery app.

### Visual feedback during drag

Directional overlays are non-negotiable. Without them, users cannot tell what the gesture will do. The pattern:

- **Right drag:** Green-tinted overlay with a bookmark or heart icon (or text "SAVE") fades in proportionally to `percentThresholdX`. Reaches full opacity at ~60% threshold.
- **Left drag:** Muted/red-tinted overlay with an X icon (or text "PASS") mirrors the same behaviour.
- **No label at rest or near-centre:** The overlay should not be visible when `percentThresholdX < 0.15` to avoid visual noise during small corrective movements.

### Card stack depth

Show 2–3 cards in the stack behind the active card. The card immediately behind should be slightly smaller (scale ~0.95) and shifted upward ~8–12px. A third card, if shown, should be at ~0.90 scale. This creates depth perception and communicates that there are more cards to discover. The offset/scale is static — it does not animate until a swipe completes.

### Pre-fetching

Pre-fetch the next card as soon as the current one is displayed, not after the swipe completes. Scryfall's `/cards/random` is fast (~200–400ms) but a blank loading state between swipes destroys the flow. The architecture should keep a small buffer (2–3 cards) using the existing `CardRepository`.

---

## 2. MTG Card Display on the Swipe Card

### What to show on the card face

The Scryfall `normal` image (~488×680 px JPEG) is the primary content. It already contains the full card art, mana cost, type line, and rules text rendered in the original card layout. Do not recreate this layout in Flutter — render the image and overlay only supplementary information.

**Overlay at the bottom of the card (semi-transparent dark gradient):**

| Field | Why | Notes |
|---|---|---|
| Card name | First thing users want to know | Use the `name` field |
| Mana cost | Instant colour/cost read; players parse this reflexively | Render mana symbols, not raw text like `{2}{R}{R}` |
| Type line | Determines if it's relevant to what they're looking for | Truncate at 40 chars if needed |
| Rarity pip | Small coloured dot — minimal space, high info density | Use rarity colours below |
| Set name | Contextual; helps collectors | Can be smaller/secondary weight |

**Do not overlay:**
- Oracle text (already on the card image; too long for overlay)
- Power/toughness (visible on the image for creatures; not worth the overlay space)
- Price (belongs on the detail screen, not the swipe view)
- Legalities (detail screen only)

### Mana symbol rendering

Do not display the raw mana cost string like `{2}{R}{R}`. This is the single biggest quality-of-life difference between an app that feels MTG-native and one that feels like a developer project.

The `mtg` Flutter package (pub.dev) provides `parseManaCostString('{2}{R}{R}')` which returns a `List<Widget>` of SVG-based mana symbols ready for use in a `Row`. This uses vector assets, scales cleanly, and covers all symbol types including hybrid, Phyrexian, and colourless.

If the mana cost is null (land cards), show nothing in that slot. Do not show "Free" or blank space.

### Rarity colour dots

Use these colour values, which match the standard established across MTG digital tools:

| Rarity | Colour | Hex |
|---|---|---|
| Common | Near-black | `#212121` |
| Uncommon | Silver-blue | `#B9DCEB` |
| Rare | Gold | `#E6CD8C` |
| Mythic Rare | Orange/rose-gold | `#F59105` |

A single 8px coloured dot next to the rarity label is sufficient. Do not use full rarity icon SVGs on the swipe card — too much visual noise.

### Double-faced cards

The `MagicCard.fromJson` already handles the fallback from `card_faces[0].image_uris` when top-level `image_uris` is absent. The `normal` image URL will be populated correctly. The swipe card itself does not need to handle DFC flipping — that belongs to the card detail screen. Show only the front face image on the swipe card.

---

## 3. Filter UX

### Colour filter: mana symbol toggles

Do not use text labels (White, Blue, Black...) or generic coloured circles. Use the official MTG mana symbol icons for W/U/B/R/G/C (Colourless). These are immediately parseable by any MTG player without reading.

Layout: a horizontal row of 6 circular icon buttons (~48px tap target), spaced evenly. Selected state: filled background using the colour's identity colour. Unselected state: outline only.

Multi-select is expected (fetch cards that are Red AND Green). The query builder already uses Scryfall's `color:R OR color:G` syntax for OR logic, and `color>=RG` (includes both) for AND. Clarify in the UI which mode is active — a small label like "Any of these" vs "All of these" with a toggle achieves this without burying the concept.

Colourless (`C`) and Multicolour (`M`) should be included as options in the same row. Players expect them there.

### Type filter: chip group

Card types (Creature, Instant, Sorcery, Enchantment, Artifact, Land, Planeswalker) should be presented as filter chips in a wrap layout. Filter chips are the Material 3 standard for multi-select categories. Each chip toggles independently. Selected chips use the app's accent colour with a checkmark; unselected chips use outline style.

Do not use a dropdown or a list of checkboxes. Chips allow visual scanning of all options at once, which is critical when users are mid-session and want to quickly change their mind.

Limit to the 7 main types. Do not expose subtypes (Warrior, Dragon, etc.) in the filter UI — the combinations are too numerous and subtypes are Scryfall advanced-search territory.

### Rarity filter: chip group with colour pips

Same chip pattern as types, but each chip should include the rarity pip colour (as described in section 2) as a leading element inside the chip. This reinforces the visual language consistently.

Options: Common, Uncommon, Rare, Mythic. All four shown, multi-select.

### Date range filter

Use two date pickers (Released After, Released Before) rather than a slider. MTG sets have specific release dates and players tend to think in terms of set names / eras, not continuous ranges. A simple text field with a calendar picker is adequate. Show the selected range as a summary chip ("After 2020-01-01") when set.

### Active filter summary bar

At the top of the swipe screen, show a compact horizontal scrolling row of chips representing currently active filters. Each chip should have an X to remove it inline. This gives users permanent visibility of what's constraining their results without requiring them to navigate to the filter screen.

A "Clear all" action should be accessible next to this bar when any filters are active.

### Filter presets

The save-preset flow should be: user configures filters, taps "Save preset", enters a name in a bottom sheet dialog, confirms. Preset list is presented as a scrollable list in the filter screen. Tapping a preset applies all its settings immediately. Presets with identical names should be prevented at save time (show inline validation, not an error dialog).

---

## 4. Favourites UX

### Layout: 3-column grid, portrait orientation

For a card collection view, a 3-column grid using `artCrop` images (square, art-only, no frame) is the right choice for mobile. Rationale:

- `artCrop` is visually dense and immediately recognisable; the card frame adds no information in thumbnail view
- 3 columns fits ~12 cards on screen simultaneously, giving a sense of collection density
- 2 columns is too sparse; 4 columns makes art unrecognisable at phone pixel densities

Use a `SliverGrid` with `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3)` and ~2px gaps. Each cell is square. `cached_network_image` (already in pubspec) handles the network caching.

### Tap to enter swipe mode

Tapping a card in the grid should enter a swipe-through-favourites mode (the `FavouriteSwipeScreen`). Show the full `normal` image in a swipeable stack of the user's favourites. This is what ManaBox and similar apps do — the grid is a navigation surface, not the primary viewing experience.

### Delete from favourites

On the favourites swipe screen, a trash/remove icon button should be clearly visible (top-right or as a swipe-down action). Do not use swipe-left/right for delete in the favourites view — it creates ambiguity with the discovery swipe. Use an explicit button.

On the grid view, a long-press to enter multi-select mode for bulk deletion is the standard pattern and is worth implementing for users who accumulate large collections.

### Filtering within favourites

Apply the same colour/type/rarity chip pattern as the main filter screen. Present it as a bottom sheet triggered by a filter icon in the app bar. This keeps the grid clean.

---

## 5. Scryfall-Specific UX: No Cards Found (404) and Invalid Query (422)

### 404 — No cards match the current filters

This is the most common error users will encounter. The UX must:

1. **Explain what happened without blaming the user.** Copy: "No cards match your filters." Not "Invalid request" or "Error 404".

2. **Show what filters are active.** Repeat the active filter chips in the empty state so the user does not have to navigate back to see what caused it.

3. **Provide one clear primary action.** A single prominent button: "Adjust Filters". This navigates directly to the filter screen. Do not provide multiple competing calls to action.

4. **Optional secondary action.** "Clear all filters" as a text link below the primary button. This lets experienced users who know they over-constrained their query fix it in one tap.

5. **Illustration.** An illustrated empty state (a simple card-with-question-mark or a sad wizard) makes the state feel intentional rather than broken. This is optional but meaningfully improves perceived quality.

Do not auto-clear filters or auto-retry. The user's intent was to see those filter results — silently changing their configuration without consent is a UX anti-pattern (Airbnb learned this the hard way with their filter reset behaviour).

### 422 — Invalid query syntax

This should not surface to users under normal operation if the `ScryfallQueryBuilder` is correct. However, if it does occur:

- Show: "Your filter combination produced an invalid query. Please try different settings."
- Do not expose the raw Scryfall error message — it contains query syntax that is meaningless to end users.
- Provide: "Adjust Filters" button, same as the 404 flow.
- Log the raw error internally for debugging.

### Network timeout / connectivity error

Show: "Could not reach Scryfall. Check your connection." with a **Retry** button that re-runs the same request. This is already called out in CLAUDE.md and the error handling is defined in `ScryfallApiClient`. The UI must surface it as a full-screen state, not a toast, because there is no card to show.

### Pre-emptive filter validation

When a user has configured filters that are known to produce very few cards (e.g., Mythic + a single colour + a narrow date range), consider showing a warning inline in the filter screen before they close it: "These filters may return few results." This can be heuristic-based — no API call required — using rough known rarity distributions. This is a polish item, not MVP.

---

## 6. Implementation Notes for the Flutter Layer

### No missing fields are shown as blank

The `MagicCard` model already marks `flavorText` and `manaCost` as nullable with the convention that null means "hide the field". The UI layer must honour this: use conditional rendering (`if (card.manaCost != null) ...`), never render an empty `SizedBox` in place of missing content.

### Image loading states

`cached_network_image` is already in the pubspec. Always provide:
- A placeholder: a `Container` with the rarity pip colour as background (low effort, high quality feel)
- An error widget: a card-shaped container with a "?" icon — not a generic error icon

Avoid shimmer loading effects on the swipe card itself. They draw attention to loading rather than the card. A solid colour placeholder is less distracting.

### Dark theme compliance

The overlay gradient on the swipe card should be `Colors.black.withOpacity(0.65)` — dark enough to read white text over any card art, light enough not to obscure the art. Test specifically with white-bordered cards (older sets) where the contrast assumption can fail.

Never use `Theme.of(context).colorScheme` colours directly as overlay backgrounds — they depend on the theme seed and will produce unexpected tints.

### Action buttons below the swipe card

A row of two icon buttons below the card stack (X for pass, heart/bookmark for save) is expected by users who find gesture-only UIs inaccessible. These should map to `CardSwiperController.swipeLeft()` and `CardSwiperController.swipeRight()`, producing the identical animation as a manual swipe.

---

## Sources

- [Vinova: Engineering Tinder-Style Swipe Interfaces](https://vinova.sg/engineering-tinder-style-swipe-interfaces-in-react-native/) — threshold and rotation patterns
- [Phill Farrugia: Building a Tinder-esque Card Interface](https://medium.com/@phillfarrugia/building-a-tinder-esque-card-interface-5afa63c6d3db) — pivot point and animation feel
- [JC: Creating Tinder-Like Swipeable Cards in SwiftUI](https://medium.com/@jaredcassoutt/creating-tinder-like-swipeable-cards-in-swiftui-193fab1427b8) — swipeThreshold / rotationFactor values
- [flutter_card_swiper on pub.dev](https://pub.dev/packages/flutter_card_swiper) — package parameters
- [appinio_swiper on pub.dev](https://pub.dev/packages/appinio_swiper) — alternative package comparison
- [Scryfall Card Objects API](https://scryfall.com/docs/api/cards) — canonical field reference
- [Scryfall Error Objects API](https://scryfall.com/docs/api/errors) — 404/422 semantics
- [Material Design 3: Chips](https://m3.material.io/components/chips/guidelines) — filter chip pattern
- [NN/G: Empty State Interface Design](https://www.nngroup.com/articles/empty-state-interface-design/) — empty state guidelines
- [mtg Flutter package](https://pub.dev/documentation/mtg/latest/) — mana symbol rendering
- [MTG Rarity colours reference](https://cardboardkeeper.com/mtg-rarities/) — common/uncommon/rare/mythic colour values
- [PatternFly: Card View guidelines](https://www.patternfly.org/patterns/card-view/design-guidelines/) — grid layout patterns
- [Filter UI best practices](https://www.insaim.design/blog/filter-ui-design-best-ux-practices-and-examples) — chip-based filter patterns
