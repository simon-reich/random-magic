# Architecture Research: Random Magic — Remaining Features

**Researched:** 2026-04-10
**Riverpod version in lock:** flutter_riverpod 3.3.1 / riverpod_annotation 4.0.2 / riverpod_generator 4.0.3
**Hive CE version in lock:** hive_ce 2.19.3 / hive_ce_flutter 2.3.4
**Overall confidence:** HIGH (all patterns verified against generated code already in repo + Riverpod 3 official docs)

---

## 1. Passing filter state to `RandomCardNotifier`

### Decision: watch `activeFilterQueryProvider` inside `build()`

The cleanest wiring is a dedicated provider that owns the "current Scryfall query string" and is watched inside the notifier's `build()`. When filter settings are saved, that provider updates, the notifier's `build()` re-runs, and a new card is fetched automatically — no manual invalidation needed.

```dart
// features/filters/presentation/providers.dart

/// Holds the Scryfall query string derived from the active FilterPreset.
/// Null means no filter is active (unrestricted random card).
@Riverpod(keepAlive: true)
class ActiveFilterQuery extends _$ActiveFilterQuery {
  @override
  String? build() => null; // start with no filter

  void setQuery(String? query) => state = query;
}
```

```dart
// features/card_discovery/presentation/providers.dart

@riverpod
class RandomCardNotifier extends _$RandomCardNotifier {
  @override
  Future<MagicCard> build() {
    // Watching this means: whenever the filter changes, build() re-runs,
    // which fetches a new random card with the updated query.
    final query = ref.watch(activeFilterQueryProvider);
    return _fetch(query: query);
  }

  Future<void> refresh() async {
    final query = ref.read(activeFilterQueryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(query: query));
  }

  Future<MagicCard> _fetch({String? query}) async {
    final result = await ref.read(cardRepositoryProvider).getRandomCard(query: query);
    return switch (result) {
      Success(:final value) => value,
      Failure(:final error) => throw error,
    };
  }
}
```

**Why this beats the alternatives:**

- **Provider family (passing query as constructor arg):** In Riverpod 3 the `FamilyAsyncNotifier` was removed. Families now require a constructor arg — `RandomCardNotifier(this.query)` — which means the widget calling `.refresh()` must pass the query itself. That couples the swipe screen to the filter query at the call site. The `ref.watch` approach keeps the swipe screen ignorant of filter internals.
- **`.select()` to filter updates:** Irrelevant here — `ActiveFilterQuery` is a plain `String?`, not a large object. No selector optimisation needed.
- **`ref.listen` inside notifier:** Works, but then you need to manually call `refresh()` inside the listener callback. The `ref.watch`-in-`build()` approach is declarative and idiomatic — re-building `build()` is literally what Riverpod designed the notifier rebuild for.

**Important: `keepAlive: true` on `ActiveFilterQuery`**

`RandomCardNotifier` is `autoDispose` (the default). When it disposes, Riverpod would also dispose `ActiveFilterQuery` unless it is `keepAlive: true`. Mark it keepAlive so the selected filter persists across navigation (tab switches etc.) and so `RandomCardNotifier` can re-read it on rebuild without the query being lost.

### Using `ref.read` vs `ref.watch` in `refresh()`

Inside `refresh()` (a mutation method, not `build()`), use `ref.read` to get the current query — not `ref.watch`. `ref.watch` is only safe inside `build()`. This is already how the current `_fetch` method reads `cardRepositoryProvider`.

---

## 2. `ref.invalidateSelf()` vs manual state assignment for refresh

The current implementation uses the correct pattern for on-demand refresh:

```dart
Future<void> refresh() async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(_fetch);
}
```

This is intentionally **not** `ref.invalidateSelf()`. Here is why:

- `ref.invalidateSelf()` schedules a rebuild on the next frame (async). The state will transiently remain the old `AsyncData` until the rebuild executes. This means there is a frame where the card image is still visible — not what you want when swiping.
- Setting `state = const AsyncLoading()` synchronously puts the UI into loading/shimmer immediately on the swipe gesture, then the `AsyncValue.guard()` sets the final state. This is the explicit-state-machine pattern and it is correct here.

