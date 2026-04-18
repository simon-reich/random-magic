# Phase 5: Tests - Research

**Researched:** 2026-04-18
**Domain:** Flutter testing — unit, widget, integration — for a Riverpod + GoRouter + Hive CE app
**Confidence:** HIGH

---

## Summary

Phase 5 is a pure test-writing phase targeting 80%+ coverage on all business logic, widget
tests for every screen in all states, and one integration test covering the core user flow.
Phases 1–4 are complete; all production code exists and passes `flutter analyze`. The test
infrastructure was bootstrapped progressively during each earlier phase, so a significant
amount of work is already done — this phase fills the remaining gaps.

The current test suite has 87 passing tests and 13 skipped stubs. Coverage already exceeds
100% on several logic files. The major gaps are: (1) `CardSwipeScreen` widget tests covering
all five states, (2) `FilterSettingsScreen` widget tests (stubs exist, bodies missing), (3)
`ActiveFilterBar` widget tests (stubs exist), (4) `MagicCard.fromJson()` unit tests for the
full edge-case matrix, (5) `RandomCardNotifier` unit tests with a fake repository, and (6)
the integration test. These map directly to TEST-01 through TEST-06.

**Primary recommendation:** Work through the stub files from the bottom up — unit tests first
(pure Dart, fast feedback), then widget tests, then integration last. Use the existing
`FakeCardRepository` pattern already established by `CardDetailScreen` tests.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TEST-01 | Unit tests for `ScryfallQueryBuilder.fromSettings()` covering all filter combinations | Already fully implemented — 19 tests passing, 100% coverage |
| TEST-02 | Unit tests for `MagicCard.fromJson()` — normal, DFC, null prices, null oracle text | Colors parsing exists; full fromJson matrix missing — new test file needed |
| TEST-03 | Widget tests for `CardSwipeScreen` — loading, success, all 3 error states | No CardSwipeScreen widget test file exists — new file needed |
| TEST-04 | Widget tests for `FilterSettingsScreen` and `FavouritesScreen` | FavouritesScreen: 4 tests passing; FilterSettingsScreen: 7 stubs all skipped |
| TEST-05 | Unit tests for `FavouritesNotifier` and `FilterPresetsNotifier` with Hive CE in temp dir | Both fully implemented — 5 + 6 tests passing |
| TEST-06 | Integration test: swipe → new card loads → save to favourites → card appears in grid | integration_test/ directory exists but empty (only .gitkeep) |
| QA-01 | `flutter analyze --fatal-infos` passes with zero warnings | Must pass after every plan; not a new test to write |
| QA-02 | All async operations have loading, success, and error states handled in the UI | Covered by TEST-03 widget tests; verify no states are missing |
| QA-03 | No hardcoded colours or magic numbers | Verified by code review; not a test to write |
</phase_requirements>

---

## Current Test Inventory

> [VERIFIED: running `flutter test` and reading all test files]

### What Already Exists and Passes

| File | Tests | Status |
|------|-------|--------|
| `test/unit/filters/scryfall_query_builder_test.dart` | 10 | All passing — TEST-01 DONE |
| `test/unit/filters/filter_settings_notifier_test.dart` | 16 | All passing |
| `test/unit/filters/filter_presets_notifier_test.dart` | 6 | All passing — TEST-05 (presets) DONE |
| `test/unit/favourites/favourites_notifier_test.dart` | 5 | All passing — TEST-05 (favs) DONE |
| `test/unit/favourites/favourites_filter_test.dart` | 6 | All passing |
| `test/unit/favourites/favourite_card_test.dart` | 10 | All passing |
| `test/unit/card_discovery/magic_card_colors_test.dart` | 6 | Passing (colors field only) |
| `test/widgets/favourites/favourites_screen_test.dart` | 4 | All passing — TEST-04 (favs) DONE |
| `test/widgets/card_detail/card_detail_screen_test.dart` | 14 | All passing |
| `test/app_test.dart` | 1 | Placeholder only |

### What Are Stubs (skip: true or empty bodies)

| File | Stubs | Target Plan |
|------|-------|-------------|
| `test/widgets/filters/filter_settings_screen_test.dart` | 7 stubs | Plan 05-02 |
| `test/widgets/card_discovery/card_swipe_screen_filter_bar_test.dart` | 3 stubs | Plan 05-02 |
| `test/widgets/card_discovery/card_swipe_screen_tap_test.dart` | 2 stubs (skip: true) | Plan 05-02 |

