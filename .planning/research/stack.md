# Stack Research: Remaining Feature Packages

**Project:** Random Magic
**Researched:** 2026-04-10
**Scope:** Packages needed to complete CardSwipeScreen (RM-13), Filter UI + Hive CE presets, Favourites with Hive CE persistence. Core stack already decided — this file covers only the open questions.

---

## 1. Swipe Gesture: Package vs. GestureDetector

### The Decision Space

There are two viable paths: roll a custom `GestureDetector` + `Transform` + `AnimationController` implementation, or adopt a dedicated swipe-card package. The custom path is appropriate when you need full control over physics (spring curves, drag thresholds, rotation math). The package path is appropriate when the swipe mechanic is standard Tinder-style and developer time is better spent elsewhere.

For Random Magic the swipe mechanic IS the core UX, but it is also entirely standard: drag card, rotate slightly with drag offset, release triggers directional action or snap-back. There is no exotic behaviour (no stacking piles, no multi-select, no chained animations). A package is appropriate.

### Packages Evaluated

**flutter_card_swiper** (ricardodalarme/flutter_card_swiper)
- Latest version: 7.x (last updated November 2025 — actively maintained)
- Supports swipe in four directions; exposes `CardSwiperController` for programmatic triggers from outside the widget (button taps, keyboard shortcuts)
- `onSwipe` callback receives `currentIndex`, `previousIndex`, and `CardSwiperDirection` — enough to trigger `randomCardNotifier.refresh()` on every swipe
- `CardSwiperDirection` is a class (not an enum) as of recent versions, enabling custom-angle swiping via `CardAnimation.animateToAngle`
- Undo support via `CardAnimation.animateUndoFromAngle`
- Supports displaying multiple cards in a stack simultaneously (useful if a "peek" of the next card is desired)
- Pub score: high; Flutter 3.x compatible
- Confidence: MEDIUM (pub.dev metadata verified via search; version number from November 2025 update confirmed)

**appinio_swiper** (appinioGmbH/flutter_packages)
- Latest version: 2.1.1 (last meaningful update: April 2024 — less active than flutter_card_swiper)
- Also supports four-direction swipe, custom widgets, programmatic control
- Maintained by a company (Appinio GmbH) but slower release cadence
- Confidence: MEDIUM

**GestureDetector (custom)**
- Full control, zero dependencies, no versioning risk
- Requires implementing: drag tracking, rotation transform, velocity-based release threshold, snap-back animation, directional classification — ~200-400 lines of animation code that needs thorough testing
- `onPanUpdate` + `Transform.rotate` + `AnimationController` with `Curves.elasticOut` for snap-back is the standard pattern; well documented in Flutter cookbook
- Viable but disproportionate effort for a standard mechanic

**Recommendation: flutter_card_swiper ~7.x**

Rationale: actively maintained (November 2025), the `CardSwiperController` integrates cleanly with Riverpod — the controller lives in the `ConsumerStatefulWidget` and the `onSwipe` callback calls `ref.read(randomCardNotifierProvider.notifier).refresh()`. No provider needs to hold the controller. The package handles gesture physics, rotation, and snap-back correctly out of the box; there is no compelling reason to build this from scratch.

Add to pubspec:
```yaml
flutter_card_swiper: ^7.0.0
```

Verify the exact latest `^7.x` version on pub.dev before adding — use the minimum compatible with the project's Flutter SDK constraint.

---

## 2. Shimmer / Skeleton Loading

### The Decision Space

Two dominant approaches exist in the Flutter ecosystem:

**shimmer** (hunghd.dev)
- The original; wraps any widget in a shimmer gradient animation
- Requires manually building a skeleton layout (grey boxes/circles) to place inside the `Shimmer.fromColors` wrapper
- Last published: ~2 years ago (as of April 2026); effectively unmaintained
- Still functional — the API is simple and unlikely to break — but a frozen dependency is a maintenance liability
- Confidence: MEDIUM (multiple sources confirm stale maintenance)

