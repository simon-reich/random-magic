# Phase 1: CardSwipeScreen - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the `CardSwipeScreen` placeholder with the real implementation. After this phase, users can swipe through random MTG cards, see the full card face, shimmer loading while fetching, and three visually distinct error states with action buttons.

This phase adds `flutter_card_swiper` and `skeletonizer` dependencies, extends the `AppFailure` hierarchy with `RateLimitedFailure`, scaffolds the `activeFilterQueryProvider` null stub, and implements the complete swipe UI.

</domain>

<decisions>
## Implementation Decisions

### Card display
- **D-01:** Display the **full card face** (Scryfall `normal` image format), not an art crop.
  The card image already contains name, mana cost, type line, rules text, and flavour text — no separate metadata overlay is needed.
- **D-02:** Card is centered on screen using `AspectRatio(aspectRatio: 63/88)`, scaled to fit. Dark app background fills any letterbox area.
- **D-03:** No metadata overlay rendered in the Flutter UI. `DISC-03` (overlay spec) is **superseded** by this decision — the image itself carries that information.
- **D-04:** Null image URL guard still required before `CachedNetworkImage`; use `normal` URL from `image_uris` (fallback to `card_faces[0].image_uris.normal` for double-faced cards).

### Swipe gesture behaviour
- **D-05:** `flutter_card_swiper ^7.0.0` handles swipe gestures (proportional rotation 12–15°, velocity fly-off > 800 px/s OR > 40% card width).
- **D-06:** Swiping is **disabled** while a card is loading (`cardState.isLoading` gate). No race conditions.
- **D-07:** Both left and right swipe load the next random card — same action, same result.
- **D-08:** `CardSwiperController` lives on `ConsumerStatefulWidget` state (UI concern, not a Riverpod provider).
- **D-09:** `RandomCardNotifier` marked `keepAlive: true` to survive tab navigation.

### Swipe direction overlays
- **D-10:** Text label badge fades in on each side during a drag — same label shown on both the left and the right.
- **D-11:** Label text is **Claude's choice** — user wants something MTG-flavored and surprising. Pick a single short label (≤8 chars) that evokes the card-drawing / discovery theme.
- **D-12:** Label colour follows the app accent palette (`AppColors`). No hardcoded values.

### Action buttons
- **D-13:** No action buttons in Phase 1. Swipe is the only user interaction on the card screen. FAV button is Phase 3.

### Error and empty states
- **D-14:** All three error states render **inside the card shape** — the `AspectRatio(63/88)` slot — as a card-shaped placeholder widget. Layout stays stable; no full-screen takeover.
- **D-15:** Layout per error state: vertically centered column — icon (large) → title → subtitle → action button.
- **D-16:** Each error state uses a **distinct accent colour** to signal type at a glance:
  - `CardNotFoundFailure` (HTTP 404 — "No cards found") → **orange/amber**
  - `InvalidQueryFailure` (HTTP 422 — "Invalid filter settings") → **red/error**
  - `NetworkFailure` (timeout/no internet — "Could not reach Scryfall") → **blue-grey**
- **D-17:** Action buttons per state:
  - 404 → "Adjust Filters" (navigates to `AppRoutes.filters`)
  - 422 → "Fix Filters" (navigates to `AppRoutes.filters`)
  - Network → "Retry" (re-triggers `RandomCardNotifier` fetch)

### Loading state
- **D-18:** `skeletonizer ^1.x` wraps the real card widget tree — no separate skeleton layout.
- **D-19:** `SkeletonizerConfigData.dark()` configured in `AppTheme` so the shimmer matches the dark theme.

### New failure types and shared code
- **D-20:** `RateLimitedFailure` added to `lib/shared/failures.dart` as a new `final class` in the `AppFailure` sealed hierarchy (HTTP 429 from Scryfall).
- **D-21:** `activeFilterQueryProvider` scaffolded as a null stub in `lib/features/filters/presentation/providers.dart` — returns `null` (unrestricted query). No UI, just the provider definition.
- **D-22:** `legalities` field in `MagicCard.fromJson()` parsed defensively via `.toString()` conversion to avoid `Map<dynamic, dynamic>` cast errors.