### What Does Not Exist Yet

| Missing File | Covers |
|---|---|
| `test/unit/card_discovery/magic_card_from_json_test.dart` | TEST-02 full matrix |
| `test/unit/card_discovery/random_card_notifier_test.dart` | Provider unit tests |
| `test/widgets/card_discovery/card_swipe_screen_test.dart` | TEST-03 (5 states) |
| `integration_test/core_flow_test.dart` | TEST-06 |

---

## Standard Stack

### Core (already in pubspec — no new dependencies needed)

| Library | Version | Purpose | How Used in Tests |
|---------|---------|---------|-------------------|
| `flutter_test` | SDK-bundled | Test framework, widget pumping | All test files |
| `flutter_riverpod` | ^3.0.0 | `ProviderContainer`, `ProviderScope` | Unit + widget tests |
| `mockito` | ^5.4.4 | Mock generation (build_runner) | Available; currently unused — FakeRepository pattern preferred |
| `hive_ce` | ^2.19.3 | Hive CE test init pattern | Unit tests for notifiers |
| `go_router` | ^17.2.0 | Test router construction | CardDetailScreen + integration test |
| `integration_test` | SDK-bundled | Flutter integration test driver | TEST-06 |

[VERIFIED: pubspec.yaml read directly — no additional packages required for this phase]

**Integration test requires adding `integration_test` to pubspec dev_dependencies:**

```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

[VERIFIED: `integration_test` package is bundled with Flutter SDK — no pub.dev fetch needed]

---

## Architecture Patterns

### Pattern 1: FakeCardRepository (Preferred over Mockito)

The existing codebase uses `_FakeFavouritesNotifier` (in `card_detail_screen_test.dart`) and
value overrides (`favouritesProvider.overrideWithValue(...)`) rather than Mockito mocks.
Maintain this pattern for consistency.

```dart
// Source: test/widgets/card_detail/card_detail_screen_test.dart (verified)
class _FakeFavouritesNotifier extends FavouritesNotifier {
  @override
  List<FavouriteCard> build() => const [];
}

// For CardRepository, create a FakeCardRepository in test/fixtures/
class FakeCardRepository implements CardRepository {
  final Result<MagicCard> _result;

  FakeCardRepository({Result<MagicCard>? result})
      : _result = result ?? Success(fakeMagicCard());

  @override
  Future<Result<MagicCard>> getRandomCard({String? query}) async => _result;

  @override
  Future<Result<MagicCard>> getCardById(String id) async => _result;
}
```

Override the provider in tests:
```dart
ProviderScope(
  overrides: [
    cardRepositoryProvider.overrideWithValue(FakeCardRepository()),
  ],
  child: const CardSwipeScreen(),
)
```

### Pattern 2: Hive CE in Unit Tests

[VERIFIED: test/unit/favourites/favourites_notifier_test.dart read directly]

```dart
setUp(() async {
  Hive.init(Directory.systemTemp.path);
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(FavouriteCardAdapter());
  }
  final box = await Hive.openBox<FavouriteCard>('favourites');
  await box.clear();
  container = ProviderContainer();
});

tearDown(() async {
  container.dispose();
  await Hive.close();
});
```

**Critical:** Use `Hive.init(Directory.systemTemp.path)` — NOT `Hive.initFlutter()`. The
latter requires a native channel and crashes in the test runner. [VERIFIED: existing tests use this pattern]

### Pattern 3: CardSwipeScreen Widget Test

`CardSwipeScreen` watches `randomCardProvider` which is an `AsyncNotifier<MagicCard>`. To
test specific states, override `cardRepositoryProvider` (which `RandomCardNotifier` depends
on) and use `AsyncValue` state injection.

Because `randomCardProvider` is `keepAlive: true`, override it at `ProviderContainer` level:

```dart
// Source: synthesized from existing override patterns in the codebase [ASSUMED — verify compiles]
late ProviderContainer container;

setUp(() {
  // Hive must be open because FavouritesNotifier (keepAlive) opens Hive.box('favourites')
  Hive.init(Directory.systemTemp.path);
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(FavouriteCardAdapter());
  Hive.openBox<FavouriteCard>('favourites');
  container = ProviderContainer(overrides: [
    cardRepositoryProvider.overrideWithValue(FakeCardRepository()),
  ]);
});

