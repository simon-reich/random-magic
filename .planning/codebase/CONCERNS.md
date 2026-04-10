# Codebase Concerns

**Analysis Date:** 2026-04-10

---

## Tech Debt

**CLAUDE.md Documents Riverpod as 2.x but Codebase Uses 3.x:**
- Issue: `CLAUDE.md` tech stack table states "Riverpod 2.x" and the note at line 88 says an upgrade to 3.x is pending. The actual `pubspec.yaml` already pins `flutter_riverpod: ^3.0.0`, `riverpod_annotation: ^4.0.0`, and `riverpod_generator: ^4.0.0`. The briefing document is stale.
- Files: `CLAUDE.md` (lines 28, 88–91), `pubspec.yaml` (lines 37–38, 56)
- Impact: Agents reading CLAUDE.md may generate Riverpod 2.x–style code (e.g., `ProviderRef` instead of `Ref`, old `@riverpod` annotation usage).
- Fix approach: Update CLAUDE.md tech stack table to "Riverpod 3.x" and remove the upgrade note.

**`_buildDio` Is Private But Documented as Test-Callable:**
- Issue: `dio_client.dart` line 18–19 says "Separated from the provider so tests can call `_buildDio` directly without needing a `ProviderContainer`." However, `_buildDio` is a library-private function (leading underscore) and cannot be called from test files in other libraries.
- Files: `lib/core/network/dio_client.dart` (lines 18–20)
- Impact: Any test that tries to follow this documented pattern will get a compile error. Tests must use `ProviderContainer` with overrides instead.
- Fix approach: Either rename to `buildDio` (public) or remove the misleading doc comment. Preferred: remove the claim and document the override pattern instead.

**AppBar `fontSize: 20` Is a Magic Number:**
- Issue: `app_theme.dart` line 109 sets `fontSize: 20` directly on `AppBarTheme.titleTextStyle` instead of using a typography token or `AppSpacing`-equivalent text size constant.
- Files: `lib/core/theme/app_theme.dart` (line 109)
- Impact: Minor inconsistency with the project's "no magic numbers" rule. If the app ever needs a global type-scale adjustment this value will be missed.
- Fix approach: Add text size constants to `AppColors`/`AppTheme` or use `Theme.of(context).textTheme` styles as the source of truth.

**`legalities` Field Uses a Runtime Cast That Can Panic:**
- Issue: `MagicCard.fromJson` at line 85 calls `rawLegalities.cast<String, String>()`. The Scryfall API currently returns all legality values as strings (e.g. `"legal"`, `"not_legal"`), but `cast<>()` is a lazy runtime cast — a schema change from Scryfall will throw a `CastError` at read time, not at parse time, making failures hard to trace.
- Files: `lib/shared/models/magic_card.dart` (line 85)
- Impact: Silent data corruption potential; a Scryfall API change could crash at an unexpected call site.
- Fix approach: Replace with explicit mapping: `rawLegalities.map((k, v) => MapEntry(k, v.toString()))` or add a try-catch in `fromJson` with a graceful fallback to an empty map.

**No Rate-Limiting or Back-off on Rapid Swipes:**
- Issue: `RandomCardNotifier.refresh()` fires a new Scryfall request immediately with no debounce, throttle, or exponential back-off. Scryfall's documented limit is 10 req/s. A rapid-swipe user can exceed this, triggering 429/503 responses that are currently unmapped to a typed failure.
- Files: `lib/features/card_discovery/presentation/providers.dart` (lines 37–40), `lib/features/card_discovery/data/scryfall_api_client.dart` (`_mapDioException`)
- Impact: Users could hit Scryfall rate limits and see generic network errors. Repeat offenders risk being temporarily blocked by Scryfall.
- Fix approach: Add a `sendTimeout` to `ApiConstants`, add a debounce delay inside `refresh()`, and map HTTP 429/503 to a new `RateLimitedFailure` in `failures.dart`.

**`sendTimeout` Is Not Configured on Dio:**
- Issue: `dio_client.dart` sets `connectTimeout` and `receiveTimeout` but not `sendTimeout`. For POST/PUT requests (future features) this means upload hangs are unbounded.
- Files: `lib/core/network/dio_client.dart` (lines 23–25), `lib/core/constants/api_constants.dart`
- Impact: Low risk now (all requests are GET), but will become a problem when any write endpoint is added.
- Fix approach: Add `static const Duration sendTimeout = Duration(seconds: 10)` to `ApiConstants` and wire it into `BaseOptions`.