`ref.invalidateSelf()` is the right tool when you want to re-run `build()` reactively (e.g. after a mutation in another feature invalidates a dependency) — but for a user-initiated "next card" action, manual state assignment is more predictable.

**One gotcha with Riverpod 3:** setting `state` inside a notifier method after an async gap is fine in Riverpod 3. The "cannot use ref after async gap" issue (GitHub #4096) applies to `ref.*` calls after an `await`, not to `this.state`. Your `_fetch` already uses `ref.read` (not `ref.watch`) before the await, which is correct.

---

## 3. Hive CE + Riverpod integration

### Box lifecycle: open once at app startup, never close during session

Boxes are cheap to keep open. The recommended pattern is to open all boxes in `main()` before `runApp`, not in a `FutureProvider`. This sidesteps a class of bugs where providers try to read a box before it is opened.

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register adapters before opening boxes
  Hive.registerAdapter(FilterPresetAdapter());
  // MagicCard stored as favourite — register its adapter here too

  await Future.wait([
    Hive.openBox<FilterPreset>('filter_presets'),
    Hive.openBox<MagicCard>('favourites'),
  ]);

  runApp(const ProviderScope(child: RandomMagicApp()));
}
```

Then Riverpod providers access boxes synchronously:

```dart
@Riverpod(keepAlive: true)
class FavouritesNotifier extends _$FavouritesNotifier {
  Box<MagicCard> get _box => Hive.box<MagicCard>('favourites');

  @override
  List<MagicCard> build() => _box.values.toList();

  Future<void> add(MagicCard card) async {
    await _box.put(card.id, card);
    state = _box.values.toList();
  }

  Future<void> remove(String cardId) async {
    await _box.delete(cardId);
    state = _box.values.toList();
  }

  bool isFavourite(String cardId) => _box.containsKey(cardId);
}
```

**Why `Notifier<List<MagicCard>>` not `StreamNotifier`:**

`Box.watch()` returns a `Stream<BoxEvent>` that only emits changes (no initial value). Wiring this to a `StreamNotifier` means you must fetch the initial list separately and merge it with the stream — more boilerplate than simply reading `_box.values` after every mutation. Since all writes go through the notifier, you control exactly when state updates, so a reactive stream adds no value.

### Hive CE adapter for `MagicCard`

`MagicCard` is an immutable domain model. Rather than adding a Hive type adapter to the shared model (which would violate the "shared models are infrastructure-free" principle), create a `FavouriteCard` wrapper in `features/favourites/domain/` that holds the fields you actually need to display in the favourites list. This also lets you store a `savedAt` timestamp cheaply.

```dart
// features/favourites/domain/favourite_card.dart
@HiveType(typeId: 1)
class FavouriteCard extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String name;
  @HiveField(2) final String? imageUriNormal;
  @HiveField(3) final String rarity;
  @HiveField(4) final String setCode;
  @HiveField(5) final DateTime savedAt;
  // ... other display fields
}
```

`FavouriteCard.fromMagicCard(card)` factory handles the mapping. The full `MagicCard` is never persisted — only display fields. This keeps adapter maintenance low and avoids having to version a complex nested object graph.

### `FilterPreset` adapter

```dart
// features/filters/domain/filter_preset.dart
@HiveType(typeId: 0)
class FilterPreset extends HiveObject {
  @HiveField(0) String name;
  @HiveField(1) List<String> colors;    // e.g. ['R', 'G']
  @HiveField(2) String? type;
  @HiveField(3) String? rarity;
  @HiveField(4) String? dateFrom;       // ISO date string
  @HiveField(5) String? dateTo;
}
```

`typeId: 0` for `FilterPreset`, `typeId: 1` for `FavouriteCard`. Reserve a block (0–9 for this app). Document the type ID table in a comment at the top of each adapter file. **Never reuse a typeId after deleting a type** — Hive will silently misread old data.

---

## 4. Filter preset Riverpod provider

```dart
@Riverpod(keepAlive: true)
class FilterPresetsNotifier extends _$FilterPresetsNotifier {
  Box<FilterPreset> get _box => Hive.box<FilterPreset>('filter_presets');