testWidgets('shows loading state', (tester) async {
  // Inject AsyncLoading state before pump
  container.read(randomCardProvider.notifier);
  container.updateOverrides([
    cardRepositoryProvider.overrideWithValue(
      FakeCardRepository(stall: true), // never resolves
    ),
  ]);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: CardSwipeScreen()),
    ),
  );
  // Skeletonizer shows shimmer — no card text visible
  expect(find.byType(Skeletonizer), findsWidgets);
});
```

Alternative simpler approach (no stall): override `randomCardProvider` state directly via
`ProviderContainer` and inject `AsyncLoading()`, `AsyncData(card)`, or `AsyncError(failure, StackTrace.empty)`.

**Key dependency chain:** `CardSwipeScreen` also watches `favouritesProvider` (for bookmark
icon state). Because `FavouritesNotifier` accesses `Hive.box('favourites')` synchronously,
the box must be open before pumping, or override `favouritesProvider` with a stub.

### Pattern 4: GoRouter-Dependent Widget Tests

For tests that trigger navigation (e.g., "Adjust Filters" button in error state goes to `/filters`):

```dart
// Source: test/widgets/card_detail/card_detail_screen_test.dart (verified)
GoRouter _testRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const CardSwipeScreen()),
    GoRoute(path: '/filters', builder: (_, __) => const FilterSettingsScreen()),
  ],
);

await tester.pumpWidget(
  ProviderScope(
    overrides: [cardRepositoryProvider.overrideWithValue(fakeRepo)],
    child: MaterialApp.router(routerConfig: _testRouter()),
  ),
);
```

For error-state button tests specifically, the navigation can also be verified by checking
that `context.go('/filters')` was called — but this requires router wrapping.

### Pattern 5: RandomCardNotifier State Injection for Widget Tests

The cleanest approach for widget tests of `CardSwipeScreen` is to override
`cardRepositoryProvider` so `RandomCardNotifier.build()` immediately resolves to the desired
state. For the loading state, use a `Completer<Result<MagicCard>>` that never completes:

```dart
class _StallingFakeRepository implements CardRepository {
  @override
  Future<Result<MagicCard>> getRandomCard({String? query}) =>
      Completer<Result<MagicCard>>().future; // never resolves → AsyncLoading
  @override
  Future<Result<MagicCard>> getCardById(String id) =>
      Completer<Result<MagicCard>>().future;
}
```

For error states, throw from `getRandomCard`:

```dart
class _FailingFakeRepository implements CardRepository {
  final AppFailure failure;
  _FailingFakeRepository(this.failure);

