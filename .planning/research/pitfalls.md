# Pitfalls & Gotchas: Random Magic

**Stack:** Flutter stable / Dart ^3.x / Riverpod 3.x / Dio 5.9.x / Hive CE 2.19.x / GoRouter 17.x / cached_network_image
**Researched:** 2026-04-10
**Confidence:** MEDIUM–HIGH (Scryfall layout rules HIGH from official docs; Riverpod 3.x lifecycle HIGH from changelog; Hive CE migration MEDIUM from community; swipe UX MEDIUM from Flutter issue tracker; cached_network_image MEDIUM from GitHub issues)

---

## 1. Scryfall API Pitfalls

### 1.1 Layouts where `image_uris` is absent at the top level

**What goes wrong.**
`MagicCard.fromJson` falls back to `card_faces[0].image_uris` only for the double-faced-card family. But Scryfall has more than two layout families where top-level `image_uris` is absent:

| Layout | `image_uris` location | Notes |
|---|---|---|
| `transform` | `card_faces[n].image_uris` | Classic DFC (e.g. Werewolves) |
| `modal_dfc` | `card_faces[n].image_uris` | MDFCs (e.g. Pathway lands) |
| `double_faced_token` | `card_faces[n].image_uris` | Promo tokens |
| `reversible_card` | `card_faces[n].image_uris` each face has independent card_face.layout |
| `meld` | **top-level** `image_uris` present | Meld cards themselves still have top-level image_uris; the melded result is a separate card object |
| `art_series` | **top-level** `image_uris` present | Art cards (non-gameplay) |
| `adventure` | **top-level** `image_uris` present | Single card object, no card_faces image split |
| `split` | **top-level** `image_uris` present | Full card image; card_faces hold per-half text |
| `flip` | **top-level** `image_uris` present | Full card image; flip side is a second card_face |

**Current code status.** `MagicCard.fromJson` already handles the most dangerous case (absent top-level `image_uris` → fall back to `card_faces[0].image_uris`). The fallback also returns an empty map `{}` if `card_faces` is missing, allowing `CardImageUris` to be constructed without crashing. This is correct.

**Remaining risk.**
- `reversible_card` puts *two fully independent cards* in `card_faces`. The app displays only face 0. That is acceptable for a random-card viewer, but should be documented so future developers do not treat the result as a complete card.
- If Scryfall ever returns a card where both `image_uris` and `card_faces[0].image_uris` are absent (e.g. a newly added layout the code does not yet anticipate), the `CardImageUris` object will have all-null URLs. The `CachedNetworkImage` placeholder must handle a null/empty URL gracefully rather than crashing — see section 5.

**Prevention.**
Keep the `_firstFaceImageUris` fallback as-is. Add a guard in the image widget:
```dart
final url = card.imageUris.normal;
if (url == null || url.isEmpty) {
  // show placeholder — do not pass empty string to CachedNetworkImage
}
```
Never pass an empty string URL to `CachedNetworkImage`; it throws a `FlutterError` in debug mode and produces a broken image in release mode.

---

### 1.2 Rate limiting and HTTP 429

**What goes wrong.**
Scryfall enforces a soft limit of 10 requests per second. Exceeding it returns HTTP 429, which locks the client out for 30 seconds. The current `_mapDioException` in `ScryfallApiClient` does not handle 429 — it falls through to `NetworkFailure`, which shows a generic "Could not reach Scryfall" message. The user has no idea why and may retry immediately, making the lock-out worse.

**Why it matters for a swipe app.**
A user who swipes extremely fast (or who hammers the retry button on an error screen) can reach the limit in a burst. Also, if the Favourites screen and the Discovery screen both make requests simultaneously, it doubles the effective rate.

**Prevention.**
1. Add a 429 case to `_mapDioException` and introduce a `RateLimitedFailure` type. Map it to a UI message like "Slow down — Scryfall is catching its breath. Try again in 30 seconds."
2. Debounce swipe events in the UI layer: ignore a new swipe while the current card is still loading (see section 2.2).
3. Cache the current card. Do not re-fetch on widget rebuild. Riverpod's `keepAlive: true` on the `RandomCardNotifier` prevents unnecessary re-fetches on navigation events.
4. Note: Scryfall's polite recommendation is 50–100 ms between requests. A user swiping at human speed (one card per second at most) will never approach the limit. The concern is only with programmatic retries or concurrent screen requests.

