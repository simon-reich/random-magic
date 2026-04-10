# Testing Patterns

**Analysis Date:** 2026-04-10

## Test Framework

**Runner:**
- `flutter_test` (Flutter SDK built-in)
- No separate config file — Flutter uses `flutter test` directly
- Mockito v5.4.4 for mock generation

**Assertion Library:**
- `flutter_test` includes `expect`, `isTrue`, `isFalse`, `equals`, `throwsA`, `isA` matchers

**Run Commands:**
```bash
flutter test                    # Run all tests
flutter test --coverage         # Run with coverage output
flutter analyze --fatal-infos   # Static analysis (CI enforces this before tests)
```

CI pipeline (`.github/workflows/ci.yml`) runs `flutter analyze --fatal-infos` then `flutter test` on every push and pull request to `main`.

## Test File Organization

**Location:**
- Unit tests: `test/unit/<feature>/` — one directory per feature
- Widget tests: `test/widgets/<feature>/` — one directory per feature
- Fixtures: `test/fixtures/` — shared fake data and helpers
- Integration tests: `integration_test/` — full app flow tests (directory exists, no files yet)

**Current state:**
- Directory structure is scaffolded with `.gitkeep` placeholders; only `test/app_test.dart` contains a live (placeholder) test
- No feature tests exist yet — all `test/unit/` and `test/widgets/` subdirectories are empty

**Naming (prescribed by CLAUDE.md):**
- Unit test files: `<subject>_test.dart` placed in `test/unit/<feature>/`
- Widget test files: `<screen>_screen_test.dart` placed in `test/widgets/<feature>/`

**Directory layout:**
```
test/
├── app_test.dart               # Placeholder; remove once feature tests exist
├── fixtures/                   # Fake card data, fake presets (currently empty)
├── unit/
│   ├── card_discovery/         # Unit tests for ScryfallApiClient, CardRepository
│   ├── card_detail/
│   ├── favourites/
│   └── filters/
└── widgets/
    ├── card_discovery/         # Widget tests for CardSwipeScreen
    ├── card_detail/
    ├── favourites/
    └── filters/

integration_test/               # Full app flow tests (empty)
```

## Test Structure

**Suite Organization (prescribed pattern from CLAUDE.md + flutter_test conventions):**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([CardRepository])
void main() {
  group('ScryfallApiClient', () {
    late MockCardRepository mockRepository;

    setUp(() {
      mockRepository = MockCardRepository();
    });

    test('returns Success<MagicCard> on HTTP 200', () async {
      // arrange
      when(mockRepository.getRandomCard()).thenAnswer(
        (_) async => const Success(fakeMagicCard),
      );
      // act
      final result = await mockRepository.getRandomCard();
      // assert
      expect(result, isA<Success<MagicCard>>());
    });

    test('returns Failure<CardNotFoundFailure> on HTTP 404', () async { ... });
  });
}
```

**Patterns prescribed in CLAUDE.md:**
- `setUp` / `tearDown` for initialising mocks and test state
- Arrange-Act-Assert structure within each `test()`
- `group()` to scope related tests by class or method
- Coverage target: 80%+ on logic classes (repositories, notifiers, API clients)

## Mocking

**Framework:** Mockito v5.4.4 with code generation

**Pattern:**
```dart
// Annotate the test file
@GenerateMocks([CardRepository, ScryfallApiClient])
void main() { ... }

// Generate mocks with:
// dart run build_runner build

// Use the generated mock
final mock = MockCardRepository();
when(mock.getRandomCard(query: anyNamed('query')))
    .thenAnswer((_) async => const Success(fakeCard));