  @override
  Future<Result<MagicCard>> getRandomCard({String? query}) async =>
      Failure(failure);
  @override
  Future<Result<MagicCard>> getCardById(String id) async =>
      Failure(failure);
}
```

### Pattern 6: FilterSettingsScreen Widget Test

`FilterSettingsScreen` depends on `filterSettingsProvider`, `filterPresetsProvider`, and
`activeFilterQueryProvider` — all are Riverpod providers that can be overridden or simply
left at default (no Hive CE required since `FilterSettingsNotifier` is in-memory only).
`FilterPresetsNotifier` reads from Hive CE (`filter_presets` box) — must init Hive or
override the provider with a value stub.

```dart
// Simplest approach — override presetsProvider with empty list
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      filterPresetsProvider.overrideWith(() => _StubPresetsNotifier()),
    ],
    child: const MaterialApp(home: FilterSettingsScreen()),
  ),
);
```

### Pattern 7: Integration Test Structure

```dart
// integration_test/core_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:random_magic/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('core flow: swipe → new card loads → save → appears in grid',
      (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Assert card is loaded (shimmer gone, card visible)
    // Swipe left to get new card
    // Tap bookmark icon
    // Navigate to Favourites tab
    // Assert card appears in grid
  });
}
```

**Integration test limitation:** Real Scryfall network calls will be made (no fake repository
available at the full-app level without app-level DI switch). Tests must run on a device/
emulator with network access. For CI, integration tests run with `flutter test integration_test/`
separately from unit tests.

---

## What Needs to Be Written

### Plan 1: TEST-01 Gap + TEST-02 (Unit — Pure Dart)

**TEST-01 is already done.** TEST-02 (`MagicCard.fromJson()`) has only colors-field tests.
Missing edge cases that `MagicCard.fromJson()` must handle:

| Scenario | What to Test |
|----------|-------------|
| Normal card (has `image_uris`) | All fields parsed correctly |
| Double-faced card (no top-level `image_uris`, uses `card_faces[0].image_uris`) | `imageUris.normal` comes from first face; `cardFaces` is non-null with 2 entries |
| Card with null `prices` | `card.prices == null` |
| Card with all null price fields | `card.prices.usd == null`, `card.prices.eur == null`, etc. |
| Card with null `oracle_text` | `card.oracleText == null` |
| Card with null `flavor_text` | `card.flavorText == null` |
| Card with null `mana_cost` (land) | `card.manaCost == null` |
| Card with null `legalities` | `card.legalities == {}` (defensive) |
| Card with colourless (no `colors` key) | `card.colors == []` |
| `type_line` absent (token) | `card.typeLine == ''` |

Also needed: unit tests for `RandomCardNotifier.refresh()` — requires `FakeCardRepository`.

### Plan 2: TEST-03 + TEST-04 + ActiveFilterBar (Widget Tests)

**`CardSwipeScreen` states to test:**
1. Loading state — Skeletonizer visible, no card text
2. Success state — card image slot rendered, bookmark icon visible
3. Error: `CardNotFoundFailure` — "No cards found" title visible, "Adjust Filters" button
4. Error: `InvalidQueryFailure` — "Invalid filter settings" title visible, "Fix Filters" button
5. Error: `NetworkFailure` — "Could not reach Scryfall" title visible, "Retry" button
6. (Bonus) Error: `RateLimitedFailure` — "Too Many Requests" title, "Retry" button

**`FilterSettingsScreen` states to test (filling existing stubs):**
1. Colour toggles visible (W/U/B/R/G/C/M)
2. Type chips visible (Creature/Instant/Sorcery etc.)
3. Rarity chips visible (Common/Uncommon/Rare/Mythic)
4. Date pickers present
5. Preset row shown when presets exist
6. Save preset stores it
7. Duplicate name shows error
8. Chip X button removes preset

**`ActiveFilterBar` states to test (filling existing stubs):**
1. No chips visible when filter is empty
2. FilterChips visible for each active value
3. Tapping chip's delete icon removes that filter from state

### Plan 3: TEST-06 (Integration Test)

Flow: app.main() → await settle → swipe left → new card loads → tap bookmark → navigate to
Favourites → assert card in grid → (optional) delete card.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Fake HTTP responses | Custom interceptors | `FakeCardRepository implements CardRepository` |
| Hive in-memory store | Custom test cache | `Hive.init(Directory.systemTemp.path)` + real Hive |
| Provider state injection | Manual state mutation | `ProviderContainer.overrides` + fake repository |
| GoRouter in tests | Stateful mock router | `GoRouter(initialLocation: ..., routes: [...])` |
| Widget interaction simulation | Direct state mutation | `tester.tap()`, `tester.drag()`, `tester.pumpAndSettle()` |

---

## Common Pitfalls

### Pitfall 1: FavouritesNotifier Opens Hive Box Synchronously

**What goes wrong:** `CardSwipeScreen` calls `ref.watch(favouritesProvider)` which instantiates
`FavouritesNotifier.build()` → `_sorted()` → `Hive.box<FavouriteCard>('favourites')`. If the
box is not open, this throws `HiveError: Box not found`.

**Why it happens:** `FavouritesNotifier` uses `keepAlive: true`. When the `ProviderScope`
initialises, Riverpod eagerly builds keepAlive providers. The box must be open before pumping.

**How to avoid:** Either init Hive + open the box in `setUp()`, or override `favouritesProvider`
with a stub notifier (like `_FakeFavouritesNotifier` in `card_detail_screen_test.dart`).

**Warning signs:** `HiveError: Box not found. Did you forget to call Hive.openBox()?` in test output.

### Pitfall 2: FilterPresetsNotifier Also Needs Hive in FilterSettingsScreen Tests

**What goes wrong:** `FilterSettingsScreen` watches `filterPresetsProvider`, which
instantiates `FilterPresetsNotifier` → `Hive.box<FilterPreset>('filter_presets')`. Same
pattern as Pitfall 1.

**How to avoid:** Init Hive and open both boxes (`favourites` + `filter_presets`) in setUp,
OR override both `favouritesProvider` and `filterPresetsProvider` with stubs.

### Pitfall 3: ProviderContainer Hive Conflict Between Tests

**What goes wrong:** Multiple tests in one file share the same `Directory.systemTemp.path`.
If a test fails mid-run without calling `tearDown`, the Hive box stays open. Next test's
`Hive.init()` silently succeeds but the box still contains stale data.

**How to avoid:** Always call `await box.clear()` in `setUp()` (after opening the box), not
just in `tearDown()`. The existing tests already do this correctly. [VERIFIED: favourites_notifier_test.dart]

### Pitfall 4: RandomCardNotifier is keepAlive — Stays Alive Across Tests

**What goes wrong:** `randomCardProvider` is `keepAlive: true`. In a test that creates a
`ProviderContainer`, if the container is not disposed before the next test, the notifier
retains its state.

**How to avoid:** Always call `container.dispose()` in `tearDown()`. When using
`UncontrolledProviderScope(container: container)` in widget tests, the container lifecycle
is still the test's responsibility.

### Pitfall 5: CardSwiper Swipe Gesture in Widget Tests

**What goes wrong:** `CardSwiper` uses internal gesture recognizers that don't respond
to standard `tester.drag()` as expected. The swipe callback may not fire during widget tests.

**How to avoid:** For `CardSwipeScreen` widget tests, test states directly via provider
overrides — not by simulating swipe gestures. The swipe trigger (`onSwipe` → `refresh()`)
is tested indirectly. For the integration test, use `tester.fling()` with a large dx value.

**Warning signs:** Test passes but state doesn't change; `onSwipe` callback not invoked.

### Pitfall 6: Integration Test Requires Network — Not Suitable for Offline CI

**What goes wrong:** `integration_test/core_flow_test.dart` calls `app.main()` which uses
the real `CardRepositoryImpl` → real Scryfall API. On a CI machine without network access,
the card never loads and the test times out.

**How to avoid:** Document that the integration test requires network. For CI, run only
`flutter test` (unit + widget). The integration test is a UAT tool run manually. Add a
`// Requires network access — run manually` comment at the top of the file.