```dart
// In _mapDioException:
if (statusCode == 429) return const RateLimitedFailure();
```

---

### 1.3 Overly restrictive filter combinations returning 404

**What goes wrong.**
`GET /cards/random?q=color:W+rarity:mythic+type:Instant+date>=2024-01-01` is valid syntax (no 422) but may match zero cards (returns 404). Users who set very specific filters will see a "No cards found" error with no guidance on which constraint is too restrictive.

**Why it happens.**
The 404 from `/cards/random` has identical structure to a normal Scryfall 404. The current code maps it to `CardNotFoundFailure` and shows an empty state — correct, but the error message can be more helpful.

**Prevention.**
In the `CardNotFoundFailure` UI handler, display a message like "No cards match your current filters. Try broadening your search." and provide a shortcut button to the filter settings screen. Do not just show a blank screen.

---

### 1.4 `oracle_text` and `flavor_text` absent on tokens and emblems

**What goes wrong.**
Tokens (`layout: token`) and emblems have no rules text box. `oracle_text` will be `null`. The current `MagicCard` model marks it nullable and the comment says "May be null on tokens" — this is handled. The risk is in the presentation layer: any widget that does `card.oracleText!` will throw.

**Prevention.**
Enforce in the UI: only render the oracle text widget when `oracleText != null && oracleText!.isNotEmpty`. Same applies to `flavorText`. The `MagicCard` doc comment is already explicit about this — enforce it in code review.

---

### 1.5 `legalities` map cast failure

**What goes wrong.**
`MagicCard.fromJson` calls `.cast<String, String>()` on the `legalities` map. If Scryfall ever returns a value that is not a `String` (e.g. a future API version uses enums), this will throw `CastError` at runtime, not a graceful failure.

**Prevention.**
Replace the direct cast with a defensive conversion:
```dart
final rawLegalities = json['legalities'] as Map<String, dynamic>? ?? {};
legalities: {
  for (final e in rawLegalities.entries)
    e.key: e.value.toString(), // toString() is safe regardless of value type
},
```

---

## 2. Swipe UX Pitfalls

### 2.1 Gesture conflict with metadata overlay scrolling

**What goes wrong.**
The planned UI has a scrollable metadata overlay (oracle text, flavour text, legalities) dragged up from the bottom of the card. A `GestureDetector` wrapping the full screen for horizontal swipes will compete with the overlay's `ScrollView` for vertical drag events. Flutter's gesture arena will mis-route the gesture: the user tries to scroll the overlay but the card swipes instead (or vice versa).

**Why it happens.**
Flutter's gesture disambiguator defaults to whoever wins the arena first. A horizontal `GestureDetector` and a vertical `ScrollView` at the same position will both enter the arena. The `ScrollView` normally wins vertical drags, but if the swipe recogniser also listens to `onVerticalDragUpdate`, it will steal them.

**Prevention.**
- Do not register `onVerticalDragUpdate` or `onPanUpdate` on the outer swipe `GestureDetector`. Only register `onHorizontalDragStart/Update/End`.
- Wrap the swipe detector around only the card widget itself (not the whole scaffold), so the gesture hit-test area excludes the overlay.
- If the metadata sheet is a `DraggableScrollableSheet`, it handles its own vertical gesture without conflict — prefer this pattern over a custom `ScrollView` inside a full-screen gesture detector.
- Test on both iOS (where iOS native swipe-back competes with horizontal drags in the first ~20pt of the screen) and Android.

---

### 2.2 Race condition: user swipes while card is still loading

**What goes wrong.**
The current `refresh()` method in `RandomCardNotifier`:
```dart
Future<void> refresh() async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(_fetch);
}
```
If the user swipes again while `_fetch` is in-flight, `refresh()` is called a second time. Both calls are now running concurrently. Whichever finishes last will overwrite the state — it is not guaranteed to be the second card. If the first fetch takes longer (e.g. a large card image), the UI may flicker back to the first result after showing the second.

**Prevention.**
Gate the swipe gesture at the UI layer — disable or ignore swipe events when `state` is `AsyncLoading()`:
```dart
final cardState = ref.watch(randomCardNotifierProvider);
GestureDetector(
  onHorizontalDragEnd: cardState.isLoading
      ? null   // disable gesture handling during load
      : (_) => ref.read(randomCardNotifierProvider.notifier).refresh(),
  ...
)
```
Alternatively, track a `_isFetching` boolean inside the notifier and return early from `refresh()` if already in-flight. The UI-layer gate is simpler and more testable.

