# Phase 4: Card Detail View — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 04-card-detail-view
**Areas discussed:** Navigation & Data Source, Double-faced card model, Detail screen layout, Legality display

---

## Navigation & Data Source

| Option | Description | Selected |
|--------|-------------|----------|
| Pass MagicCard via extra | context.go('/card/${card.id}', extra: card) — no re-fetch, instant display | ✓ |
| Re-fetch by cardId | Navigate with ID, detail screen calls Scryfall GET /cards/{id} — extra latency | |
| Pass via extra + ID fallback | Try extra first; fall back to re-fetch if null — over-engineering for v1 | |

**User's choice:** Pass MagicCard via extra
**Notes:** GoRouter extra doesn't survive deep links, but that's acceptable — deep linking to card detail is not a v1 requirement.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Tap the card image itself | GestureDetector wrapping card face widget — same in both swipe screens | ✓ |
| Info button / icon overlay | Small ℹ️ button Positioned on the card | |
| You decide | Leave to planner/executor | |

**User's choice:** Tap the card image itself
**Notes:** Same tap pattern in both CardSwipeScreen and FavouriteSwipeScreen.

---

## Double-Faced Card Model

| Option | Description | Selected |
|--------|-------------|----------|
| Add cardFaces list to MagicCard | List<CardFace>? with imageUris, name, typeLine, oracleText, manaCost | ✓ |
| Add backFaceImageUrl only | Minimal change — enough for flip image but can't show back-face text | |
| Re-fetch on flip | Keep model as-is; fetch full DFC JSON on flip — extra latency | |

**User's choice:** Add cardFaces list to MagicCard

---

| Option | Description | Selected |
|--------|-------------|----------|
| Image + name + type + oracle text | All fields that genuinely differ per face on DFCs | ✓ |
| Image only | Just swap artwork — misleading if oracle text differs | |
| You decide | Leave to planner | |

**User's choice:** Image + name + type + oracle text
**Notes:** Mana cost stays from front face (Scryfall convention). Prices and legalities fixed.

---

## Detail Screen Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Scrollable page, artwork at top | SliverAppBar with expandedHeight — collapses on scroll | ✓ |
| Sticky artwork + scrollable content | Fixed-height image + SingleChildScrollView below | |
| You decide | Leave to planner/executor | |

**User's choice:** Scrollable page, artwork at top

---

| Option | Description | Selected |
|--------|-------------|----------|
| large | 672×936px — sharper than normal for a dedicated detail view | ✓ |
| normal | Same as swipe screen — consistent but less detail | |
| png | Lossless, highest quality but large file size — overkill | |

**User's choice:** large
**Notes:** Fall back to normal if large is null.

---

## Legality Display

| Option | Description | Selected |
|--------|-------------|----------|
| Colored badge rows | Format name left, colored badge right (green/red/grey) | ✓ |
| Plain text table | Two-column table: Format | Status — no color coding | |
| Chips / tags | Show only legal formats as chips — hides Not Legal status | |

**User's choice:** Colored badge rows
**Notes:** Formats shown: Standard, Modern, Legacy, Commander (minimum). Green=Legal, Red=Banned, Grey=Not Legal/Restricted.

---

## Claude's Discretion

- Exact SliverAppBar vs sticky-image layout (SliverAppBar recommended, sticky image acceptable)
- Spacing, padding, and section divider style
- Flip toggle as local widget state or StateProvider
- Additional format rows beyond the required four

## Deferred Ideas

None.