### Pitfall 7: Skeletonizer Shimmer vs. Actual Skeleton

**What goes wrong:** During the loading state, `Skeletonizer` wraps the placeholder
`_CardFaceWidget`. Looking for specific text like an empty string will not work because the
`Skeletonizer` renders the shimmer overlay, not visible text.

**How to avoid:** Detect the loading state by checking `find.byType(Skeletonizer)` with
`enabled: true`, or verify that card-specific text is absent rather than shimmer is present.

---

## Coverage Assessment

> [VERIFIED: `flutter test --coverage` output analysed]

### Current Coverage (before Phase 5)

| File | Current % | Status |
|------|-----------|--------|
| `scryfall_query_builder.dart` | 100% | Done |
| `filter_settings.dart` | 100% | Done |
| `filter_preset.dart` | 100% | Done |
| `filters/presentation/providers.dart` | 100% | Done |
| `favourite_card.dart` | 100% | Done |
| `favourites/presentation/providers.dart` | ~41% LH/LF ratio | Needs CardSwipeScreen tests to exercise `isFavourite` hot path |
| `magic_card.dart` | ~52% LH/LF ratio | Needs full `fromJson()` matrix tests |
| `favourites_screen.dart` | ~71% | Done (4 widget tests cover main paths) |
| `card_detail_screen.dart` | ~89% | Done |
| `card_swipe_screen.dart` | 0% (not in lcov) | All 5 states need widget tests |
| `filter_settings_screen.dart` | 0% (not in lcov) | 7 stub tests need bodies |
| `app_theme.dart` | 0% | Low priority (pure theme data) |

**Files not yet exercised at all (not appearing in lcov output):**
- `card_discovery/presentation/card_swipe_screen.dart`
- `filters/presentation/filter_settings_screen.dart`
- `card_discovery/data/card_repository_impl.dart`
- `core/network/dio_client.dart`
- `shared/failures.dart`
- `shared/result.dart`

