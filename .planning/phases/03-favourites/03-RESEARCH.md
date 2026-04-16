# Phase 3: Favourites — Research

**Researched:** 2026-04-16
**Domain:** Flutter / Hive CE / Riverpod 3.x / flutter_card_swiper 7.x
**Confidence:** HIGH — all findings verified against live codebase and resolved pubspec.lock

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Save Action (FAV-01)**
- D-01: Bookmark button as overlay on the card, bottom-right corner, `Positioned` inside `Stack` in `_CardFaceWidget`. Icon: `Icons.favorite_border` when not saved.
- D-02: Swipe-up also saves — `flutter_card_swiper` top-direction triggers the same save action as the button tap.
- D-03: On save, show a Snackbar ("Saved to Favourites"). No modal, no blocking UI.

**Already-Saved Indicator**
- D-04: When the displayed card is already in Favourites, icon shows filled (`Icons.favorite`). Tapping the filled icon does nothing. Requires `FavouritesNotifier.isFavourite(cardId)` watched per card.

**Favourites Grid (FAV-02)**
- D-05: 3-column `SliverGrid` with `artCrop` image URLs, ~2px gaps. (`GridView.builder` or `SliverGrid` inside `CustomScrollView`.)
- D-06: Long-press on any grid card enters multi-select mode. Selected cards show a checkmark overlay. A top app bar appears with a delete button and "X selected" count.
- D-07: Multi-select mode is exited via Back-Button or second long-press (no timeout). Exiting without deleting deselects all.

**Delete (FAV-04)**
- D-08: Delete in `FavouriteSwipeScreen` is immediate — card removed from Hive on tap. A Snackbar with Undo (~3 seconds) allows reverting.
- D-09: Batch delete from multi-select grid mode uses the same immediate + Undo Snackbar. Single undo restores ALL cards deleted in that batch.

**Favourites Filter (FAV-07)**
- D-10: Filter state is in-memory only — resets when the user leaves the Favourites tab. No Hive persistence. `autoDispose` acceptable.
- D-11: Filter applied client-side against full `FavouritesNotifier` list. Bottom sheet with colour/type/rarity chips (same chip style as Phase 2).

**Data Model**
- D-12: `FavouriteCard` is a projection — persist only display/filter fields. Fields: `id`, `name`, `typeLine`, `rarity`, `setCode`, `artCropUrl`, `normalImageUrl`, `manaCost`, `savedAt`, `colors`.
- D-13: `FavouriteCardAdapter` uses typeId: 1. Box name: `'favourites'`.

### Claude's Discretion

- Navigation from grid to `FavouriteSwipeScreen`: load ALL favourites, seek to card matching passed ID.
- Sort order in grid: newest-saved first (use `savedAt` descending).
- `FavouritesNotifier` marked `keepAlive: true` — consistent with Phase 1/2 notifier pattern.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FAV-01 | User can save the current card to Favourites (swipe up or via a button) | Swipe-up via `CardSwiperDirection.top` in `onSwipe`; bookmark button via `Positioned` overlay in `_CardFaceWidget` Stack; write-through to Hive via `FavouritesNotifier.add()` |
| FAV-02 | The Favourites screen shows a 3-column grid of saved cards using `artCrop` images | `SliverGrid.count(crossAxisCount: 3)` + `CachedNetworkImage` for `artCropUrl`; `CustomScrollView` supports multi-select app bar transition |
| FAV-03 | Tapping a card in the grid opens a swipe-through view starting at that card | Route `/favourites/:id` already wired; `FavouriteSwipeScreen` receives `favouriteId`; seek to index by matching ID in sorted list |
| FAV-04 | User can remove a card from Favourites via delete button in swipe view | Immediate Hive delete via `FavouritesNotifier.remove(id)` + Snackbar with Undo; re-insert on undo via `FavouritesNotifier.add()` |
| FAV-05 | Favourites are persisted locally via Hive CE and survive app restarts | Hive CE box `'favourites'` opened in `main.dart` before `runApp`; `FavouriteCardAdapter` typeId: 1; write-through pattern |
| FAV-06 | An empty state is shown in the grid when no cards are saved | Guard on `FavouritesNotifier` state list being empty; render empty state widget consistent with Phase 1/2 empty states |
| FAV-07 | User can filter the Favourites grid by colour, type, and rarity (via a bottom sheet) | `autoDispose` provider for filter state; client-side filter applied to `_box.values`; reuse Phase 2 `FilterChip` + `Wrap` chip pattern |
</phase_requirements>

---

## Summary

Phase 3 builds on fully established infrastructure from Phases 1 and 2. The Hive CE adapter pattern (typeId: 0 in `filter_preset.dart`) provides an exact template for `FavouriteCardAdapter` (typeId: 1). The `FilterPresetsNotifier` write-through pattern is the model for `FavouritesNotifier`. The `CardSwipeScreen` already contains the `Stack` + `Positioned` overlay pattern and `CardSwiper.onSwipe` callback — the bookmark button and swipe-up save slot in cleanly.