```

**What to mock:**
- `CardRepository` in notifier/provider tests — never use a real repository
- `ScryfallApiClient` (with a mock `Dio`) in repository implementation tests
- `Dio` directly when testing `ScryfallApiClient._mapDioException` logic

**What NOT to mock:**
- `MagicCard.fromJson` — test it with real JSON fixtures
- `AppFailure` subclasses — use the real sealed classes
- `Result<T>` — use real `Success` / `Failure` instances

**Riverpod test injection:**
```dart
// Override a provider in tests using ProviderContainer / ProviderScope override
final container = ProviderContainer(
  overrides: [
    cardRepositoryProvider.overrideWithValue(mockRepository),
  ],
);
```

## Fixtures and Factories

**Test Data (prescribed location: `test/fixtures/`):**
```dart
// Expected pattern — not yet implemented, but prescribed by CLAUDE.md
// test/fixtures/fake_cards.dart
const fakeMagicCard = MagicCard(
  id: 'fake-id-001',
  name: 'Fake Dragon',
  typeLine: 'Creature — Dragon',
  rarity: 'rare',
  setCode: 'tst',
  setName: 'Test Set',
  collectorNumber: '001',
  releasedAt: '2024-01-01',
  imageUris: CardImageUris(normal: 'https://example.com/card.jpg'),
  legalities: {'modern': 'legal'},
);
```

**Location:**
- `test/fixtures/` — shared across unit and widget tests (currently empty, `.gitkeep` only)

## Coverage

**Requirements:** 80%+ coverage target on logic classes (repositories, notifiers, API clients), per CLAUDE.md. Not currently enforced automatically — no coverage threshold in CI.

**View Coverage:**
```bash
flutter test --coverage
# Outputs to coverage/lcov.info
genhtml coverage/lcov.info -o coverage/html   # if lcov installed
```

## Test Types

**Unit Tests (`test/unit/`):**
- Scope: Pure Dart logic — API clients, repositories, domain models, `fromJson` parsing
- No Flutter framework involvement — `test()` not `testWidgets()`
- All external dependencies (Dio, Hive) mocked

**Widget Tests (`test/widgets/`):**
- Scope: Flutter screens and widgets
- Uses `testWidgets()` with `WidgetTester`
- Tests all four states: loading, success, error, empty
- Riverpod providers overridden via `ProviderScope(overrides: [...])`

**Integration Tests (`integration_test/`):**
- Scope: Full app flow (e.g., swipe → card loads → save to favourites)
- Uses `flutter_test` integration test runner
- Directory created but empty — not yet implemented

## Critical Edge Cases to Test

Per CLAUDE.md — these must be covered:

- **Double-faced cards**: `image_uris` absent at top level → fallback to `card_faces[0].image_uris` (tested via `MagicCard.fromJson`)
- **All price fields null**: `CardPrices` with all null fields → UI shows "N/A" (not a crash)
- **No `flavor_text`**: field must be hidden in UI, not shown as blank string
- **Empty filter query**: no `q` param sent to Scryfall → unrestricted random card returned
- **Duplicate preset names**: two `FilterPreset` records with identical names — prevent or handle gracefully

## Common Patterns

**Async Testing:**
```dart
test('getRandomCard returns Success on 200', () async {
  when(mockClient.getRandomCard()).thenAnswer(
    (_) async => const Success(fakeMagicCard),
  );
  final result = await repository.getRandomCard();
  expect(result, isA<Success<MagicCard>>());
  final success = result as Success<MagicCard>;
  expect(success.value.id, 'fake-id-001');
});
```

**Error / Failure Testing:**
```dart
test('getRandomCard returns CardNotFoundFailure on 404', () async {
  when(mockDio.get<Map<String, dynamic>>(any, queryParameters: anyNamed('queryParameters')))
      .thenThrow(DioException(
        requestOptions: RequestOptions(path: '/cards/random'),
        response: Response(
          statusCode: 404,
          requestOptions: RequestOptions(path: '/cards/random'),
        ),
        type: DioExceptionType.badResponse,
      ));
  final result = await client.getRandomCard();
  expect(result, isA<Failure<MagicCard>>());
  final failure = result as Failure<MagicCard>;
  expect(failure.error, isA<CardNotFoundFailure>());
});
```

**Widget State Testing:**
```dart
testWidgets('shows loading indicator while fetching card', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        randomCardProvider.overrideWith(() => LoadingNotifier()),
      ],
      child: const MaterialApp(home: CardSwipeScreen()),
    ),
  );
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

**`fromJson` / Parsing Tests:**
```dart
test('MagicCard.fromJson handles double-faced card', () {
  final json = {
    'id': 'dfc-001',
    'name': 'Day // Night',
    // no top-level image_uris
    'card_faces': [
      {'image_uris': {'normal': 'https://example.com/front.jpg'}},
      {'image_uris': {'normal': 'https://example.com/back.jpg'}},
    ],
    ...
  };
  final card = MagicCard.fromJson(json);
  expect(card.imageUris.normal, 'https://example.com/front.jpg');
});
```

---

*Testing analysis: 2026-04-10*
