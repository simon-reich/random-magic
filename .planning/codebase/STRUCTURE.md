# Codebase Structure

**Analysis Date:** 2026-04-10

## Directory Layout

```
random-magic/
├── lib/                          # All Dart application code
│   ├── main.dart                 # App entry point; mounts ProviderScope + RandomMagicApp
│   ├── core/                     # App-wide infrastructure (no feature logic)
│   │   ├── constants/            # Shared constants (spacing, API config)
│   │   ├── network/              # Dio client setup and interceptors
│   │   ├── router/               # GoRouter configuration and route constants
│   │   └── theme/                # AppTheme, AppColors (dark mode only)
│   ├── features/                 # Feature modules; each owns data/domain/presentation
│   │   ├── card_discovery/       # Random card fetching and swipe screen
│   │   │   ├── data/             # ScryfallApiClient, CardRepositoryImpl
│   │   │   ├── domain/           # CardRepository interface
│   │   │   └── presentation/     # CardSwipeScreen, Riverpod providers
│   │   ├── card_detail/          # Full-screen card detail view
│   │   │   ├── domain/           # (reuses MagicCard from shared/)
│   │   │   └── presentation/     # CardDetailScreen (placeholder)
│   │   ├── favourites/           # Save, view, delete, and swipe favourites
│   │   │   ├── data/             # FavouritesRepository (Hive CE) — not yet implemented
│   │   │   ├── domain/           # FavouriteCard model — not yet implemented
│   │   │   └── presentation/     # FavouritesScreen, FavouriteSwipeScreen (placeholders)
│   │   └── filters/              # Filter settings and preset management
│   │       ├── data/             # ScryfallQueryBuilder, FilterPresetRepository — not yet implemented
│   │       ├── domain/           # FilterPreset, FilterSettings models — not yet implemented
│   │       └── presentation/     # FilterSettingsScreen (placeholder)
│   └── shared/                   # Types shared across features
│       ├── models/               # MagicCard and sub-types (CardImageUris, CardPrices)
│       ├── result.dart           # Result<T> sealed class (Success / Failure)
│       └── failures.dart         # AppFailure sealed class hierarchy
├── test/                         # All tests
│   ├── app_test.dart             # Placeholder; remove once feature tests exist
│   ├── fixtures/                 # Fake card data, fake presets (empty)
│   ├── unit/                     # Pure Dart logic tests, mirroring lib/features/
│   │   ├── card_discovery/
│   │   ├── card_detail/
│   │   ├── favourites/
│   │   └── filters/
│   └── widgets/                  # Flutter widget tests, mirroring lib/features/
│       ├── card_discovery/
│       ├── card_detail/
│       ├── favourites/
│       └── filters/
├── integration_test/             # Full app flow tests (empty)
├── android/                      # Android host project
├── ios/                          # iOS host project
├── .planning/                    # GSD planning documents
│   └── codebase/                 # Codebase analysis docs (ARCHITECTURE.md, STRUCTURE.md, etc.)
├── .github/workflows/            # GitHub Actions CI/CD pipelines
├── pubspec.yaml                  # Package manifest and dependency versions
└── analysis_options.yaml         # Dart lint configuration (flutter_lints)
```

## Directory Purposes

**`lib/core/constants/`:**
- Purpose: App-wide constant values; no logic
- Key files: `lib/core/constants/api_constants.dart` (Scryfall URL, timeouts, User-Agent), `lib/core/constants/spacing.dart` (`AppSpacing` with xs/sm/md/lg/xl/xxl values)

**`lib/core/network/`:**
- Purpose: Dio HTTP client configuration; interceptors; exposes `dioProvider`
- Key files: `lib/core/network/dio_client.dart` (provider + `_ScryfallErrorInterceptor`), `lib/core/network/dio_client.g.dart` (generated)

**`lib/core/router/`:**
- Purpose: GoRouter configuration and route path constants
- Key files: `lib/core/router/app_router.dart` (`AppRoutes` constants, `appRouter` instance, `_ShellScaffold` with bottom nav)

**`lib/core/theme/`:**
- Purpose: Single dark theme; all colours and typography in one place
- Key files: `lib/core/theme/app_theme.dart` (`AppColors`, `AppTheme.dark`)

**`lib/features/card_discovery/`:**
- Purpose: Core feature — fetches random cards from Scryfall and drives the swipe UI
- Implemented: `ScryfallApiClient`, `CardRepositoryImpl`, `CardRepository` interface, Riverpod providers (`scryfallApiClientProvider`, `cardRepositoryProvider`, `RandomCardNotifier`)
- Placeholder: `CardSwipeScreen`

**`lib/features/card_detail/`:**
- Purpose: Full-screen card detail view; receives `cardId` from route
- Implemented: `CardDetailScreen` (placeholder)

**`lib/features/favourites/`:**
- Purpose: Save cards to Hive CE local storage; list and swipe saved cards
- Implemented: `FavouritesScreen`, `FavouriteSwipeScreen` (both placeholders)
- Pending: `FavouritesRepository`, `FavouriteCard` model, Hive CE box setup

**`lib/features/filters/`:**
- Purpose: Build Scryfall query strings from user-selected filter settings; save named presets
- Implemented: `FilterSettingsScreen` (placeholder)
- Pending: `ScryfallQueryBuilder`, `FilterPresetRepository`, `FilterPreset` model, `FilterSettings` model