The main novelty in this phase is: (1) multi-select grid mode with a dynamic app bar, (2) the Undo Snackbar delete pattern, and (3) client-side filtering of a local Hive collection. All three have direct Flutter/Riverpod solutions without custom infrastructure.

The route `/favourites/:id` and both placeholder screens already exist in the codebase. The phase is almost entirely replacement of placeholder content with real implementations plus one new domain file and one new data file.

**Primary recommendation:** Follow the `FilterPresetsNotifier` pattern exactly for `FavouritesNotifier`. Use `ConsumerStatefulWidget` for `FavouritesScreen` to manage multi-select local state alongside provider state.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| hive_ce | 2.19.3 | Persist `FavouriteCard` objects | Already in use (Phase 2); box lifecycle established in `main.dart` |
| hive_ce_flutter | 2.3.4 | Flutter `Hive.initFlutter()` adapter | Already in use |
| flutter_riverpod | 3.3.1 | State management for `FavouritesNotifier` | Project-standard; `keepAlive: true` pattern established |
| riverpod_annotation + riverpod_generator | 4.0.2 / 4.0.3 | Code-gen for `@Riverpod` providers | Already used in all existing providers via `part 'providers.g.dart'` |
| flutter_card_swiper | 7.2.0 | Swipe-through view in `FavouriteSwipeScreen` | Already used in `CardSwipeScreen`; reuse `CardSwiperDirection.top` |
| cached_network_image | 3.4.1 | `artCrop` thumbnails in grid + normal images in swipe view | Already a dependency; used in `_CardFaceWidget` |

[VERIFIED: pubspec.lock]

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| go_router | 17.2.0 | `/favourites/:id` navigation already wired | Route params already defined in `app_router.dart` |
| flutter_svg | 2.2.4 | MTG colour symbol icons (if used in filter bottom sheet) | Already a dependency from Phase 2 filter screen |

[VERIFIED: pubspec.lock]

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-written `FavouriteCardAdapter` | `hive_ce_generator` code-gen | Phase 2 established hand-written pattern; changing generator approach mid-project would require source_gen setup; not worthwhile |
| `autoDispose` for favourites filter provider | `keepAlive: false` (same thing) | `autoDispose` is more explicit — use `@riverpod` default (autoDispose is the default in Riverpod 3.x for non-keepAlive providers) |

**Installation:** No new packages needed — all dependencies already in `pubspec.yaml`. [VERIFIED: pubspec.yaml]

---

## Architecture Patterns

### Recommended Project Structure
```
lib/features/favourites/
├── data/
│   └── favourites_repository.dart      # FavouritesRepository (Hive write-through)
├── domain/
│   └── favourite_card.dart             # FavouriteCard model + FavouriteCardAdapter (typeId: 1)
└── presentation/
    ├── favourites_screen.dart          # Replace placeholder — 3-column grid
    ├── favourite_swipe_screen.dart     # Replace placeholder — swipe-through view
    └── providers.dart                  # FavouritesNotifier, favouritesFilterProvider
```

[VERIFIED: existing .gitkeep files confirm data/, domain/, presentation/ subdirs exist]

### Pattern 1: FavouriteCard Domain Model + Hive Adapter

**What:** Plain Dart class (no Hive annotations on fields) with a hand-written `TypeAdapter<FavouriteCard>` — exact same pattern as `FilterPreset` / `FilterPresetAdapter`.

**When to use:** Always for Hive CE in this project — the hand-written adapter avoids source_gen conflicts and is already established as project convention.

**Key serialisation note:** `DateTime savedAt` must be stored as ISO-8601 string to avoid timezone issues — consistent with how `FilterPresetAdapter` handles dates.

**Example (from established pattern):**
```dart
// Source: lib/features/filters/domain/filter_preset.dart (verified in codebase)

/// typeId: 1 — reserved for FavouriteCard.
/// typeId: 0 is taken by FilterPresetAdapter — collision would corrupt the box.
class FavouriteCardAdapter extends TypeAdapter<FavouriteCard> {
  @override
  final int typeId = 1;

  @override
  FavouriteCard read(BinaryReader reader) {
    final id = reader.read() as String;
    final name = reader.read() as String;
    final typeLine = reader.read() as String;
    final rarity = reader.read() as String;
    final setCode = reader.read() as String;
    final artCropUrl = reader.read() as String?;
    final normalImageUrl = reader.read() as String?;
    final manaCost = reader.read() as String?;
    final savedAtStr = reader.read() as String;
    final colors = (reader.read() as List).cast<String>();
    return FavouriteCard(
      id: id, name: name, typeLine: typeLine, rarity: rarity, setCode: setCode,
      artCropUrl: artCropUrl, normalImageUrl: normalImageUrl, manaCost: manaCost,
      savedAt: DateTime.parse(savedAtStr), colors: colors,
    );
  }

  @override
  void write(BinaryWriter writer, FavouriteCard obj) {
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.typeLine);
    writer.write(obj.rarity);
    writer.write(obj.setCode);
    writer.write(obj.artCropUrl);
    writer.write(obj.normalImageUrl);
    writer.write(obj.manaCost);
    // Store as ISO-8601 string — consistent with FilterPresetAdapter date pattern.
    writer.write(obj.savedAt.toIso8601String());
    writer.write(obj.colors);
  }
}
```

