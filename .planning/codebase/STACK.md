# Technology Stack

**Analysis Date:** 2026-04-10

## Languages

**Primary:**
- Dart ^3.11.4 - All application code in `lib/`

**Secondary:**
- YAML - Configuration (`pubspec.yaml`, `analysis_options.yaml`, `.github/workflows/ci.yml`)

## Runtime

**Environment:**
- Flutter stable channel (no pinned version — uses latest stable via CI action)

**Package Manager:**
- pub (Flutter's built-in package manager)
- Lockfile: `pubspec.lock` present and committed

## Frameworks

**Core:**
- Flutter (stable channel) - Cross-platform mobile UI framework; targets iOS and Android
- Material 3 (`useMaterial3: true`) - Design system; configured via `AppTheme.dark` in `lib/core/theme/app_theme.dart`

**State Management:**
- flutter_riverpod 3.3.1 - Reactive state management with `ProviderScope` at app root
- riverpod_annotation 4.0.2 - Code-gen annotations (`@riverpod`, `@Riverpod(keepAlive: true)`)
- riverpod_generator 4.0.3 (dev) - Generates `.g.dart` provider boilerplate from annotations

**Navigation:**
- go_router 17.2.0 - Declarative routing; `StatefulShellRoute` for bottom-nav tab persistence; configured in `lib/core/router/app_router.dart`

**HTTP:**
- dio 5.9.2 - HTTP client with interceptors; singleton provider in `lib/core/network/dio_client.dart`

**Local Storage:**
- hive_ce 2.19.3 - Pure Dart key-value/box database; used for favourites and filter presets
- hive_ce_flutter 2.3.4 - Flutter-specific Hive CE initialisation helpers

**Image Loading:**
- cached_network_image 3.4.1 - Network image caching for Scryfall card images

**Testing:**
- flutter_test (SDK bundled) - Widget and unit test runner
- mockito 5.6.4 (dev) - Mock generation for injectable dependencies

**Build/Dev:**
- build_runner 2.13.1 (dev) - Code generation runner for Riverpod and Hive adapters

**Linting:**
- flutter_lints 6.0.0 (dev) - Activates `package:flutter_lints/flutter.yaml` ruleset; config in `analysis_options.yaml`

## Key Dependencies

**Critical:**
- `flutter_riverpod` 3.3.1 - All state is managed through Riverpod providers; app will not compile without it
- `dio` 5.9.2 - Sole HTTP transport layer; all Scryfall calls go through the `dioProvider` singleton
- `hive_ce` 2.19.3 - Persistent storage for favourites and filter presets; chosen over Isar to avoid AGP and source_gen conflicts (see ADR-006)
- `go_router` 17.2.0 - All navigation; widgets must never call `Navigator.push` directly

**Infrastructure:**
- `cached_network_image` 3.4.1 - Card images served from Scryfall CDN; caching prevents redundant downloads
- `riverpod_generator` 4.0.3 - Generates `providers.g.dart` and `dio_client.g.dart`; must run `build_runner` after provider changes
- `build_runner` 2.13.1 - Run with `flutter pub run build_runner build --delete-conflicting-outputs`

## Configuration

**Environment:**
- No `.env` file or runtime environment variables required
- Scryfall API requires no authentication — all connection settings are compile-time constants in `lib/core/constants/api_constants.dart`
- Key constants: `baseUrl = 'https://api.scryfall.com'`, `connectTimeout = 10s`, `receiveTimeout = 10s`, `userAgent = 'RandomMagicApp/1.0'`

**Build:**
- `pubspec.yaml` - Package manifest and Flutter asset/font configuration
- `analysis_options.yaml` - Extends `package:flutter_lints/flutter.yaml`; no additional custom rules currently active
- `build_runner` config is implicit (no separate `build.yaml` present)

## Platform Requirements

**Development:**
- Flutter stable channel
- Dart SDK ^3.11.4
- `flutter pub get` then `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate `.g.dart` files

**Production:**
- iOS (Xcode required for device builds; `ios/` directory present)
- Android (AGP; `android/` directory present; debug APK built in CI)
- No backend server required — app calls Scryfall API directly

## CI/CD

**Pipeline:** GitHub Actions — `.github/workflows/ci.yml`

**Jobs:**
1. `analyze-and-test` (ubuntu-latest): `flutter analyze --fatal-infos` then `flutter test`
2. `build-apk` (ubuntu-latest, depends on job 1): `flutter build apk --debug` (smoke test only)

**Triggers:** Push and pull request to `main`

---

*Stack analysis: 2026-04-10*