**`lib/shared/`:**
- Purpose: Types used by more than one feature — prevents cross-feature coupling
- Key files:
  - `lib/shared/models/magic_card.dart` — `MagicCard`, `CardImageUris`, `CardPrices`
  - `lib/shared/result.dart` — `Result<T>`, `Success<T>`, `Failure<T>`
  - `lib/shared/failures.dart` — `AppFailure`, `CardNotFoundFailure`, `InvalidQueryFailure`, `NetworkFailure`

**`test/fixtures/`:**
- Purpose: Static fake data for use across unit and widget tests
- Currently empty; populate with raw Scryfall JSON maps and `MagicCard` factory helpers

## Key File Locations

**Entry Points:**
- `lib/main.dart`: `main()` function; wraps `RandomMagicApp` in `ProviderScope`
- `lib/core/router/app_router.dart`: `appRouter` GoRouter instance; `AppRoutes` string constants

**Configuration:**
- `pubspec.yaml`: All package dependencies and SDK constraints
- `analysis_options.yaml`: Lint rules (extends `flutter_lints`)
- `lib/core/constants/api_constants.dart`: Scryfall base URL, timeouts, User-Agent string
- `lib/core/constants/spacing.dart`: `AppSpacing` layout values

**Core Logic:**
- `lib/shared/result.dart`: `Result<T>` — used by all repository methods
- `lib/shared/failures.dart`: `AppFailure` hierarchy — typed error taxonomy
- `lib/shared/models/magic_card.dart`: `MagicCard.fromJson()` — handles double-faced cards and null prices
- `lib/core/network/dio_client.dart`: Dio singleton provider; `_ScryfallErrorInterceptor`
- `lib/features/card_discovery/data/scryfall_api_client.dart`: HTTP call + failure mapping
- `lib/features/card_discovery/presentation/providers.dart`: `RandomCardNotifier` async state machine

**Testing:**
- `test/unit/<feature>/`: Pure Dart logic tests (repositories, query builders, models)
- `test/widgets/<feature>/`: Widget tests for all screen states
- `test/fixtures/`: Shared fake data helpers
- `integration_test/`: Full user-flow tests

## Naming Conventions

**Files:**
- All Dart files: `snake_case.dart` (e.g. `card_repository_impl.dart`, `dio_client.dart`)
- Generated files: `<source_file>.g.dart` (e.g. `providers.g.dart`, `dio_client.g.dart`) — do not edit manually

**Directories:**
- Feature directories: `snake_case` (e.g. `card_discovery/`, `card_detail/`)
- Layer directories: single word lowercase (`data/`, `domain/`, `presentation/`)

**Classes:**
- All classes: `PascalCase` (e.g. `CardRepositoryImpl`, `ScryfallApiClient`, `MagicCard`)
- Abstract interfaces: `PascalCase` without `I` prefix (e.g. `CardRepository` not `ICardRepository`)
- Abstract final utility classes: `PascalCase` (e.g. `AppSpacing`, `AppColors`, `ApiConstants`, `AppRoutes`)

**Providers:**
- Riverpod generated providers: `camelCaseProvider` (e.g. `dioProvider`, `cardRepositoryProvider`, `randomCardNotifierProvider`)
- Notifier classes: `PascalCaseNotifier` extending `_$PascalCaseNotifier` (codegen pattern)

## Where to Add New Code

**New Feature:**
- Create directory: `lib/features/<feature_name>/`
- Sub-layers: `data/`, `domain/`, `presentation/`
- Domain interface: `lib/features/<feature_name>/domain/<feature_name>_repository.dart`
- Implementation: `lib/features/<feature_name>/data/<feature_name>_repository_impl.dart`
- Providers: `lib/features/<feature_name>/presentation/providers.dart` (with `part 'providers.g.dart'`)
- Screen: `lib/features/<feature_name>/presentation/<screen_name>_screen.dart`
- Register route in: `lib/core/router/app_router.dart` using a new `AppRoutes` constant

**New Shared Model:**
- Add to: `lib/shared/models/<model_name>.dart`
- Use when: more than one feature imports the type

**New Failure Type:**
- Add to: `lib/shared/failures.dart` as a new `final class` extending `AppFailure`

**New Screen (within existing feature):**
- Implementation: `lib/features/<feature>/presentation/<screen_name>_screen.dart`
- Register in: `lib/core/router/app_router.dart`
- Tests: `test/widgets/<feature>/<screen_name>_screen_test.dart`

**New Repository (Hive CE):**
- Type adapter: `lib/features/<feature>/domain/<model_name>.dart` (annotate with Hive CE)
- Repository implementation: `lib/features/<feature>/data/<model_name>_repository_impl.dart`
- Provider: add to `lib/features/<feature>/presentation/providers.dart`

**New Unit Test:**
- Location: `test/unit/<feature>/<class_being_tested>_test.dart`

**New Widget Test:**
- Location: `test/widgets/<feature>/<screen_name>_screen_test.dart`

**Shared Test Fixtures:**
- Location: `test/fixtures/` — add factory functions returning fake `MagicCard` or JSON maps

## Special Directories

**`.planning/codebase/`:**
- Purpose: GSD codebase analysis documents for Claude agents
- Generated: By GSD mapping agents
- Committed: Yes

**`.dart_tool/`:**
- Purpose: Dart tooling cache, build_runner outputs
- Generated: Yes
- Committed: No (in `.gitignore`)

**`build/`:**
- Purpose: Flutter build output
- Generated: Yes
- Committed: No

**`.github/workflows/`:**
- Purpose: GitHub Actions CI pipeline definitions
- Generated: No
- Committed: Yes

---

*Structure analysis: 2026-04-10*