  @override
  List<FilterPreset> build() => _box.values.toList();

  Future<void> save(FilterPreset preset) async {
    // Use preset.name as key for upsert semantics (same name = overwrite)
    await _box.put(preset.name, preset);
    state = _box.values.toList();
  }

  Future<void> delete(String name) async {
    await _box.delete(name);
    state = _box.values.toList();
  }
}
```

When the user selects a preset to apply, the `FilterSettingsScreen` calls:

```dart
ref.read(activeFilterQueryProvider.notifier).setQuery(
  ScryfallQueryBuilder.fromPreset(preset),
);
context.go(AppRoutes.discovery);
```

`RandomCardNotifier` picks it up automatically because it watches `activeFilterQueryProvider`.

### `ScryfallQueryBuilder`

Pure function, no provider needed. Static class in `features/filters/data/`:

```dart
abstract final class ScryfallQueryBuilder {
  static String? fromPreset(FilterPreset preset) {
    final parts = <String>[];

    if (preset.colors.isNotEmpty) {
      // Scryfall: "color:R OR color:G" for multi-color
      parts.add(preset.colors.map((c) => 'color:$c').join(' OR '));
    }
    if (preset.type != null) parts.add('type:${preset.type}');
    if (preset.rarity != null) parts.add('rarity:${preset.rarity}');
    if (preset.dateFrom != null) parts.add('date>=${preset.dateFrom}');
    if (preset.dateTo != null) parts.add('date<=${preset.dateTo}');

    return parts.isEmpty ? null : parts.join(' ');
  }
}
```

Returns `null` for an empty preset so `ScryfallApiClient` omits the `q` param entirely (unrestricted random).

---

## 5. CardSwipeScreen implementation pattern

### Shimmer while loading

Use the `shimmer` package (already a common dependency choice). The shimmer widget wraps a placeholder that matches the card's layout:

```dart
state.when(
  loading: () => const _CardShimmer(),
  data: (card) => _CardDisplay(card: card),
  error: (err, _) => _errorWidget(err),
);
```

`_CardShimmer` is a `Container` with the same dimensions as the card image, wrapped in `Shimmer.fromColors`. Match height/width to the card aspect ratio (488:680 → ~0.718).

### Three distinct error states

Pattern-match on the thrown `AppFailure` type in the `error` callback:

```dart
error: (err, _) => switch (err) {
  CardNotFoundFailure() => _NoCardsState(onRetry: _refresh),
  InvalidQueryFailure() => _InvalidFilterState(onResetFilters: _resetFilters),
  NetworkFailure()      => _NetworkErrorState(onRetry: _refresh),
  _ => _NetworkErrorState(onRetry: _refresh), // defensive fallback
},
```

`_resetFilters` calls `ref.read(activeFilterQueryProvider.notifier).setQuery(null)`.

### Swipe gesture to fetch next card

`GestureDetector` with `onHorizontalDragEnd` checking velocity. No third-party swipe library needed for this use case:

```dart
GestureDetector(
  onHorizontalDragEnd: (details) {
    // threshold: 300 logical px/s to distinguish swipe from drag
    if (details.primaryVelocity!.abs() > 300) {
      ref.read(randomCardProvider.notifier).refresh();
    }
  },
  child: AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    child: KeyedSubtree(
      key: ValueKey(card.id), // forces AnimatedSwitcher to animate on card change
      child: _CardDisplay(card: card),
    ),
  ),
)
```

`AnimatedSwitcher` with a `ValueKey(card.id)` gives a crossfade between cards with zero extra state.

---

## 6. App lifecycle and Hive CE

**Do not close boxes on pause.** The common advice to close on `AppLifecycleState.paused` is overcautious and causes the `HiveError: Box has already been closed` crash if the OS resumes the app quickly. The correct behaviour:

- **Open:** once in `main()`, before `runApp`
- **During session:** leave open — Hive flushes writes lazily and safely
- **On app exit:** `Hive.close()` is called automatically by the OS process termination; you can also call it in `AppLifecycleState.detached` if you want explicit cleanup

If you want belt-and-suspenders safety on resume, check `Hive.isBoxOpen('favourites')` before accessing the box inside a notifier, and re-open if needed. In practice this should never be false during a normal session.

```dart
// Optional defensive accessor — only needed if you ever close boxes manually
Box<T> _safeBox<T>(String name) {
  if (!Hive.isBoxOpen(name)) {
    throw StateError('Box "$name" is not open — was it opened in main()?');
  }
  return Hive.box<T>(name);
}
```

---

## 7. Duplicate preset name handling

`FilterPresetsNotifier.save()` uses the preset name as the box key. This means saving a preset with the same name silently overwrites the previous one — which is the desired upsert behaviour for editing a preset.

To prevent accidental overwrite when creating (not editing):

```dart
Future<Result<void>> saveNew(FilterPreset preset) async {
  if (_box.containsKey(preset.name)) {
    return const Failure(DuplicatePresetFailure());
  }
  await _box.put(preset.name, preset);
  state = _box.values.toList();
  return const Success(null);
}
```

Add `DuplicatePresetFailure` to `shared/failures.dart`.

---

## 8. Cross-feature provider dependency map

```
ActiveFilterQuery (keepAlive)
    ↑ written by: FilterSettingsScreen / FilterPresetsNotifier
    ↓ watched by: RandomCardNotifier.build()