---

## Missing Implementations (Placeholder Screens)

**Five of Seven Screens Are Placeholder Stubs:**
- Issue: The following screens contain only a `Text(...)` placeholder body with a comment that the real implementation comes "in a later ticket":
  - `lib/features/card_discovery/presentation/card_swipe_screen.dart` — core feature, no swipe UI
  - `lib/features/filters/presentation/filter_settings_screen.dart` — no filter controls
  - `lib/features/favourites/presentation/favourites_screen.dart` — no card list
  - `lib/features/favourites/presentation/favourite_swipe_screen.dart` — displays raw ID string
  - `lib/features/card_detail/presentation/card_detail_screen.dart` — displays raw card ID string
- Impact: The app is functionally non-operational beyond routing. Any end-to-end test would fail.
- Fix approach: Tracked as future Jira tickets per project plan. Priority: `card_swipe_screen.dart` first as it exercises the wired `randomCardProvider`.

**Entire Data and Domain Layers Missing for Three Features:**
- Issue: Per CLAUDE.md spec, the following should exist but do not:
  - `lib/features/filters/data/` — `ScryfallQueryBuilder`, `FilterPresetRepository` (directories empty)
  - `lib/features/filters/domain/` — `FilterPreset` model, `FilterSettings` model (directory empty)
  - `lib/features/favourites/data/` — `FavouritesRepository` with Hive CE (directory empty)
  - `lib/features/favourites/domain/` — `FavouriteCard` model (directory empty)
  - `lib/features/card_detail/domain/` — empty directory
- Impact: Filters never apply to Scryfall queries. Favourites cannot be saved, read, or deleted. No Hive CE boxes are registered or opened.
- Fix approach: Implement per CLAUDE.md Backend Agent spec, starting with `FilterPreset`/`FilterSettings` models and `ScryfallQueryBuilder`.

**Hive CE Is Declared as a Dependency But Never Initialized:**
- Issue: `hive_ce` and `hive_ce_flutter` are in `pubspec.yaml` but `main.dart` has no `await Hive.initFlutter()` call, no boxes are opened, and no `TypeAdapter`s are registered.
- Files: `lib/main.dart`, `pubspec.yaml` (lines 42–43)
- Impact: Any Hive read/write call will throw at runtime. The dependency is dead weight until initialisation is wired.
- Fix approach: Add `WidgetsFlutterBinding.ensureInitialized()` + `await Hive.initFlutter()` to `main()` before `runApp`. Register adapters for `FavouriteCard` and `FilterPreset` once those models exist.

**`cached_network_image` Is Declared but Never Used:**
- Issue: `cached_network_image: ^3.4.1` is in `pubspec.yaml` but zero source files import or use `CachedNetworkImage`.
- Files: `pubspec.yaml` (line 41)
- Impact: Unused dependency adds APK/IPA size and a future version-conflict surface. No functional impact today.
- Fix approach: Leave in place if image caching is planned for `CardSwipeScreen`; otherwise remove now and re-add when needed.

---

## Missing Critical Features

**No `MtgColor`, `CardType`, or `Rarity` Enums:**
- Problem: CLAUDE.md specifies shared enums at `lib/shared/models/` for `MtgColor`, `CardType`, and `Rarity`. These do not exist. The `MagicCard.rarity` field is a raw `String`.
- Blocks: Filter UI cannot bind to typed values; `ScryfallQueryBuilder` cannot produce type-safe queries.
- Files: `lib/shared/models/` (only `magic_card.dart` exists)

**No Shared Widget Library:**
- Problem: `lib/shared/widgets/` exists as an empty directory. CLAUDE.md requires reusable components for error states and empty states. All placeholder screens that will be implemented will need these widgets.
- Blocks: Consistent error/empty/loading states across all screens.
- Files: `lib/shared/widgets/` (empty)