---

### 2.3 Swipe animation completing into a loading skeleton

**What goes wrong.**
If the swipe animation plays to completion before the network response arrives, the user sees the card fly off the screen and then stares at a blank loading skeleton for 1–2 seconds. This feels broken rather than intentional.

**Prevention.**
Trigger the swipe fly-out animation only after the next card has been pre-fetched, or start the animation in parallel and ensure the loading state shows a full-card skeleton (not just a spinner) that matches the card's aspect ratio. The skeleton should have the same dimensions as the card so there is no layout shift when the image arrives.

Pre-fetch pattern:
1. User initiates swipe (drag begins).
2. Start network request immediately (before drag completes).
3. Complete the fly-out animation.
4. By the time the animation finishes (~250ms), the response is often already in-flight or complete.

---

### 2.4 AnimationController leak in swipe implementation

**What goes wrong.**
When a swipe animation is implemented with `AnimationController` inside a `StatefulWidget` or `ConsumerStatefulWidget`, forgetting to call `controller.dispose()` in `dispose()` leaves the `Ticker` running. Flutter's debug mode will print a warning, but in release mode this is a silent memory and CPU leak that accumulates with every route navigation.

**Prevention.**
- Use `SingleTickerProviderStateMixin` (one controller) or `TickerProviderStateMixin` (multiple).
- Always override `dispose()` and call `_controller.dispose()` before `super.dispose()`.
- Consider using `AnimatedWidget` or `TweenAnimationBuilder` for simpler animations that self-manage lifecycle.
- Flutter's leak tracker (enabled in debug builds) will catch undisposed `AnimationController`s — watch for `FlutterError: "AnimationController was not disposed"` in tests.

---

## 3. Riverpod 3.x Pitfalls

### 3.1 `ref.watch` after an `await` (the "watch-after-await" trap)

**What goes wrong.**
In Riverpod 2.x, calling `ref.watch` after an `await` inside an `AsyncNotifier.build()` method could trigger unexpected provider disposal because the auto-dispose subscription had already been set up in a paused/incomplete state. This was the single most common source of hard-to-reproduce bugs in Riverpod 2.x async providers.

**Riverpod 3.x status.**
Riverpod 3.0 **fixes this** by delaying the removal of subscriptions until the rebuild completes rather than removing them immediately. The pattern is now safe. However, it is still cleaner and more readable to place all `ref.watch` calls at the top of `build()` before any `await`:

```dart
// Preferred: watch before await
@override
Future<MagicCard> build() async {
  final repo = ref.watch(cardRepositoryProvider); // watch before any await
  final result = await repo.getRandomCard();
  ...
}
```

**Risk that remains.**
Developers migrating code from Riverpod 2.x or copying older examples from Stack Overflow/Medium may introduce the pattern and comment it as "known safe." Mark it as acceptable in code review but prefer the pre-await pattern for readability.

---

### 3.2 Calling `ref.invalidateSelf()` vs `refresh()` vs setting `state`

**What goes wrong.**
Three mechanisms exist to reload an `AsyncNotifier` and they have different semantics:

| Method | Effect on current state | Use case |
|---|---|---|
| `state = const AsyncLoading()` then `state = await AsyncValue.guard(...)` | Immediately shows spinner, then data | Current `RandomCardNotifier.refresh()` pattern — correct for "load next card" |
| `ref.invalidateSelf()` | Schedules a rebuild; **current `AsyncData` is preserved** until rebuild completes (`isRefreshing: true`) | Useful for "pull to refresh" patterns that want to show old data while loading |
| `ref.invalidate(provider)` from outside | Same as above but initiated externally | Provider inter-dependency refresh |

**What goes wrong in practice.**
Using `ref.invalidateSelf()` inside `refresh()` for the card swipe gives a brief flash of the old card instead of immediately showing the loading state. The current implementation using `state = const AsyncLoading()` is correct for the swipe use case — do not replace it with `ref.invalidateSelf()`.

**The `isRefreshing` vs `isReloading` distinction (Riverpod 3.x).**
In Riverpod 3.x, `asyncValue.isRefreshing` is `true` when `ref.refresh` is called, while `asyncValue.isReloading` is `true` when the provider is re-built from scratch (e.g. via invalidation). UI code that checks `isLoading` safely catches both. Avoid checking `isRefreshing` or `isReloading` directly unless the distinction is intentional.