**Field count:** 10 fields written in fixed order. Order must never change without a migration note.

### Pattern 2: FavouritesNotifier (write-through, keepAlive)

**What:** `AsyncNotifier<List<FavouriteCard>>` with `keepAlive: true`. Reads from the open Hive box on `build()`, exposes `add`, `remove`, and `isFavourite`. No streams — reads are synchronous from the in-memory box.

**When to use:** This is the project pattern for Hive-backed notifiers (established by `FilterPresetsNotifier`).

**Critical:** Use `card.id` as the Hive box key (consistent with D-12 / D-13) so `_box.containsKey(id)` implements `isFavourite` cheaply.

```dart
// Source: lib/features/filters/presentation/providers.dart (verified — established pattern)
@Riverpod(keepAlive: true)
class FavouritesNotifier extends _$FavouritesNotifier {
  Box<FavouriteCard> get _box => Hive.box<FavouriteCard>('favourites');

  @override
  List<FavouriteCard> build() =>
      _box.values.toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt)); // newest first (discretion)

  void add(FavouriteCard card) {
    _box.put(card.id, card);
    state = _sorted();
  }

  void remove(String id) {
    _box.delete(id);
    state = _sorted();
  }

  bool isFavourite(String id) => _box.containsKey(id);

  List<FavouriteCard> _sorted() =>
      _box.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));
}
```

**Note on `isFavourite`:** This is called synchronously per rendered card in `CardSwipeScreen`. Since it reads from the in-memory box (not disk), it is safe to call in `build()` without async overhead. [VERIFIED: Hive CE boxes are in-memory once opened]

### Pattern 3: Swipe-Up Save in CardSwipeScreen

**What:** In the existing `onSwipe` callback in `_buildSwipeStack`, add a branch for `CardSwiperDirection.top`.

**Example:**
```dart
// Source: lib/features/card_discovery/presentation/card_swipe_screen.dart (verified)
onSwipe: (previousIndex, currentIndex, direction) {
  if (direction == CardSwiperDirection.top) {
    // Save to favourites — same action as bookmark button tap.
    _saveToFavourites(card);
    return true; // Consume the swipe without loading next card.
    // OR: return false to also advance — user decision already made (D-02 says save only).
  }
  ref.read(randomCardProvider.notifier).refresh();
  return true;
},
```

**Important:** `CardSwiperDirection.top` is an enum value in `flutter_card_swiper` 7.x. [VERIFIED: flutter_card_swiper 7.2.0 in pubspec.lock; CardSwipeScreen already imports and uses the package]

**Swipe-up return value clarification:** Returning `true` from `onSwipe` for the top direction saves the card but does NOT auto-advance. The user must swipe left/right to get the next card (consistent with D-02: "swipe-up saves"). Returning `false` would cancel the swipe animation entirely; returning `true` completes the animation but the `cardsCount: 1` setup means a new card only loads on an explicit refresh call. [ASSUMED — the exact return-value behavior for cardsCount: 1 with only 1 card displayed should be validated against the swiper package behavior at runtime]

### Pattern 4: Multi-Select Grid Mode

**What:** Local `ConsumerStatefulWidget` state manages multi-select mode and the selected-IDs set. Provider state (`FavouritesNotifier`) manages the authoritative favourites list.

**State split:**
- `bool _isSelecting` — whether multi-select mode is active
- `Set<String> _selectedIds` — IDs of selected cards

**App bar transition:** Use `SliverAppBar` inside `CustomScrollView` and rebuild based on `_isSelecting`:
```dart
// Standard pattern — no external package needed
SliverAppBar(
  title: _isSelecting
      ? Text('${_selectedIds.length} selected')
      : const Text('Favourites'),
  actions: _isSelecting
      ? [IconButton(icon: const Icon(Icons.delete), onPressed: _batchDelete)]
      : [IconButton(icon: const Icon(Icons.filter_list), onPressed: _openFilterSheet)],
),
```

**Grid cell overlay (checkmark):** A `Stack` with a `Positioned` checkmark container (same `Positioned` overlay technique as `_CardFaceWidget`). Visibility gated on `_selectedIds.contains(card.id)`.

