# Research Summary: Random Magic

**Project:** Random Magic
**Researched:** 2026-04-10
**Confidence:** HIGH overall

---

## Executive Summary

Random Magic is a Tinder-style card discovery app where the swipe mechanic is the entire UX. Infrastructure is complete (Dio, Riverpod 3.x, GoRouter, MagicCard model, CardRepository). RM-13 is the first user-facing screen.

Research converges on a clear implementation path with all conflicts resolved. No further research needed for Phases 1–3. Phase 4 needs one check (GoRouter 17.x iOS ShellRoute status).

---

## Key Decisions

### Resolved Conflict: `flutter_card_swiper` vs `GestureDetector`

**Verdict: Use `flutter_card_swiper ^7.0.0`**

The `GestureDetector` + `AnimatedSwitcher` approach produces a crossfade — not a Tinder-style swipe. UX research is explicit: proportional rotation (12–15 degrees), velocity-based fly-off (>800 px/s OR >40% card width), and directional overlays are non-negotiable for the mechanic to feel intentional. Building these correctly is ~200–400 lines of animation code. `flutter_card_swiper 7.x` (maintained November 2025) provides all of it and integrates cleanly with Riverpod: hold `CardSwiperController` as a field on `ConsumerStatefulWidget`, call `notifier.refresh()` in the `onSwipe` callback.

### Recommended Package Additions

| Package | Version | Purpose | Decision |
|---------|---------|---------|---------|
| flutter_card_swiper | ^7.0.0 | Swipe gestures, rotation, fly-off, snap-back | Add in Phase 1 |
| skeletonizer | ^1.0.0 | Skeleton loading — wraps real widget tree | Add in Phase 1 |
| cached_network_image | ^3.4.1 | Image caching | Keep (already in pubspec) |
| mtg | latest | Mana symbol SVG rendering | Defer to Phase 2+ |

### Architecture: Filter → Notifier

`RandomCardNotifier.build()` watches `activeFilterQueryProvider` (a `keepAlive: true` `String?` notifier). When filters change, the notifier rebuilds and fetches automatically — no manual invalidation. The swipe screen is ignorant of filter internals.

```
ActiveFilterQuery (keepAlive)     ← written by FilterSettingsScreen
    ↓ ref.watch in build()
RandomCardNotifier (keepAlive)    → CardRepository → ScryfallApiClient → Dio
```

In RM-13, scaffold `activeFilterQueryProvider` as a null stub (one file, one provider, zero UI work).

### Refresh pattern

Manual `state = AsyncLoading(); state = await AsyncValue.guard(...)` — **not** `ref.invalidateSelf()`. The manual pattern shows shimmer immediately on swipe; `invalidateSelf()` preserves old card for one frame.

### Hive CE lifecycle

Open all boxes in `main()` before `runApp()`. GoRouter shell routes eagerly instantiate providers — any synchronous `Hive.box()` call before the box is open throws `HiveError`. Never close boxes during session. Implement this in Phase 2 (first Hive-dependent phase).

### FavouriteCard model

Do NOT persist `MagicCard` directly. Use a `FavouriteCard` projection in `features/favourites/domain/` with only display fields + `savedAt` timestamp. `typeId: 0` → FilterPreset, `typeId: 1` → FavouriteCard.

---

## Critical Pitfalls for RM-13

| # | Pitfall | Fix |
|---|---------|-----|
| 1 | Race condition: second swipe while first fetch in-flight | Gate gesture: `onSwipe: cardState.isLoading ? null : ...` |
| 2 | Null URL crashes `CachedNetworkImage` | Guard: `if (url == null \|\| url.isEmpty) return placeholder` |
| 3 | Layout shift from unsized placeholder | `AspectRatio(aspectRatio: 63/88)` wrapper on card |
| 4 | `RandomCardNotifier` resets on tab navigation | `@Riverpod(keepAlive: true)` on the notifier |
| 5 | `CardSwiperController` leak | `_controller.dispose()` in `dispose()` before `super.dispose()` |
| 6 | HTTP 429 not handled | Add `RateLimitedFailure` to `shared/failures.dart` |
| 7 | `legalities` cast crash | Replace `.cast<String, String>()` with `.toString()` conversion |

---

## What RM-13 Must Deliver (UX Requirements)

**Swipe mechanics:**
- Proportional rotation: `angle = (dragX / screenWidth) * 12–15 degrees`; pivot at top-centre
- Fly-off on velocity (>800 px/s) OR distance (>40% card width) — either condition alone
- Right = next card (pass); Left = next card (pass). Favourites wired in Phase 3.
- Directional overlays: fade in proportional to drag; invisible below 15% threshold
- 2–3 card stack depth (0.95 and 0.90 scale, 8–12px offset)
- Action buttons below card (X and ♥) → `CardSwiperController.swipeLeft/Right()`

**Card display overlay (bottom gradient):**
- Name, type line, rarity pip (colour dot), set name
- Mana cost: deferred (requires `mtg` package)
- `Colors.black.withOpacity(0.65)` gradient — tested on white-bordered older cards

**Loading & error states:**
- `Skeletonizer(enabled: isLoading, child: CardWidget(placeholder))` — same tree for skeleton
- `CardNotFoundFailure` → "No cards match your filters" + "Adjust Filters" button
- `InvalidQueryFailure` → "Invalid filter combination" + filter link
- `NetworkFailure` → "Could not reach Scryfall" + Retry button
- `RateLimitedFailure` → "Scryfall is rate-limiting, try again in 30s"

---

## Deferred from RM-13

- Pre-fetch buffer (shimmer between swipes acceptable for v1)
- Mana symbol SVG rendering (requires `mtg` package — Phase 2+)
- Favourites save action (Phase 3)
- Filter UI integration beyond null stub (Phase 2)

---

## Phase-by-Phase Flags

| Phase | Research needed | Notes |
|-------|----------------|-------|
| Phase 1 (RM-13) | None | All patterns fully specified |
| Phase 2 (Filters) | None | architecture.md has explicit code patterns |
| Phase 3 (Favourites) | None | architecture.md has explicit patterns |
| Phase 4 (Card Detail) | **Yes** — verify GoRouter 17.x fix for GitHub `#120353` (iOS ShellRoute swipe-back conflict) before building navigation shell |
| Phase 5 (Tests) | None | Testing patterns explicit in pitfalls.md |

---

## Gaps / Unconfirmed at Research Time

- `cached_network_image` memory under rapid swiping — benchmark during Phase 1; set `memCacheWidth` if pressure detected; fallback is `cached_network_image_ce` (one-line pubspec change)
- `flutter_card_swiper` exact 7.x minor version — confirm latest on pub.dev before adding
- GoRouter 17.x fix for iOS ShellRoute swipe-back (GitHub `#120353`) — verify before Phase 4

---

*Synthesized: 2026-04-10*