RandomCardNotifier (autoDispose)
    → reads: CardRepository → ScryfallApiClient → Dio

FilterPresetsNotifier (keepAlive)
    → reads/writes: Hive box 'filter_presets'

FavouritesNotifier (keepAlive)
    → reads/writes: Hive box 'favourites'
    ← reads by: CardSwipeScreen (isFavourite check), FavouritesScreen
```

`CardSwipeScreen` imports `activeFilterQueryProvider` and `randomCardProvider`.
`FilterSettingsScreen` imports `activeFilterQueryProvider` and `filterPresetsNotifierProvider`.
`FavouritesScreen` imports `favouritesNotifierProvider`.

No cross-feature data-layer imports — all wiring goes through shared providers. This matches the isolation rule in CLAUDE.md.

---

## 9. Testing implications

- `RandomCardNotifier`: override `cardRepositoryProvider` + `activeFilterQueryProvider` in `ProviderContainer`. The filter integration can be tested by setting the query provider and verifying `getRandomCard` is called with the right query.
- `FilterPresetsNotifier` / `FavouritesNotifier`: inject an in-memory Hive box. `Hive.init()` with a temp directory works in unit tests without Flutter bindings. Alternatively, use a mock repository pattern (wrap Hive behind an interface).
- `ScryfallQueryBuilder`: pure function, plain unit tests, no Riverpod involved.

---

## Summary of key decisions

| Question | Answer |
|---|---|
| How does filter reach notifier? | `ref.watch(activeFilterQueryProvider)` inside `build()` — reactive, no manual invalidation |
| `invalidateSelf()` vs manual state? | Manual `state = AsyncLoading()` for refresh — immediate feedback, predictable |
| When to open Hive boxes? | Once in `main()` before `runApp`, never close during session |
| Reactive Hive with Riverpod? | Write-through notifier — update `state` after every `_box.*` call, no stream needed |
| Store full `MagicCard` in Hive? | No — use a `FavouriteCard` projection with only display fields |
| Duplicate preset names? | Use name as box key (upsert on edit); guard with `containsKey` on create |
| Swipe gesture library? | `GestureDetector.onHorizontalDragEnd` — no package needed |
| Filter query when no filters set? | `null` — `ScryfallQueryBuilder.fromPreset` returns null, `ScryfallApiClient` omits `q` param |