**skeletonizer** (Milad-Akarie/skeletonizer)
- Wraps existing widget trees and automatically converts them to skeleton placeholders; no separate skeleton layout required
- Three built-in painting effects (shimmer, pulse, wave) — each configurable
- Dark mode support via `SkeletonizerConfigData.dark()` as a `ThemeExtension`; fits naturally into the existing dark theme in `AppTheme`
- Actively maintained — changelog confirms Flutter 3.32.0 support (2025), recent fixes include improved painting context override for better performance and a release-mode crash fix
- `Skeletonizer(enabled: isLoading, child: actualCardWidget)` — the same widget tree is used for both skeleton and real content; this aligns well with the existing `AsyncValue.when` pattern in Riverpod consumers
- Confidence: HIGH (pub.dev changelog directly confirmed via search, Flutter 3.32 support verified)

**Recommendation: skeletonizer ^1.x**

Rationale: The existing `RandomCardNotifier` exposes `AsyncValue<MagicCard>`. In the `CardSwipeScreen` consumer, the loading state maps directly to `Skeletonizer(enabled: true, child: CardWidget(placeholderCard))`. No separate skeleton layout to maintain. Dark mode is handled automatically via `SkeletonizerConfigData.dark()` in `AppTheme.darkTheme`. This is strictly less work than `shimmer` and produces a more realistic loading state.

Add to pubspec:
```yaml
skeletonizer: ^1.0.0
```

Configure in `AppTheme`:
```dart
extensions: [
  SkeletonizerConfigData.dark(), // for darkTheme
]
```

---

## 3. cached_network_image + Scryfall CDN

### Maintenance Status

The original `cached_network_image` package (Baseflow) has been effectively unmaintained since August 2024. Over 300 issues are unresolved including reported memory leaks and scroll performance bugs. The last meaningful release predates Flutter 3.27 (December 2024), which introduced a regression where HTML images from `cached_network_image` stopped loading on web.

The project already depends on `cached_network_image: ^3.4.1`. For iOS and Android targets only (which is the scope of this project), the package continues to function. The web regression does not apply.

### Scryfall CDN Specifics