---

### 3.3 `keepAlive: true` and the `dioProvider`

**What goes wrong.**
The `dioProvider` is already `@Riverpod(keepAlive: true)`, which is correct — Dio should live for the app's lifetime so that connection pooling is preserved. But if the `randomCardNotifierProvider` (an auto-dispose notifier by default in Riverpod 3.x) is not kept alive, the provider will reset every time the swipe screen is removed from the widget tree and pushed back (e.g. going to Favourites and back). The next `build()` call will fire a new network request immediately on screen return, which costs one API call and shows a spinner even if the card was already loaded.

**Prevention.**
For the `RandomCardNotifier`, consider `@Riverpod(keepAlive: true)` or use `ref.keepAlive()` conditionally inside `build()`. Be explicit about the trade-off: `keepAlive` means the card data is never garbage-collected — acceptable for a single card object.

For `FilterPresetNotifier` and `FavouritesNotifier`, `keepAlive: true` is also appropriate since they manage local Hive state that should persist across navigation events without re-reading the box.

---

### 3.4 `ProviderScope` overrides in widget tests — "number of overrides changed" error

**What goes wrong.**
When running multiple widget tests in the same test file, if a test wraps a widget in `ProviderScope(overrides: [...])` and the number or type of overrides changes between test cases, Riverpod throws:

```
Failed assertion: line XX: 'Tried to change the number of overrides in a ProviderScope'
```

This happens because `ProviderScope` treats its `overrides` list as fixed after the first `pumpWidget` call.

**Prevention.**
Create a fresh `ProviderScope` for every `testWidgets` call — never share a `ProviderScope` across tests. Use `tester.pumpWidget(ProviderScope(...))` at the start of each test, not a shared variable in `setUp`. The golden pattern:

```dart
testWidgets('shows card image when data loads', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        randomCardNotifierProvider.overrideWith(
          () => FakeRandomCardNotifier(stubbedCard),
        ),
      ],
      child: const MaterialApp(home: CardSwipeScreen()),
    ),
  );
  await tester.pump(); // settle async state
  expect(find.byType(CachedNetworkImage), findsOneWidget);
});
```

Use `ProviderContainer.test()` (not `ProviderContainer()`) for pure unit tests — it automatically disposes after each test.

---

## 4. Hive CE Pitfalls

### 4.1 Box not open before widget tree builds

**What goes wrong.**
If Hive boxes are opened asynchronously (via `Hive.openBox<T>('name')`) inside an `initState` or inside a provider's `build()` method, and a widget accesses `Hive.box('name')` synchronously before `openBox` completes, it throws:

```
HiveError: Box not found. Did you forget to call Hive.openBox()?
```

This is especially likely when GoRouter's shell routes eagerly instantiate providers for routes that are not currently visible.

**Prevention.**
Open all boxes in `main()` before `runApp()`, wrapped in `WidgetsFlutterBinding.ensureInitialized()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(FavouriteCardAdapter());
  Hive.registerAdapter(FilterPresetAdapter());
  await Hive.openBox<FavouriteCard>('favourites');
  await Hive.openBox<FilterPreset>('filter_presets');
  runApp(const ProviderScope(child: RandomMagicApp()));
}
```

Repositories then call `Hive.box('favourites')` (synchronous, no `await`) and the box is guaranteed open.

---

### 4.2 Type adapter registration order

**What goes wrong.**
Hive identifies types by `typeId` (an integer). If two adapters share the same `typeId`, the second registration silently overwrites the first. This produces `HiveError: Unknown typeId: N` or data corruption when reading stored objects that were written with the first adapter's schema.

**Prevention.**
Maintain a central comment block or constant file listing all `typeId` assignments:

```dart
// Type IDs — never reuse a retired ID
// 0: FavouriteCardAdapter
// 1: FilterPresetAdapter
// 2–9: reserved for future models
```

In Hive CE 2.8+, the `@GenerateAdapters` annotation approach can reduce the chance of manual ID collision. If using the annotation approach, still document IDs explicitly.

Do not call `Hive.registerAdapter` inside a provider's factory or inside widget `build` — only call it once in `main()`. Guard against double-registration in test code with `if (!Hive.isAdapterRegistered(adapterId))`.