### Claude's Discretion
- Exact shimmer/skeletonizer configuration beyond dark mode
- Internal widget decomposition (private sub-widgets vs single build method)
- Spacing and padding values — use `AppSpacing` constants throughout
- The specific MTG-flavored swipe overlay label text (D-11)

</decisions>

<specifics>
## Specific Ideas

- User explicitly wants the **full card face** (name, mana cost, type line, card text visible), not just artwork. This is a meaningful deviation from the original ROADMAP wording of "full-screen artwork + metadata overlay".
- Swipe overlay label: user said "something exciting and unusual — surprise me." Pick a short MTG-flavored term that fits the discovery theme (e.g., "DRAW", "CAST", "REVEAL" — but make it feel right).
- Error states should be visually distinct from one another AND from the loading shimmer (DISC-09).

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` §Discovery — DISC-01 to DISC-09 (note: DISC-03 is superseded by D-03 above)

### Existing domain model and error handling
- `lib/shared/models/magic_card.dart` — `MagicCard.fromJson()`, `image_uris` structure, double-faced card fallback (`card_faces[0].image_uris`)
- `lib/shared/failures.dart` — `AppFailure` sealed class hierarchy (`CardNotFoundFailure`, `InvalidQueryFailure`, `NetworkFailure`); add `RateLimitedFailure` here
- `lib/shared/result.dart` — `Result<T>` sealed class (`Success` / `Failure`) — used by all repository methods

### Existing providers and repository
- `lib/features/card_discovery/presentation/providers.dart` — `RandomCardNotifier` (`AsyncNotifier`); `randomCardProvider` is the state machine to drive
- `lib/features/card_discovery/domain/card_repository.dart` — `CardRepository` interface
- `lib/features/card_discovery/data/scryfall_api_client.dart` — `ScryfallApiClient`; maps DioException to AppFailure

### Theme and constants
- `lib/core/theme/app_theme.dart` — `AppColors` (all colour constants), `AppTheme.dark` (MaterialTheme); add `SkeletonizerConfigData.dark()` here
- `lib/core/constants/spacing.dart` — `AppSpacing` (xs/sm/md/lg/xl/xxl); use exclusively — no hardcoded numeric spacing

### Navigation
- `lib/core/router/app_router.dart` — `AppRoutes` string constants; 404/422 error buttons navigate to `AppRoutes.filters`

### Filters feature (for stub provider)
- `lib/features/filters/presentation/` — location for `activeFilterQueryProvider` null stub

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AppColors` / `AppSpacing` / `AppTheme.dark` — all theming and spacing ready; use exclusively
- `Result<T>` + `AppFailure` sealed classes — already wired; `RandomCardNotifier` already returns typed failures
- `CachedNetworkImage` — likely already in pubspec (check); handles image caching automatically
- `ConsumerStatefulWidget` pattern — established in codebase; `CardSwiperController` goes here

### Established Patterns
- `AsyncValue.when(data:, loading:, error:)` — all three states MUST be handled in presentation layer (no silent ignores)
- `package:random_magic/` import prefix — all internal imports use this path, never relative
- `const` constructors — use everywhere possible on widget constructors
- `///` doc comments on every public class, method, and provider — mandatory per CLAUDE.md

### Integration Points
- `randomCardProvider` (from `providers.dart`) drives the UI — watch this in `CardSwipeScreen`
- `activeFilterQueryProvider` (new null stub) is watched by `RandomCardNotifier.build()` in a future phase; scaffold the provider now so the import path is stable
- GoRouter shell scaffold (`_ShellScaffold` in `app_router.dart`) wraps the tab screens; `CardSwipeScreen` is the discovery tab

</code_context>

<deferred>
## Deferred Ideas

- FAV button (save to favourites) — Phase 3 (FAV-01)
- Card detail tap gesture — Phase 4
- Filter summary bar with active filter chips above card — Phase 2 (DISC-10)

</deferred>

---

*Phase: 01-cardswipescreen*
*Context gathered: 2026-04-12*