Scryfall serves card images via direct HTTPS URLs in the `image_uris` JSON fields (e.g. `cards.scryfall.io/normal/...`). These are direct image URLs, not the redirect-bearing `/cards/random?format=image` endpoint. The redirect concern (HTTP 302 from the API's image format endpoint) does not apply here — the app fetches card JSON via Dio and then uses the URL from `imageUris.normal` or `imageUris.png` directly with `CachedNetworkImage`. No redirect is involved in image loading.

Known issues to be aware of:
- Scryfall images are large JPEGs (~200 KB for `normal`, ~800 KB for `png`). The `normal` size (488x680 px) is the correct choice for the swipe card — `large` and `png` are unnecessarily heavy for list/swipe views.
- Use `imageUris.artCrop` for thumbnail contexts (favourites list).
- `imageUris.normal` may be null on some tokens — `MagicCard.fromJson` already handles this with nullable fields; the UI must supply a placeholder.
- No Scryfall-specific CDN CORS issues exist for mobile targets (CORS is only relevant on Flutter Web).

### Community Edition Alternative

`cached_network_image_ce` (Erengun/flutter_cached_network_image_ce) is a community-maintained drop-in replacement. It replaces the `sqflite` cache backend with `hive_ce` (which this project already depends on), claims 99% API compatibility, and is actively maintained. This is a strong candidate if the original package causes issues.

**Recommendation: Keep cached_network_image ^3.4.1 for now; document the migration path**

The original package works correctly on iOS and Android for this project's direct-URL image loading pattern. Switching is low-risk but adds churn with no immediate gain. If memory or performance issues surface during development, migrate to `cached_network_image_ce` (single `pubspec.yaml` change + import rename).

If a migration is needed:
```yaml
# Replace:
cached_network_image: ^3.4.1
# With:
cached_network_image_ce: ^3.6.x  # verify latest on pub.dev
```
No other code changes required due to API compatibility.

---

## 4. Riverpod + Swipe Card Pattern

### The Standard Pattern

The `RandomCardNotifier` already established in `providers.dart` is the correct foundation. The pattern for swipe-to-next in Riverpod is:

```
User swipes card
  → flutter_card_swiper onSwipe callback fires
  → ref.read(randomCardNotifierProvider.notifier).refresh()
  → state = AsyncLoading()  [skeleton shown by Skeletonizer]
  → state = AsyncData(newCard)  [new card animated in]
```

The `CardSwiperController` should live as a field on the `ConsumerStatefulWidget` (not in a provider). It is a UI-layer concern — it controls the animation widget, not the business state. The Riverpod provider owns the card data; the controller owns the swipe animation.

```dart
class _CardSwipeScreenState extends ConsumerState<CardSwipeScreen> {
  final _controller = CardSwiperController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  // ...
}
```

### Pre-fetching / Buffering

The current `RandomCardNotifier.refresh()` is single-card — it fetches one card at a time on demand. This means there is a loading gap after every swipe (shimmer is shown while the next card loads). This is acceptable for v1 and matches the shimmer-loading requirement in RM-13.

If future tickets require eliminating the loading gap, the pattern is to extend the notifier to maintain a small buffer (e.g. `List<MagicCard>`) and pre-fetch the next card while the current one is displayed. Do not implement this in RM-13 — it adds significant complexity and is not required by the acceptance criteria.

### Filter Query Threading

The `_fetch` method in `RandomCardNotifier` already accepts an optional `query` parameter. When filter support is wired in, the notifier should read the active filter preset from a `FilterSettingsNotifier` via `ref.watch` in `_fetch`, not accept filters as a method argument. This keeps the card provider reactive — changing filters automatically invalidates and re-fetches.

### Favourites Pattern

Favourites write to Hive CE. The recommended pattern:

```
User taps favourite icon
  → ref.read(favouritesRepositoryProvider).save(currentCard)
  → FavouritesNotifier state updated
  → Icon swaps to filled variant (local UI state, not AsyncLoading)
```

There is no need to show loading state for a Hive CE write (it is synchronous/near-instant). Use a simple `StateProvider<bool>` or a field on the screen state to track whether the current card is already favourited.

---

## Package Summary

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| flutter_card_swiper | ^7.0.0 | Card swipe gestures | Add — actively maintained Nov 2025 |
| skeletonizer | ^1.0.0 | Skeleton/shimmer loading | Add — actively maintained, Flutter 3.32 support confirmed |
| cached_network_image | ^3.4.1 | Image caching | Keep — works for mobile; migration path documented |

---

## Sources

- flutter_card_swiper on pub.dev: https://pub.dev/packages/flutter_card_swiper (last updated November 2025 per search metadata)
- appinio_swiper on pub.dev: https://pub.dev/packages/appinio_swiper
- skeletonizer on pub.dev: https://pub.dev/packages/skeletonizer
- skeletonizer changelog (Flutter 3.32 support): https://pub.dev/packages/skeletonizer/changelog
- skeletonizer GitHub: https://github.com/Milad-Akarie/skeletonizer
- shimmer package maintenance status: https://pub.dev/packages/shimmer/versions
- cached_network_image community edition: https://github.com/Erengun/flutter_cached_network_image_ce
- Scryfall image URI documentation: https://scryfall.com/docs/api/images
- Scryfall CDN URI stability announcement: https://scryfall.com/blog/upcoming-api-changes-to-scryfall-image-uris-and-download-uris-224
- Flutter GestureDetector docs: https://docs.flutter.dev/ui/interactivity/gestures
- Swipe cards + Riverpod sample: https://github.com/bestriser/swipe_cards_riverpod_sample