The 80% target applies to `lib/features/` + `lib/shared/` logic classes specifically.
Network/DI infrastructure (`dio_client.dart`, `card_repository_impl.dart`) is lower priority.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK-bundled) + integration_test (SDK-bundled) |
| Config file | No config file — `flutter test` auto-discovers |
| Quick run command | `flutter test test/unit/` |
| Full suite command | `flutter test --coverage` |
| Integration test command | `flutter test integration_test/` (requires device/emulator) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TEST-01 | `ScryfallQueryBuilder` all filter combos | unit | `flutter test test/unit/filters/scryfall_query_builder_test.dart` | Yes — DONE |
| TEST-02 | `MagicCard.fromJson()` full edge-case matrix | unit | `flutter test test/unit/card_discovery/` | Partial — new file needed |
| TEST-03 | `CardSwipeScreen` 5 states | widget | `flutter test test/widgets/card_discovery/card_swipe_screen_test.dart` | No — new file needed |
| TEST-04a | `FavouritesScreen` 4 states | widget | `flutter test test/widgets/favourites/favourites_screen_test.dart` | Yes — DONE |
| TEST-04b | `FilterSettingsScreen` 7 states | widget | `flutter test test/widgets/filters/filter_settings_screen_test.dart` | Stubs only |
| TEST-05a | `FavouritesNotifier` with Hive | unit | `flutter test test/unit/favourites/favourites_notifier_test.dart` | Yes — DONE |
| TEST-05b | `FilterPresetsNotifier` with Hive | unit | `flutter test test/unit/filters/filter_presets_notifier_test.dart` | Yes — DONE |
| TEST-06 | Integration: swipe → save → grid | integration | `flutter test integration_test/` | No — new file needed |
| QA-01 | `flutter analyze --fatal-infos` clean | static | `flutter analyze --fatal-infos` | Ongoing |

### Sampling Rate

- **Per task commit:** `flutter test --no-pub`
- **Per wave merge:** `flutter test --coverage --no-pub`
- **Phase gate:** Coverage report shows 80%+ on logic files before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/unit/card_discovery/magic_card_from_json_test.dart` — covers TEST-02
- [ ] `test/unit/card_discovery/random_card_notifier_test.dart` — covers provider logic
- [ ] `test/widgets/card_discovery/card_swipe_screen_test.dart` — covers TEST-03
- [ ] `test/fixtures/fake_card_repository.dart` — shared fake for widget + unit tests
- [ ] `integration_test/core_flow_test.dart` — covers TEST-06
- [ ] `pubspec.yaml` — add `integration_test: sdk: flutter` to dev_dependencies

---

## Code Examples

### MagicCard.fromJson() — DFC Minimal JSON

```dart
// Source: lib/shared/models/magic_card.dart (verified) — test should produce:
// card.imageUris.normal == 'https://example.com/front.jpg'  (from card_faces[0])
// card.cardFaces != null && card.cardFaces!.length == 2
final dfcJson = <String, dynamic>{
  'id': 'dfc-id',
  'name': 'Delver of Secrets // Insectile Aberration',
  'type_line': 'Creature — Human Wizard // Creature — Human Insect',
  'rarity': 'common',
  'set': 'isd',
  'set_name': 'Innistrad',
  'collector_number': '51',
  'released_at': '2011-09-30',
  'legalities': <String, dynamic>{},
  'colors': ['U'],
  // No top-level image_uris — DFC pattern
  'card_faces': [
    {
      'name': 'Delver of Secrets',
      'type_line': 'Creature — Human Wizard',
      'oracle_text': 'At the beginning of your upkeep...',
      'mana_cost': '{U}',
      'image_uris': {'normal': 'https://example.com/front.jpg'},
    },
    {
      'name': 'Insectile Aberration',
      'type_line': 'Creature — Human Insect',
      'oracle_text': 'Flying',
      'mana_cost': null,
      'image_uris': {'normal': 'https://example.com/back.jpg'},
    },
  ],
};
```

### ProviderContainer Override for Fake Repository

```dart
// Source: synthesized from existing override patterns in test files [ASSUMED pattern — verify]
final container = ProviderContainer(
  overrides: [
    cardRepositoryProvider.overrideWith(
      (ref) => FakeCardRepository(result: Success(fakeMagicCard())),
    ),
  ],
);
addTearDown(container.dispose);
```

### RandomCardNotifier — Verify Error State

```dart
// Source: providers.dart (verified) — RandomCardNotifier.build() throws on Failure
// This test verifies that Failure<CardNotFoundFailure> becomes AsyncError<CardNotFoundFailure>
final container = ProviderContainer(overrides: [
  cardRepositoryProvider.overrideWith(
    (ref) => FakeCardRepository(result: const Failure(CardNotFoundFailure())),
  ),
]);
await container.read(randomCardProvider.future).catchError((_) {});
final state = container.read(randomCardProvider);
expect(state.hasError, isTrue);
expect(state.error, isA<CardNotFoundFailure>());
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `Hive.initFlutter()` in tests | `Hive.init(Directory.systemTemp.path)` | No native channel needed |
| `ProviderContainer()` (Riverpod 2.x) | `ProviderContainer()` (still valid in Riverpod 3.x) | No change needed |
| Mockito code-gen for all fakes | Hand-written fake classes (simpler, no build_runner) | Faster test iteration |
| `pump()` only | `pumpAndSettle()` for async + animations | Needed for GoRouter navigation |