**Exit multi-select:** `WillPopScope` (Flutter 3.x) or `PopScope` (Flutter 3.16+ / current Flutter 3.41.6 uses `PopScope`) intercepts back-press to clear selection instead of navigating away.

**Flutter version note:** Flutter 3.41.6 is installed. `PopScope` (replacing deprecated `WillPopScope`) is available. [VERIFIED: `flutter --version` output]

### Pattern 5: Undo Snackbar Delete

**What:** Delete from Hive immediately, show Snackbar with Undo action. If user taps Undo, re-insert deleted card(s) via `FavouritesNotifier.add()`.

**Implementation:** Store the deleted `FavouriteCard` (or `List<FavouriteCard>` for batch) in a local variable before calling `remove`. Pass to Snackbar action closure.

```dart
void _deleteSingle(FavouriteCard card) {
  final deleted = card; // capture before remove
  ref.read(favouritesProvider.notifier).remove(card.id);
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 3),
        content: Text('${deleted.name} removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => ref.read(favouritesProvider.notifier).add(deleted),
        ),
      ));
}

void _batchDelete(List<FavouriteCard> cards) {
  final deleted = List<FavouriteCard>.from(cards); // capture all before removing
  for (final card in deleted) {
    ref.read(favouritesProvider.notifier).remove(card.id);
  }
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 3),
        content: Text('${deleted.length} cards removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            for (final card in deleted) {
              ref.read(favouritesProvider.notifier).add(card);
            }
          },
        ),
      ));
}
```

[ASSUMED — Snackbar `clearSnackBars()` before `showSnackBar()` is the idiomatic way to avoid stacking Snackbars; confirm no conflicts with existing Snackbar usage in `CardSwipeScreen` "Saved to Favourites" notification]

### Pattern 6: Client-Side Favourites Filter

**What:** A derived `autoDispose` provider that takes the full `FavouritesNotifier` list and applies a `FavouritesFilter` value (colours/types/rarities). Filter state is its own `autoDispose` notifier so it resets when the Favourites tab is left.

```dart
// autoDispose is the default in Riverpod 3.x (no keepAlive annotation means autoDispose)
@riverpod
class FavouritesFilterNotifier extends _$FavouritesFilterNotifier {
  @override
  FavouritesFilter build() => const FavouritesFilter(); // all-empty = no filter

  void setColors(Set<String> colors) => state = state.copyWith(colors: colors);
  void setTypes(Set<String> types) => state = state.copyWith(types: types);
  void setRarities(Set<String> rarities) => state = state.copyWith(rarities: rarities);
  void reset() => state = const FavouritesFilter();
}

// Derived filtered list — autoDispose so it's recalculated fresh each time
@riverpod
List<FavouriteCard> filteredFavourites(Ref ref) {
  final all = ref.watch(favouritesProvider);
  final filter = ref.watch(favouritesFilterNotifierProvider);
  return all.where((card) {
    final colorMatch = filter.colors.isEmpty ||
        card.colors.any((c) => filter.colors.contains(c));
    final typeMatch = filter.types.isEmpty ||
        filter.types.any((t) => card.typeLine.contains(t));
    final rarityMatch = filter.rarities.isEmpty ||
        filter.rarities.contains(card.rarity);
    return colorMatch && typeMatch && rarityMatch;
  }).toList();
}
```

**Note:** `FavouritesFilter` is a simple value object (not persisted). `FavouriteCard.colors` stores Scryfall color identity strings (e.g., `['R', 'G']`). [VERIFIED: D-12 specifies `colors` as `List<String>` — Scryfall color identity]

### Pattern 7: FavouriteSwipeScreen Navigation + Seek

**What:** The route `/favourites/:id` passes `favouriteId`. The screen reads the sorted `FavouritesNotifier` list and finds the index of the matching ID to seek `CardSwiper` to the initial position.

**CardSwiper seek approach:** `CardSwiperController` supports setting an initial index. For `flutter_card_swiper` 7.x the `cardsCount` is `favourites.length` and the initial display seeks to `favourites.indexWhere((c) => c.id == favouriteId)`. [ASSUMED — exact API for initial index in flutter_card_swiper 7.x should be validated; the package may use `initialIndex` constructor param or controller method]

### Anti-Patterns to Avoid

