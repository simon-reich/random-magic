# Coding Conventions

**Analysis Date:** 2026-04-10

## Naming Patterns

**Files:**
- `snake_case.dart` for all Dart source files
- Generated files follow the same pattern with `.g.dart` suffix (e.g., `providers.g.dart`, `dio_client.g.dart`)
- Feature screens: `<feature>_screen.dart` (e.g., `card_swipe_screen.dart`, `card_detail_screen.dart`)
- Repository interfaces: `<noun>_repository.dart` (e.g., `card_repository.dart`)
- Repository implementations: `<noun>_repository_impl.dart` (e.g., `card_repository_impl.dart`)
- API clients: `<service>_api_client.dart` (e.g., `scryfall_api_client.dart`)
- Constants classes: `<domain>_constants.dart` (e.g., `api_constants.dart`, `spacing.dart`)

**Classes:**
- `PascalCase` for all classes
- Abstract constant classes use `abstract final class`: `AppSpacing`, `AppColors`, `AppTheme`, `ApiConstants`, `AppRoutes`
- Repository interfaces use `abstract interface class`: `CardRepository`
- Domain models are plain classes: `MagicCard`, `CardImageUris`, `CardPrices`
- Sealed hierarchies use `sealed class` + `final class` subclasses: `Result<T>`, `AppFailure`

**Providers (Riverpod):**
- Functional providers: `camelCase` function name → generated `camelCaseProvider` (e.g., `scryfallApiClient` → `scryfallApiClientProvider`)
- Notifier classes: `PascalCaseNotifier` → generated `camelCaseProvider` (e.g., `RandomCardNotifier` → `randomCardProvider`)
- `keepAlive: true` annotation on singleton providers (e.g., `dioProvider`)

**Constants:**
- Route path strings as `static const String` on `AppRoutes`: `discovery`, `cardDetail`, `filters`
- Spacing as `static const double` on `AppSpacing`: `xs`, `sm`, `md`, `lg`, `xl`, `xxl`
- Colors as `static const Color` on `AppColors`: grouped by role (Backgrounds, Accents, Content, Semantic)

## Code Style

**Formatting:**
- Official Dart formatter (`dart format`) via `flutter analyze`
- Linting: `package:flutter_lints/flutter.yaml` — the standard Flutter recommended lint set
- No custom rules currently added beyond the default set (`analysis_options.yaml`)
- CI enforces `flutter analyze --fatal-infos` (treats info-level issues as failures)

**Linting:**
- `flutter_lints` package v6.x
- `analysis_options.yaml` at project root includes `package:flutter_lints/flutter.yaml`
- No rules currently disabled or overridden

**`const` usage:**
- `const` constructors used everywhere possible — all immutable model classes (`MagicCard`, `CardImageUris`, etc.)
- Widget constructors always include `const` where applicable: `const CardSwipeScreen({super.key})`
- Abstract constant classes declared `abstract final class` (not instantiable)

**Named parameters:**
- All widget constructors with 2+ parameters use named parameters
- Required parameters explicitly marked `required`: `CardDetailScreen({super.key, required this.cardId})`
- Optional fields declared nullable without `required`: `this.flavorText`

## Import Organization

**Order:**
1. Dart SDK imports (e.g., `dart:async`) — none currently in use
2. Flutter/package imports (alphabetical): `package:dio/...`, `package:flutter/...`, `package:go_router/...`, `package:riverpod_annotation/...`
3. Internal package imports: `package:random_magic/...` (always use package-qualified paths, never relative)

**Path style:**
- All internal imports use `package:random_magic/` prefix — no relative imports (e.g., `../`)
- Example: `import 'package:random_magic/shared/failures.dart';`

**Part declarations:**
- Generated files declared with `part 'providers.g.dart';` directly after imports
- Build runner annotation files follow this pattern in every provider file

## Error Handling

**Pattern: `Result<T>` sealed class + `AppFailure` sealed class**

Defined in `lib/shared/result.dart` and `lib/shared/failures.dart`.

```dart
// Repository methods always return Result<T>
Future<Result<MagicCard>> getRandomCard({String? query});

// API client maps network errors to typed failures — never throws
return switch (result) {
  Success(:final value) => value,
  Failure(:final error) => throw error,  // re-thrown for AsyncValue.guard
};
```