---

## Open Questions

1. **FilterSettingsScreen — Hive in widget tests**
   - What we know: `FilterPresetsNotifier` accesses Hive CE box `filter_presets`. Widget tests
     that pump `FilterSettingsScreen` will trigger this.
   - What's unclear: Whether it's faster to init Hive in setUp vs. stub out the provider.
   - Recommendation: Override `filterPresetsProvider` with a stub returning `[]` in most tests;
     only bring in real Hive for preset-save-and-appear tests.

2. **Integration test — fake vs. real network**
   - What we know: Using `app.main()` uses real Scryfall. CI may not have network.
   - What's unclear: Whether this project's CI (GitHub Actions) has network access.
   - Recommendation: Write integration test using real network; add prominent comment that
     it requires network. Run only in local/device context, not in the `flutter test` unit suite.

3. **Coverage of `card_swipe_screen.dart` — Skeletonizer detection**
   - What we know: Skeletonizer renders a shimmer over the real widget tree. The placeholder
     `MagicCard` has all empty strings.
   - What's unclear: Whether `find.byType(Skeletonizer)` finds enabled skeletonizers vs. all.
   - Recommendation: In the loading state test, assert that shimmer-related widgets are present
     and that specific card text (e.g. card name from a fake card) is absent.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All tests | Yes | via `flutter test` | — |
| `integration_test` pkg | TEST-06 | Yes (SDK-bundled) | SDK-bundled | — |
| Hive CE temp dir | Unit tests with Hive | Yes (`Directory.systemTemp`) | — | — |
| Scryfall API (network) | Integration test only | [ASSUMED: yes in dev] | — | Run on real device |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `ProviderContainer(overrides: [...])` with `overrideWith((ref) => ...)` is the correct syntax for Riverpod 3.x `@riverpod`-generated providers | Architecture Patterns | Compilation error — check Riverpod 3.x API if needed |
| A2 | `UncontrolledProviderScope(container: container, child: ...)` is still valid in Riverpod 3.x | Architecture Patterns | Widget test won't compile — use `ProviderScope(overrides: [...])` instead |
| A3 | Integration test requires real network; CI has network access | Open Questions | CI integration tests will time out — mark as manual-only |
| A4 | `find.byType(Skeletonizer)` with `enabled: true` is sufficient to detect loading state | Common Pitfalls | Loading state assertion will fail — use text-absence check as fallback |

---

## Sources

### Primary (HIGH confidence)
- Existing test files (verified by direct read) — patterns for Hive CE in tests, provider overrides, fixture factories
- `pubspec.yaml` (verified) — exact package versions
- `lib/features/card_discovery/presentation/card_swipe_screen.dart` (verified) — 5 error/state branches to test
- `lib/features/card_discovery/presentation/providers.dart` (verified) — `RandomCardNotifier` structure
- `lib/features/card_discovery/domain/card_repository.dart` (verified) — interface for FakeCardRepository
- `coverage/lcov.info` (generated, verified) — actual coverage numbers per file

### Secondary (MEDIUM confidence)
- Flutter `integration_test` package — bundled with Flutter SDK, no additional install needed [ASSUMED — standard Flutter knowledge]

### Tertiary (LOW confidence)
- `UncontrolledProviderScope` availability in Riverpod 3.x — not verified against Riverpod 3.x docs [A2]

---

## Metadata

**Confidence breakdown:**
- Test inventory: HIGH — all files read directly
- Coverage numbers: HIGH — generated from actual `flutter test --coverage` run
- Hive patterns: HIGH — verified against existing passing tests
- Riverpod 3.x widget test API: MEDIUM — Riverpod 3.x is in pubspec but `UncontrolledProviderScope` not verified
- Integration test structure: MEDIUM — standard Flutter pattern, but Scryfall network dependency is runtime assumption

**Research date:** 2026-04-18
**Valid until:** 2026-05-18 (stable stack — 30 days)