- **Persisting full `MagicCard` in Hive:** `MagicCard` has fields not needed for display/filtering (oracle text, legalities, prices). Use the `FavouriteCard` projection defined in D-12.
- **Stream-watching the Hive box:** Hive CE boxes are in-memory after opening; polling `_box.values` on every read is cheap. Using `box.watch()` streams adds complexity with no benefit for a write-through notifier.
- **Calling `isFavourite` as async:** It is synchronous (`_box.containsKey`). No `AsyncValue` wrapper needed; call it inline in `build()`.
- **Storing `savedAt` as `DateTime` directly in Hive:** Hand-written adapters do not auto-serialize `DateTime`. Store as ISO-8601 string (same pattern as `FilterPresetAdapter` dates). [VERIFIED: filter_preset.dart lines 62-63]
- **Using `setState` for multi-select in `FavouritesScreen`:** Multi-select IS local widget state (`_isSelecting`, `_selectedIds`) that must trigger rebuilds — use `setState` for these fields only, consistent with CLAUDE.md's narrow exception for validation errors in `FilterSettingsScreen`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Undo delete | Custom undo stack / history manager | `ScaffoldMessenger.showSnackBar` with `SnackBarAction` | Flutter's SnackBar provides built-in ~3s timer, dismiss-on-new-snackbar, and action callback — sufficient for single-level undo |
| Grid layout | Custom grid with manual cell sizing | `SliverGrid.count(crossAxisCount: 3)` | Standard Flutter sliver — handles scroll physics, item positioning, and empty space automatically |
| Image caching in grid | Manual `Image.network` with cache headers | `CachedNetworkImage` (already dependency) | Handles disk + memory caching, placeholder/error states, and race conditions |
| Type adapter boilerplate | `build_runner` + `hive_generator` annotations | Hand-written adapter (established project pattern) | Project already uses hand-written adapters to avoid source_gen conflicts; changing approach now introduces risk |
| Multi-select back-press interception | Gesture detector wrapping entire screen | `PopScope(canPop: !_isSelecting, onPopInvoked: ...)` | Flutter 3.16+ standard for intercepting back navigation; replaces deprecated `WillPopScope` |

**Key insight:** All the complex interaction patterns in this phase (swipe, grid, undo, back-intercept) are covered by Flutter framework primitives and the existing package set. No new pub.dev packages are needed.

---

## Common Pitfalls

### Pitfall 1: typeId Collision
**What goes wrong:** If `FavouriteCardAdapter` uses `typeId: 0` (same as `FilterPresetAdapter`), Hive throws a `HiveError: There is already a TypeAdapter for typeId 0` at startup — or silently mis-deserialises data.
**Why it happens:** Easy to copy-paste from the `FilterPresetAdapter` without updating the typeId.
**How to avoid:** `FavouriteCardAdapter.typeId` MUST be `1`. The comment in `filter_preset.dart` line 23 explicitly warns: "Phase 3 FavouriteCard MUST use typeId: 1 to avoid collision." [VERIFIED: filter_preset.dart line 23]
**Warning signs:** `HiveError` at app startup, or `type 'FilterPreset' is not a subtype of type 'FavouriteCard'` cast errors when reading the favourites box.

### Pitfall 2: Box Not Opened Before Notifier Reads It
**What goes wrong:** `FavouritesNotifier.build()` calls `Hive.box<FavouriteCard>('favourites')` — if this box was not opened in `main.dart` before `runApp`, it throws `HiveError: Box not found`.
**Why it happens:** `main.dart` currently opens only the `'filter_presets'` box (line 16). The `'favourites'` box must be added in the same block.
**How to avoid:** Plan 1 (Hive init) must add both `Hive.registerAdapter(FavouriteCardAdapter())` and `await Hive.openBox<FavouriteCard>('favourites')` to `main.dart` before `runApp`. [VERIFIED: main.dart — only filter_presets box is opened]
**Warning signs:** `HiveError: Box not found. Did you forget to call Hive.openBox()?` at runtime.

### Pitfall 3: build_runner Not Re-Run After Adding New @riverpod Providers
**What goes wrong:** New `@riverpod` providers in `providers.dart` produce "Undefined name 'favouritesProvider'" compile errors because the `.g.dart` generated file is stale.
**Why it happens:** `riverpod_generator` requires `build_runner` to regenerate `providers.g.dart` after any `@riverpod` annotation change.
**How to avoid:** Run `flutter pub run build_runner build --delete-conflicting-outputs` after every change to a `@riverpod` file. [VERIFIED: project uses code-gen; all existing providers have `part 'providers.g.dart'`]
**Warning signs:** Compile error referencing generated provider name not found.

### Pitfall 4: Snackbar Conflicts Between Screens
**What goes wrong:** "Saved to Favourites" Snackbar (triggered from `CardSwipeScreen`) and delete Undo Snackbar (triggered from `FavouriteSwipeScreen`) can stack if `clearSnackBars()` is not called first.
**Why it happens:** `ScaffoldMessenger` is scoped to the nearest `Scaffold` but bottom-tab navigation shares a single `ScaffoldMessenger` at the `MaterialApp.router` level.
**How to avoid:** Always call `ScaffoldMessenger.of(context).clearSnackBars()` before `showSnackBar()` so only the most recent action is visible. [ASSUMED — verify ScaffoldMessenger scope with the GoRouter StatefulShellRoute scaffold structure]