---

### 4.3 Adding a new field to a Hive model without migration

**What goes wrong.**
Hive CE stores data in a binary format keyed by `HiveField` indices. If you add a new field to `FavouriteCard` or `FilterPreset`, regenerate the adapter, and deploy — devices that already have saved data will read the old binary and return `null` for the new field (if it defaults to null) or crash (if the field is non-nullable and the adapter tries to read it from an empty slot).

The crash profile is: works fine on fresh installs, crashes on upgrade for existing users.

**Prevention.**
- New fields must be nullable (or have a `@HiveField(N, defaultValue: ...)` if using Hive CE's `GenerateAdapters`).
- Never remove or reorder existing `HiveField` indices — only append new ones.
- Never change the type of an existing `HiveField` index.
- Document every schema change in a migration note adjacent to the model file.
- If a breaking change is unavoidable (renaming/removing a field), implement a migration: open the old box, read all entries, write them to a new box with the new schema, delete the old box.

---

### 4.4 "Box already open" exception in tests

**What goes wrong.**
Hive maintains a global singleton. If two tests call `Hive.openBox('favourites')` without closing the box between them, the second call throws `HiveError: The box "favourites" is already open`.

**Prevention.**
In each test `setUp`, initialize Hive with a temporary directory (available via the `path` package and Dart's `Directory.systemTemp`), and in `tearDown` call `Hive.close()` or `await box.deleteFromDisk()`:

```dart
setUp(() async {
  final dir = await Directory.systemTemp.createTemp();
  Hive.init(dir.path);
  Hive.registerAdapter(FavouriteCardAdapter(), override: true);
});

tearDown(() async {
  await Hive.close();
});
```

Note: `registerAdapter` may need `override: true` in tests to allow re-registration between test runs. Hive CE's `registerAdapters()` extension method also supports this pattern.

---

### 4.5 `LazyBox` vs `Box` — wrong type for repository calls

**What goes wrong.**
`Hive.openLazyBox<T>()` returns values lazily (individual reads are async). `Hive.openBox<T>()` loads everything into memory eagerly. If the favourites box is opened as `LazyBox` but the repository calls `box.values` (a synchronous getter on `Box`), it will fail at runtime because `LazyBox` does not expose `values` synchronously.

**Prevention.**
For a favourites collection that will never exceed a few hundred items, use `Box<T>` (eager). Document the choice in the repository class. Only consider `LazyBox` if the box could grow to thousands of entries and memory pressure is a concern.

---

## 5. `cached_network_image` Pitfalls

### 5.1 Null or empty URL causes crash or broken image

**What goes wrong.**
Passing `null` or an empty string as the URL argument to `CachedNetworkImage` either throws a `FlutterError` in debug mode or silently shows a broken-image icon in release mode (depending on the package version). Since `CardImageUris.normal` is nullable, this will happen for any card whose image URL could not be resolved (see section 1.1).

**Prevention.**
Always guard before constructing the widget:
```dart
final url = card.imageUris.normal;
if (url == null || url.isEmpty) {
  return const CardImagePlaceholder(); // your fallback widget
}
return CachedNetworkImage(imageUrl: url, ...);
```

---

### 5.2 Memory pressure from decoded full-resolution images

**What goes wrong.**
Scryfall's `normal` image is ~488×680px JPEG — manageable. But if the app ever switches to `large` (~672×936px) or `png` (lossless), and `CachedNetworkImage` decodes the image at full resolution, Flutter retains the decoded bitmap in memory. In a swipe scenario where many cards are loaded in rapid succession, the image cache grows without bound until the OS issues a memory pressure event and kills the app.

**Specifics.**
- A 672×936 JPEG decoded to RGBA is ~2.5MB per card.
- Flutter's default `ImageCache` holds 100 images (or 100MB, whichever comes first).
- After ~40 swipes with large images, the cache is full. Old entries are evicted, but if a previous card was retained by another widget, eviction cannot proceed, and memory grows.

**Prevention.**
- Use `memCacheWidth` and `memCacheHeight` on `CachedNetworkImage` to cap decode resolution to the display size:
  ```dart
  CachedNetworkImage(
    imageUrl: url,
    memCacheWidth: (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).toInt(),
    // height proportionally — or leave null to let the package calculate it
  )
  ```
- Stick with the `normal` size (not `png` or `large`) for the swipe screen.
- Reduce `ImageCache` size proactively if profiling shows pressure: `PaintingBinding.instance.imageCache.maximumSize = 50`.

---

### 5.3 `cached_network_image` maintenance status (as of 2025)

**What goes wrong.**
The original `cached_network_image` package has been effectively unmaintained since mid-2024, with 300+ open issues including memory leak reports and scroll-performance bugs (the cache manager could accumulate 600–700 objects instead of the intended 200 cap).

**Alternatives.**
- `cached_network_image_ce` (community edition): re-engineers the caching layer and replaces the `sqflite` dependency with `hive_ce` — a strong fit for this project since Hive CE is already in the stack. Actively maintained.
- `fast_cached_network_image`: no native dependencies, pure Dart cache.

**Recommendation.**
Evaluate `cached_network_image_ce` before committing to the original package. It has the same widget API, so migration cost is minimal (change the import, update `pubspec.yaml`). The `hive_ce` backing is particularly advantageous because it eliminates a second database dependency.

---

### 5.4 Placeholder sizing causing layout shift

**What goes wrong.**
If the `placeholder` widget in `CachedNetworkImage` does not have the same dimensions as the card image, the layout will shift (jump) when the image loads, creating a jarring visual effect. On a full-screen card viewer this is very noticeable.

**Prevention.**
Wrap `CachedNetworkImage` in an `AspectRatio` widget set to the card's standard aspect ratio (63mm × 88mm ≈ 0.716), or use `fit: BoxFit.cover` with a fixed-size container. The placeholder widget should fill the same space:
```dart
AspectRatio(
  aspectRatio: 63 / 88,
  child: CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    placeholder: (context, url) => const CardSkeletonPlaceholder(),
    errorWidget: (context, url, error) => const CardErrorWidget(),
  ),
)
```

---

## 6. Testing Pitfalls

### 6.1 Mocking Riverpod providers in widget tests — using real providers by accident

**What goes wrong.**
A test that does not override the `randomCardNotifierProvider` will use the real `CardRepositoryImpl`, which calls the real `ScryfallApiClient`, which makes real HTTP requests. This makes tests slow, non-deterministic, and dependent on network availability. In CI, these tests will flake or fail entirely.

**Prevention.**
Always override all providers that touch the network or local storage in widget and integration tests:

```dart
// In test/fixtures/fake_card_repository.dart
class FakeCardRepository implements CardRepository {
  FakeCardRepository(this._result);
  final Result<MagicCard> _result;
  @override
  Future<Result<MagicCard>> getRandomCard({String? query}) async => _result;
}

// In the test
ProviderScope(
  overrides: [
    cardRepositoryProvider.overrideWithValue(
      FakeCardRepository(Success(fakeCard)),
    ),
  ],
  child: const CardSwipeScreen(),
)
```

Use `mockito` or `mocktail` for complex interaction verification; use simple fakes (hand-written classes implementing the interface) for state-based tests.

---

### 6.2 Hive not initialized in unit tests

**What goes wrong.**
Any test that exercises a repository which calls `Hive.box(...)` synchronously will throw `HiveError: Box not found` because `Hive.initFlutter()` has not been called and the box is not open in the test environment.

**Prevention.**
Two approaches:

**Option A — Mock Hive entirely (preferred for unit tests).**
Abstract the box behind a repository interface. Test the repository logic with a mock or fake implementation of the box. No Hive initialization needed.

**Option B — Initialize Hive with a temp directory (integration/widget tests).**
```dart
setUp(() async {
  // Use a real but temporary Hive instance
  final tempDir = await Directory.systemTemp.createTemp('hive_test_');
  Hive.init(tempDir.path);
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(FavouriteCardAdapter());
  }
  await Hive.openBox<FavouriteCard>('favourites');
});

tearDown(() async {
  await Hive.deleteBoxFromDisk('favourites');
  await Hive.close();
});
```

Never call `Hive.initFlutter()` in tests — it calls `path_provider` which requires a real platform channel. Use `Hive.init(directory)` with a temp path instead.

---

### 6.3 Testing `AsyncNotifier` state sequences

**What goes wrong.**
Tests that `pump()` once after triggering `refresh()` will see `AsyncLoading` state, not `AsyncData`. Calling `pump()` again or `pumpAndSettle()` is needed to let the future complete. Tests that do not account for the loading state will either see the wrong widget or get assertion failures.

**Prevention.**
Test all three states explicitly:

```dart
// Initial build — triggers first fetch
await tester.pumpWidget(scope);
// After pumpWidget: state is AsyncLoading (build() has not completed)
expect(find.byType(CircularProgressIndicator), findsOneWidget);

// Settle the future
await tester.pumpAndSettle();
// Now state is AsyncData
expect(find.text(fakeCard.name), findsOneWidget);

// Trigger refresh (swipe)
ref.read(randomCardNotifierProvider.notifier).refresh();
await tester.pump(); // one frame — shows loading
expect(find.byType(CircularProgressIndicator), findsOneWidget);
await tester.pumpAndSettle();
expect(find.text(nextFakeCard.name), findsOneWidget);
```

---

### 6.4 GoRouter and `pumpWidget` — missing `MaterialApp.router`

**What goes wrong.**
Testing widgets that use `GoRouter.of(context)` (for navigation on swipe, for example) without wrapping in a router-aware `MaterialApp` causes:
```
Could not find a router delegate...
```

**Prevention.**
In widget tests for screens that navigate, provide a minimal `GoRouter` pointing to the screen under test:
```dart
final testRouter = GoRouter(routes: [
  GoRoute(path: '/', builder: (_, __) => const CardSwipeScreen()),
]);
await tester.pumpWidget(
  ProviderScope(
    overrides: [...],
    child: MaterialApp.router(routerConfig: testRouter),
  ),
);
```

Screens that only accept route parameters via the constructor (and use `context.go(...)` for navigation) can be tested without GoRouter by stubbing the navigation call — prefer this simpler approach where possible.

---

## 7. GoRouter-Specific Pitfalls

### 7.1 iOS swipe-back gesture conflict with ShellRoutes

**What goes wrong.**
GoRouter's `ShellRoute` (used for bottom-navigation tab layouts) has a known issue where iOS's native swipe-back gesture pops the entire shell instead of only the active sub-route. This results in the user being taken from a card detail screen all the way back past the home tab.

**Status.**
This was a tracked Flutter issue (`#120353`). Verify the fix is present in GoRouter 17.x before shipping. If not resolved: disable the iOS swipe-back gesture on routes inside a shell by wrapping route content in `PopScope(canPop: false)` and using `onPopInvokedWithResult` to drive GoRouter manually.

**For this app specifically.**
The main swipe gesture is horizontal and will not conflict with the iOS swipe-back (which is a right-edge drag starting from the very edge of the screen). The risk only appears if card detail or filter settings screens are nested inside a `ShellRoute`.

---

### 7.2 Android predictive back and `PopScope`

**What goes wrong.**
Android 14+ shows a predictive back animation when the user swipes from the left edge. If a screen uses `PopScope(canPop: false)` to intercept back events (e.g. to show a "discard changes" dialog on the filter screen), the predictive animation may play even though the pop will be cancelled, leading to visual inconsistency.

**Prevention.**
Use `onPopInvokedWithResult` in `PopScope` to check the action and call `context.go(...)` explicitly when the back action is approved. See the GoRouter documentation for the 2025-updated PopScope integration pattern.

---

## Appendix: Confidence Summary

| Area | Confidence | Primary Sources |
|---|---|---|
| Scryfall layout / image_uris rules | HIGH | Official Scryfall API docs (scryfall.com/docs/api/layouts) |
| Scryfall rate limiting | HIGH | Official Scryfall rate-limits doc |
| Riverpod 3.x watch-after-await fix | HIGH | Riverpod 3.0 changelog (pub.dev/packages/riverpod/changelog) |
| Riverpod 3.x invalidateSelf vs refresh | HIGH | Riverpod official docs (riverpod.dev/docs/whats_new) |
| Hive CE initialization / adapter order | MEDIUM | Official Hive docs + GitHub issues |
| Hive CE field migration | MEDIUM | GitHub issue #781 (isar/hive) + community articles |
| cached_network_image memory pressure | MEDIUM | GitHub issue #429 + community benchmarks |
| cached_network_image maintenance status | MEDIUM | GitHub repo observation (community report) |
| Swipe gesture / ScrollView conflict | MEDIUM | Flutter gesture docs + GitHub issue #24048 |
| GoRouter ShellRoute iOS conflict | MEDIUM | GitHub issue #120353 |
| Testing patterns | HIGH | Riverpod official testing docs |