**No GoRouter Error Route:**
- Problem: `appRouter` in `lib/core/router/app_router.dart` has no `errorBuilder` or `onException` handler. Unknown routes produce GoRouter's default debug error screen.
- Files: `lib/core/router/app_router.dart`
- Impact: Navigating to an invalid deep-link URL shows an unbranded error screen.
- Fix approach: Add `errorBuilder: (context, state) => const NotFoundScreen()` to `GoRouter(...)`.

---

## Test Coverage Gaps

**Effectively Zero Test Coverage:**
- What's not tested: All business logic, all data parsing, all provider state management, all widget rendering.
- Files:
  - `test/app_test.dart` — single placeholder assertion (`expect(true, isTrue)`)
  - `test/unit/card_discovery/` — empty (`.gitkeep` only)
  - `test/unit/filters/` — empty
  - `test/unit/favourites/` — empty
  - `test/unit/card_detail/` — empty
  - `test/widgets/card_discovery/` — empty
  - `test/widgets/filters/` — empty
  - `test/widgets/favourites/` — empty
  - `test/widgets/card_detail/` — empty
  - `test/fixtures/` — empty
  - `integration_test/` — empty (`.gitkeep` only)
- Risk: `MagicCard.fromJson` double-faced card logic, all price-null paths, all failure mapping in `ScryfallApiClient`, and the `RandomCardNotifier` state machine are completely untested. Regressions will not be caught by CI.
- Priority: High — CI runs `flutter test` and passes only because the placeholder test always passes, giving false confidence.

**Critical Edge Cases Specified in CLAUDE.md Are Untested:**
- What's not tested:
  - Card with no `image_uris` (double-faced fallback path in `MagicCard._firstFaceImageUris`)
  - Card with all price fields null
  - Card with no `flavor_text`
  - Filter preset with no filters → unrestricted query
  - Two presets with identical names
- Files: `lib/shared/models/magic_card.dart`, `test/fixtures/` (empty)
- Risk: These are explicitly flagged as required by the QA spec. None are covered.
- Priority: High — `_firstFaceImageUris` returns `{}` on empty faces, producing an all-null `CardImageUris`. If UI dereferences `.normal!` it will crash.

---

## Fragile Areas

**`MagicCard.fromJson` Crashes on Missing Required Fields:**
- Files: `lib/shared/models/magic_card.dart` (lines 72–82)
- Why fragile: Fields `id`, `name`, `type_line`, `rarity`, `set`, `set_name`, `collector_number`, `released_at` are cast with `as String` (non-nullable). If Scryfall ever omits one of these (e.g. a token card or an art card), the cast throws a `TypeError` that surfaces as `AsyncError` in the provider with no actionable message.
- Safe modification: Wrap `fromJson` in a try-catch that returns a `Failure<ParseFailure>` rather than throwing, and add a `ParseFailure` subclass to `lib/shared/failures.dart`.
- Test coverage: None.

**`_ScryfallErrorInterceptor` Passes All Errors Through Without Logging:**
- Files: `lib/core/network/dio_client.dart` (lines 41–45)
- Why fragile: The interceptor is a no-op. In debug builds there is no visibility into raw Scryfall errors (e.g. unexpected 5xx, response body details). Debugging production issues requires adding logging after the fact.
- Safe modification: Add `kDebugMode` guarded `debugPrint` inside `onError` or replace with Dio's built-in `LogInterceptor(requestBody: true, responseBody: true)` in debug builds only.

---

## Security Considerations

**No Input Sanitization on Query Strings Passed to Scryfall:**
- Risk: `_fetch({String? query})` in `providers.dart` and `_buildQueryParams` in `scryfall_api_client.dart` pass the query string directly to Scryfall. While Scryfall itself handles syntax validation (returning 422), if query construction logic in the future `ScryfallQueryBuilder` is buggy, it could construct queries that leak internal filter state or return unintended results.
- Files: `lib/features/card_discovery/presentation/providers.dart` (line 44), `lib/features/card_discovery/data/scryfall_api_client.dart` (line 47)
- Current mitigation: Scryfall returns 422 for invalid syntax; this is mapped to `InvalidQueryFailure`.
- Recommendations: When `ScryfallQueryBuilder` is implemented, add unit tests that verify its output for boundary inputs (empty strings, special characters, excessively long values).

---

*Concerns audit: 2026-04-10*