### Pitfall 5: Swipe-Up on Already-Saved Card Shows Duplicate Snackbar
**What goes wrong:** If the user swipes up on a card already in Favourites, the save action fires again — duplicate Hive write and a confusing "Saved to Favourites" message.
**Why it happens:** `onSwipe` callback does not guard against duplicates.
**How to avoid:** In the swipe-up branch, check `isFavourite(card.id)` before calling `add()`. If already saved, show a different Snackbar ("Already in Favourites") or no Snackbar. [ASSUMED — exact UX behaviour not specified in CONTEXT.md; choose the simpler "no-op + no Snackbar" approach]

### Pitfall 6: `artCropUrl` Null in Grid Thumbnail
**What goes wrong:** `FavouriteCard.artCropUrl` is nullable (D-12). Passing null directly to `CachedNetworkImage` throws an assertion error.
**Why it happens:** Some MTG cards (tokens, emblems) have no art crop URL. The `MagicCard` model already marks `artCrop` as `String?`.
**How to avoid:** Guard before building `CachedNetworkImage` — show `ColoredBox(color: AppColors.surface)` as fallback (same pattern as `_CardFaceWidget` for null `imageUrl`). [VERIFIED: card_swipe_screen.dart lines 201-214]

### Pitfall 7: Multi-Select State Survives Tab Navigation
**What goes wrong:** If the user switches tabs while in multi-select mode and returns, the multi-select state may persist — confusing UX.
**Why it happens:** `ConsumerStatefulWidget` state persists as long as the widget is in the tree. GoRouter's `StatefulShellRoute` keeps each tab's subtree alive.
**How to avoid:** Override `didChangeDependencies` or use `RouteAwareWidget` to detect tab focus change, or simply reset `_isSelecting` in `dispose()` (which fires when the route is popped). For tab switches without pop, a pragmatic approach: accept that multi-select persists across tab switches (low-impact UX issue) or use `WidgetsBindingObserver` / GoRouter listener to detect focus loss. [ASSUMED — acceptable to leave multi-select persistent across tab switches for v1; flag as a known limitation]

---

## Code Examples

### Building the Favourites Grid
```dart
// Source: Flutter documentation pattern; SliverGrid.count is standard Flutter API
CustomScrollView(
  slivers: [
    SliverAppBar(
      title: _isSelecting
          ? Text('${_selectedIds.length} selected')
          : const Text('Favourites'),
      floating: true,
      actions: [...],
    ),
    SliverGrid.count(
      crossAxisCount: 3,
      mainAxisSpacing: 2.0,     // ~2px gaps (D-05)
      crossAxisSpacing: 2.0,
      childAspectRatio: 1.0,    // Square art crop cells
      children: filtered.map((card) => _FavouriteGridCell(
        card: card,
        isSelected: _selectedIds.contains(card.id),
        isSelecting: _isSelecting,
        onTap: () => _onCellTap(card),
        onLongPress: () => _onCellLongPress(card),
      )).toList(),
    ),
  ],
),
```

### Bookmark Button Overlay in _CardFaceWidget
```dart
// Source: card_swipe_screen.dart Positioned overlay pattern (verified)
// Add as additional Positioned child in the existing Stack
Positioned(
  bottom: AppSpacing.sm,
  right: AppSpacing.sm,
  child: IconButton(
    icon: Icon(
      isFav ? Icons.favorite : Icons.favorite_border,
      color: isFav ? AppColors.error : AppColors.onBackground,
    ),
    onPressed: isFav ? null : () => _saveToFavourites(card),
  ),
),
```

### main.dart Addition (Plan 1)
```dart
// Source: main.dart (verified — add after FilterPresetAdapter lines)
Hive.registerAdapter(FavouriteCardAdapter());
await Hive.openBox<FavouriteCard>('favourites');
```