**Failure types** (exhaustive — compiler-enforced via sealed class):
- `CardNotFoundFailure` — HTTP 404 from Scryfall (no cards match query)
- `InvalidQueryFailure` — HTTP 422 from Scryfall (malformed query syntax)
- `NetworkFailure({String? message})` — connection timeout, no internet, DNS failure

**Rules:**
- API clients never throw — they return `Failure(...)` for all error cases
- Presentation layer uses `AsyncValue.when(data:, loading:, error:)` — all three states always handled
- `_mapDioException` in `ScryfallApiClient` maps `DioException` → `AppFailure` by HTTP status code

## Logging

**Framework:** None (no structured logging library)

**Pattern:** No `print` calls in production code (enforced by `flutter_lints` `avoid_print` rule). Errors carry optional `message` field on `NetworkFailure` for debugging context.

## Comments

**Doc comments (`///`):**
- Every public class must have a `///` doc comment
- Every public method must have a `///` doc comment
- Every public Riverpod provider must have a `///` doc comment
- Pattern: describe behaviour and types, not just names
- Cross-reference related types using `[TypeName]` syntax (e.g., `/// Returns [Success<MagicCard>]`)

**Inline comments (`//`):**
- Explain *why*, not *what*
- Used for non-obvious decisions: `// Double-faced cards omit top-level image_uris and put them in card_faces.`
- Used to mark intentional nullable fields: `// Intentionally nullable — hidden in UI when absent (not shown as blank).`
- Used on generated code boundaries: `// GENERATED CODE - DO NOT MODIFY BY HAND`

**Doc comment examples from codebase:**
```dart
/// Represents a single Magic: The Gathering card as returned by the Scryfall API.
///
/// All fields are immutable. Use [MagicCard.fromJson] to deserialise a
/// Scryfall `/cards/random` or `/cards/{id}` response.
class MagicCard { ... }

/// Fetches a single random card from Scryfall.
///
/// [query] is an optional Scryfall syntax filter string (e.g. `"color:R type:Creature"`).
/// Returns:
/// - [Success<MagicCard>] on HTTP 200 with a parseable response.
/// - [Failure<CardNotFoundFailure>] on HTTP 404 (no cards match [query]).
Future<Result<MagicCard>> getRandomCard({String? query}) async { ... }
```

## Function Design

**Size:** Functions kept small and single-purpose. Private helpers extracted when logic is non-trivial (e.g., `_buildQueryParams`, `_mapDioException`, `_firstFaceImageUris` in `ScryfallApiClient` and `MagicCard`).

**Parameters:**
- Named parameters for constructors with 2+ params
- Nullable optional parameters preferred over overloads: `{String? query}`
- `required` keyword used for mandatory named params

**Return Values:**
- Always use `Result<T>` for fallible repository/client operations
- Widget `build` methods return `Widget`
- No void-returning async methods that silently swallow errors

## Widget Design

**Base class:** `StatelessWidget` for pure display; `ConsumerWidget` / `ConsumerStatefulWidget` for Riverpod access — no `setState`

**Navigation:**
- All navigation via `GoRouter` using `context.go(AppRoutes.x)` or `context.push(AppRoutes.x)` — no direct `Navigator.push`
- Named route constants defined on `AppRoutes` in `lib/core/router/app_router.dart`

**Theming:**
- No hardcoded hex colours — use `AppColors.*` constants or `Theme.of(context).colorScheme.*`
- No hardcoded numeric spacing — use `AppSpacing.*` constants
- Dark-mode-only: `AppTheme.dark` wired at app root; `MaterialApp.router` uses it exclusively

## Module Design

**Exports:** No barrel files. Each file is imported directly by its `package:random_magic/...` path.

**Feature isolation:**
- Features must not import from each other's `data/` or `presentation/` layers
- Shared types live in `lib/shared/models/` or `lib/shared/widgets/`
- `lib/core/` is infrastructure only — no feature logic

**Generated code:**
- Riverpod generators produce `.g.dart` files — committed to the repo
- `part '*.g.dart'` declarations required in any file using `@riverpod` annotations
- Do not edit `.g.dart` files manually; regenerate with `dart run build_runner build`

---

*Convention analysis: 2026-04-10*
