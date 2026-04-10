# Architecture

**Analysis Date:** 2026-04-10

## Pattern Overview

**Overall:** Feature-first Clean Architecture with Riverpod dependency injection

**Key Characteristics:**
- Each feature is divided into three sub-layers: `data/`, `domain/`, `presentation/`
- Features are isolated — no cross-feature imports between `data/` or `presentation/` layers
- Cross-feature shared types live in `lib/shared/` (models, result types, failures)
- `lib/core/` provides app-wide infrastructure (network, routing, theme, constants) with no feature logic
- All async operations return `Result<T>` (a sealed class) — never throw from repositories or API clients

## Layers

**Core (Infrastructure):**
- Purpose: App-wide plumbing — not feature logic
- Location: `lib/core/`
- Contains: Dio HTTP client, GoRouter config, AppTheme, spacing/API constants
- Depends on: External packages (Dio, GoRouter, Flutter)
- Used by: Feature `data/` and `presentation/` layers

**Domain (Contracts):**
- Purpose: Abstract interfaces and pure models; no framework dependencies
- Location: `lib/features/<feature>/domain/`
- Contains: Repository abstract interfaces (e.g. `CardRepository`), domain models where feature-specific
- Depends on: `lib/shared/` only
- Used by: `data/` (implements interfaces), `presentation/` (reads interfaces via providers)

**Data (Implementations):**
- Purpose: Concrete I/O — HTTP clients, local DB, query builders
- Location: `lib/features/<feature>/data/`
- Contains: `ScryfallApiClient`, `CardRepositoryImpl`, future Hive CE repositories
- Depends on: `domain/` interfaces, `lib/core/network/`, `lib/shared/`
- Used by: `presentation/` providers only (never by other features' data layers)

**Presentation (UI + Providers):**
- Purpose: Flutter widgets and Riverpod providers that wire domain to UI
- Location: `lib/features/<feature>/presentation/`
- Contains: Screen widgets, Riverpod `@riverpod` providers, generated `.g.dart` files
- Depends on: `domain/` interfaces (via providers), `lib/shared/`, `lib/core/`
- Used by: `lib/core/router/` for route building

**Shared:**
- Purpose: Types needed by multiple features without creating cross-feature coupling
- Location: `lib/shared/`
- Contains: `MagicCard` model, `Result<T>` sealed class, `AppFailure` sealed class hierarchy
- Depends on: Nothing internal
- Used by: All features

## Data Flow

**Random Card Discovery:**

1. `RandomCardNotifier.build()` (in `lib/features/card_discovery/presentation/providers.dart`) is invoked on provider creation
2. Notifier calls `cardRepositoryProvider` → `CardRepositoryImpl`
3. `CardRepositoryImpl` delegates to `ScryfallApiClient.getRandomCard()` (in `lib/features/card_discovery/data/`)
4. `ScryfallApiClient` calls `GET /cards/random` via the shared `dioProvider` Dio instance
5. On success: returns `Success<MagicCard>` → notifier unwraps and emits `AsyncData<MagicCard>`
6. On failure: returns `Failure<AppFailure>` → notifier throws typed failure → emits `AsyncError`
7. `CardSwipeScreen` calls `.when(data:, loading:, error:)` on `AsyncValue<MagicCard>` to render correct state

**Provider Dependency Chain:**
```
dioProvider (keepAlive: true)
  └── scryfallApiClientProvider
        └── cardRepositoryProvider
              └── randomCardNotifierProvider (AsyncNotifier)
                    └── CardSwipeScreen (ConsumerWidget)
```

**State Management:**
- Riverpod 3.x with code generation (`@riverpod` / `@Riverpod(keepAlive: true)`)
- `AsyncNotifier` subclasses manage async state (loading / data / error)
- `AsyncValue.guard()` used for safe async wrapping
- Providers override in tests to inject fakes without touching Dio

## Key Abstractions

**Result<T> (sealed class):**
- Purpose: Type-safe success/failure without exceptions crossing layer boundaries
- Location: `lib/shared/result.dart`
- Pattern: `sealed class Result<T>` with `Success<T>` and `Failure<T>` subtypes; consumers use exhaustive `switch`

**AppFailure (sealed class):**
- Purpose: Typed failure taxonomy for all async operations
- Location: `lib/shared/failures.dart`
- Subtypes: `CardNotFoundFailure` (HTTP 404), `InvalidQueryFailure` (HTTP 422), `NetworkFailure` (transport errors)

**CardRepository (abstract interface):**
- Purpose: Decouples presentation providers from Dio/Scryfall — enables fake injection in tests
- Location: `lib/features/card_discovery/domain/card_repository.dart`
- Pattern: `abstract interface class CardRepository` with a single `getRandomCard({String? query})` method

**MagicCard (domain model):**
- Purpose: Single canonical card representation shared across all features
- Location: `lib/shared/models/magic_card.dart`
- Pattern: Immutable class with `factory MagicCard.fromJson(Map<String, dynamic>)` — handles double-faced cards and nullable price fields

## Entry Points

**App Bootstrap:**
- Location: `lib/main.dart`
- Triggers: Flutter runtime calls `main()`
- Responsibilities: Wraps app in `ProviderScope` (Riverpod container), mounts `RandomMagicApp`

**Root Widget:**
- Location: `lib/main.dart` → `RandomMagicApp`
- Triggers: Called by `main()`
- Responsibilities: Configures `MaterialApp.router` with `appRouter` and `AppTheme.dark`

**Router:**
- Location: `lib/core/router/app_router.dart`
- Triggers: Mounted by `RandomMagicApp`
- Responsibilities: Defines all named routes via `AppRoutes` constants; uses `StatefulShellRoute` for bottom nav tab isolation; full-screen routes (card detail, favourite swipe) sit above the shell

**Named Routes:**
- `AppRoutes.discovery` → `/` → `CardSwipeScreen`
- `AppRoutes.favourites` → `/favourites` → `FavouritesScreen`
- `AppRoutes.filters` → `/filters` → `FilterSettingsScreen`
- `AppRoutes.cardDetail` → `/card/:id` → `CardDetailScreen(cardId)`
- `AppRoutes.favouriteSwipe` → `/favourites/:id` → `FavouriteSwipeScreen(favouriteId)`

## Error Handling

**Strategy:** Typed sealed classes — no untyped exceptions cross layer boundaries

**Patterns:**
- `ScryfallApiClient` catches `DioException` and maps to `AppFailure` subtype before returning `Failure<T>`
- `RandomCardNotifier._fetch()` throws the typed `AppFailure` so `AsyncValue.guard` captures it as `AsyncError`
- UI consumes `AsyncValue.when(error:)` and switches on `AppFailure` subtype to show correct error state
- `_ScryfallErrorInterceptor` in `DioClient` passes errors through unchanged — mapping is the API client's job, not the transport layer

## Cross-Cutting Concerns

**Logging:** None — `_ScryfallErrorInterceptor` passes errors through; no structured logger configured yet

**Validation:** Scryfall query syntax errors surface as `InvalidQueryFailure` (HTTP 422); no client-side query validation implemented yet

**Authentication:** Not required — Scryfall API is public; no auth headers or token management

**Theme:** Dark mode only via `AppTheme.dark` (`lib/core/theme/app_theme.dart`); all colours from `AppColors`, all spacing from `AppSpacing`; `Theme.of(context)` used in widgets — no hardcoded values

**Dependency Injection:** Riverpod `ProviderScope` at root; providers declared with `@riverpod` codegen; override in tests via `ProviderContainer(overrides: [...])`

---

*Architecture analysis: 2026-04-10*