### PopScope for Multi-Select Back Intercept
```dart
// Source: Flutter 3.16+ API — PopScope replaces deprecated WillPopScope
// Flutter 3.41.6 is installed (verified)
PopScope(
  canPop: !_isSelecting,
  onPopInvokedWithResult: (didPop, result) {
    if (!didPop) {
      setState(() {
        _isSelecting = false;
        _selectedIds.clear();
      });
    }
  },
  child: ...,
),
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `WillPopScope` | `PopScope` + `onPopInvokedWithResult` | Flutter 3.16 | `WillPopScope` is deprecated in Flutter 3.x; use `PopScope` |
| `Riverpod 2.x` `@riverpod` | `Riverpod 3.x` `@riverpod` (same annotation, different generated API) | Riverpod 3.0 | Project already on 3.3.1; `Ref` is now `Ref` not `WidgetRef` in providers |

[VERIFIED: Flutter 3.41.6 and flutter_riverpod 3.3.1 from pubspec.lock + flutter --version]

**Deprecated/outdated:**
- `WillPopScope`: Deprecated since Flutter 3.16. Use `PopScope`. Flutter 3.41.6 will show deprecation warnings. [VERIFIED: Flutter version]
- `GridView.builder` as top-level scroll: Acceptable but `SliverGrid` inside `CustomScrollView` is preferred when a `SliverAppBar` is also present — avoids nested scroll controllers.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Returning `true` from `onSwipe` for `CardSwiperDirection.top` with `cardsCount: 1` saves the card but does not auto-advance to next card | Architecture Patterns §3 | If wrong, swipe-up would auto-advance (load next card); fix: call refresh only for left/right directions |
| A2 | `clearSnackBars()` before `showSnackBar()` is the correct approach given the `StatefulShellRoute` + single `ScaffoldMessenger` scope | Common Pitfalls §4 | If wrong, multiple Snackbars may stack; risk is minor UX issue only |
| A3 | Multi-select state persisting across tab switches is acceptable for v1 | Common Pitfalls §7 | If not acceptable, add focus-change detection via GoRouter listener |
| A4 | `flutter_card_swiper` 7.x supports an initial index parameter for `FavouriteSwipeScreen` to seek to the tapped card | Architecture Patterns §7 | If no initial index support, use a workaround (pre-scroll or sort the list to put tapped card first) |
| A5 | No Snackbar or a silent no-op is the preferred behaviour when swiping up on an already-saved card | Common Pitfalls §5 | If user expects confirmation, add "Already in Favourites" Snackbar |

---

## Open Questions

1. **Swipe-up return value in flutter_card_swiper with cardsCount: 1**
   - What we know: `onSwipe` returns `bool`; returning `true` normally advances the card stack
   - What's unclear: With only 1 card in the swiper, does returning `true` for `top` direction cause a "stack empty" error or silently no-op?
   - Recommendation: In Plan 3 (swipe integration), add a runtime check: if `direction == CardSwiperDirection.top`, save and return `false` (cancel swipe animation) rather than `true`. The save action is fire-and-forget; the animation cancel is safer. Validate at implementation time.

2. **`flutter_card_swiper` initial index for FavouriteSwipeScreen**
   - What we know: `CardSwiper` has `initialIndex` constructor parameter in some versions
   - What's unclear: Whether `flutter_card_swiper` 7.2.0 specifically has `initialIndex`
   - Recommendation: Check `CardSwiper` constructor signature during Plan 5 implementation. Fallback: sort the list with the tapped card at index 0.

---

## Environment Availability

Step 2.6: SKIPPED — phase is purely code changes within the existing Flutter project. No new external services, databases, or CLI tools are required beyond the already-verified Flutter 3.41.6 toolchain.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (bundled with Flutter 3.41.6) + mockito 5.6.4 |
| Config file | No separate config — standard `flutter test` discovery |
| Quick run command | `flutter test test/unit/favourites/ test/widgets/favourites/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FAV-01 | `FavouritesNotifier.add()` stores card, `isFavourite()` returns true | unit | `flutter test test/unit/favourites/favourites_notifier_test.dart` | ❌ Wave 0 |
| FAV-01 | Swipe-up direction triggers save action in CardSwipeScreen | widget | `flutter test test/widgets/card_discovery/` | ❌ Wave 0 |
| FAV-02 | FavouritesScreen renders 3-column grid when favourites exist | widget | `flutter test test/widgets/favourites/favourites_screen_test.dart` | ❌ Wave 0 |
| FAV-03 | Tapping grid cell navigates to `/favourites/:id` | widget | `flutter test test/widgets/favourites/favourites_screen_test.dart` | ❌ Wave 0 |
| FAV-04 | `FavouritesNotifier.remove()` deletes card; undo re-inserts | unit | `flutter test test/unit/favourites/favourites_notifier_test.dart` | ❌ Wave 0 |
| FAV-05 | Hive box persists across Hive close/reopen in temp directory | unit | `flutter test test/unit/favourites/favourites_notifier_test.dart` | ❌ Wave 0 |
| FAV-06 | FavouritesScreen renders empty state when favourites list is empty | widget | `flutter test test/widgets/favourites/favourites_screen_test.dart` | ❌ Wave 0 |
| FAV-07 | Client-side filter returns correct subset by colour/type/rarity | unit | `flutter test test/unit/favourites/favourites_filter_test.dart` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/unit/favourites/ test/widgets/favourites/`
- **Per wave merge:** `flutter test && flutter analyze`
- **Phase gate:** Full `flutter test` + `flutter analyze --fatal-infos` green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/unit/favourites/favourites_notifier_test.dart` — covers FAV-01, FAV-04, FAV-05
- [ ] `test/unit/favourites/favourites_filter_test.dart` — covers FAV-07
- [ ] `test/widgets/favourites/favourites_screen_test.dart` — covers FAV-02, FAV-03, FAV-06
- [ ] `test/fixtures/fake_favourite_card.dart` — shared fixture factory (parallel to `fake_preset.dart`)

---

## Security Domain

This phase has no authentication, network calls, or user-input-to-query paths. The only data flows are:

- Reading `MagicCard` fields (already validated/typed from Scryfall JSON in Phase 1)
- Writing a projection to local Hive CE storage (no external transmission)
- Displaying stored strings in UI (no `dangerouslySetInnerHTML` equivalent in Flutter)

**ASVS V5 Input Validation:** All fields written to `FavouriteCard` come from previously-parsed `MagicCard` objects — they are already typed Dart strings/lists, not raw user input. No additional sanitization needed.

**No applicable ASVS categories for this phase** — no auth (V2), no sessions (V3), no access control (V4), no cryptography (V6), no file uploads, no external API calls.

---

## Project Constraints (from CLAUDE.md)

The following directives from `CLAUDE.md` apply to this phase. The planner MUST verify all generated plans comply.

| Directive | Impact on Phase 3 |
|-----------|-------------------|
| Features must not import from each other's `data/` or `presentation/` layers | `FavouritesNotifier` must not import from `card_discovery/data/` or `filters/data/`; provider imports OK |
| Cross-feature shared types go in `shared/models/` or `shared/widgets/` | `MagicCard` stays in `shared/models/`; `FavouriteCard` is favourites-feature-only → `features/favourites/domain/` |
| No hardcoded colours/magic numbers — use `AppColors`/`AppSpacing` constants | Grid gaps must use `AppSpacing.xs` (4.0) or a named constant, not `2.0` literals |
| Every public class, method, and Riverpod provider must have `///` doc comment | `FavouriteCard`, `FavouriteCardAdapter`, `FavouritesNotifier`, all public methods |
| Complex logic must have inline `//` comments explaining why | `FavouriteCardAdapter` field-order comment, `isFavourite` synchronous note |
| Avoid `setState` — use `ConsumerWidget` or `ConsumerStatefulWidget` | Multi-select `_isSelecting`/`_selectedIds` are legitimate `setState` use (local ephemeral UI state); all provider state via Riverpod |
| Never access Hive or make HTTP calls directly from widgets — go through providers | `FavouritesScreen` and `FavouriteSwipeScreen` must call `ref.read(favouritesProvider.notifier)` only |
| All repository methods must return typed results (`Result<T>` pattern or sealed classes) | `FavouritesRepository` methods should return `Result<T>` or `void` (for write-through, `void` is acceptable since failures throw synchronously) |
| `flutter analyze --fatal-infos` passes with zero warnings | `PopScope` must be used, not deprecated `WillPopScope`; all imports must be used |
| Run `flutter test` and `flutter analyze` before marking any task done | Each plan's DoD must include both commands |
| Hive CE box/adapter changes must be accompanied by a migration strategy note | Plan 1 must document the migration note: typeId: 1 is fixed; changing `FavouriteCardAdapter` field order requires clearing the box |

---

## Sources

### Primary (HIGH confidence)
- Live codebase — `lib/features/filters/domain/filter_preset.dart` — Hive CE hand-written adapter pattern (typeId: 0, field serialisation order, DateTime as string)
- Live codebase — `lib/features/filters/presentation/providers.dart` — `FilterPresetsNotifier` write-through pattern; `keepAlive: true` Riverpod notifier
- Live codebase — `lib/features/card_discovery/presentation/card_swipe_screen.dart` — `CardSwiper.onSwipe`, `_CardFaceWidget` Stack + Positioned overlay, `Skeletonizer` loading pattern
- Live codebase — `lib/main.dart` — Hive init + adapter registration + box open sequence
- Live codebase — `lib/core/router/app_router.dart` — `/favourites/:id` route already wired to `FavouriteSwipeScreen`
- `pubspec.lock` — exact resolved versions for all packages

### Secondary (MEDIUM confidence)
- Flutter 3.41.6 release notes — `PopScope` replaces `WillPopScope` from Flutter 3.16 onwards
- Flutter documentation — `SliverGrid.count`, `CustomScrollView`, `ScaffoldMessenger.showSnackBar`

### Tertiary (LOW confidence / ASSUMED)
- `flutter_card_swiper` 7.2.0 behavior for `CardSwiperDirection.top` return value with `cardsCount: 1` — not verified against package source
- `flutter_card_swiper` 7.2.0 `initialIndex` parameter availability — not verified against package source

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all versions from `pubspec.lock`
- Architecture patterns: HIGH — directly derived from existing Phase 2 code
- Pitfalls: HIGH (most) / ASSUMED (Snackbar scope, swipe-up return value)
- Test map: HIGH — follows exact structure from Phase 2 test files

**Research date:** 2026-04-16
**Valid until:** 2026-05-16 (stable Flutter/Hive/Riverpod ecosystem; no fast-moving dependencies in this phase)
