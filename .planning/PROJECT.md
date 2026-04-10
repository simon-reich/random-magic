# Random Magic

## What This Is

Random Magic is a cross-platform mobile app (Flutter, iOS & Android) that lets users discover Magic: The Gathering cards by swiping through randomised results from the Scryfall API. Users can filter results by colour, type, rarity, and release date, save filter presets, maintain a favourites collection, and view detailed card information including prices and legalities.

## Core Value

Tactile, swipeable card discovery — the user should always be one swipe away from a new random card.

## Requirements

### Validated

<!-- Shipped and confirmed valuable — inferred from existing codebase (2026-04-10) -->

- ✓ Flutter project with feature-first Clean Architecture (`core/`, `features/`, `shared/`) — existing
- ✓ Dio HTTP client with `ScryfallApiClient`, `Result<T>` pattern, and typed `AppFailure` sealed class — existing
- ✓ `MagicCard` domain model with `fromJson()` factory handling double-faced cards and nullable price fields — existing
- ✓ `CardRepository` abstract interface + `CardRepositoryImpl` wiring `ScryfallApiClient` — existing
- ✓ `RandomCardNotifier` (Riverpod `AsyncNotifier`) with loading / data / error states — existing
- ✓ GoRouter navigation with `StatefulShellRoute` for tab persistence and named routes — existing
- ✓ Dark-mode `AppTheme` with `AppColors` and `AppSpacing` constants (no hardcoded values) — existing
- ✓ GitHub Actions CI pipeline: `flutter analyze --fatal-infos` → `flutter test` → `flutter build apk` — existing

### Active

<!-- Current scope — hypotheses until shipped -->

- [ ] **CardSwipeScreen** — full-screen card artwork, metadata overlay (name, mana cost, type line, rarity), swipe left/right for next card, shimmer loading state, three distinct error states with retry (RM-13)
- [ ] **Filter Settings UI** — colour, type, rarity, date-range filter UI; save/select/delete named presets (Phase 2)
- [ ] **Favourites** — swipe-up to save, grid overview, individual swipe view, filter by colour/type/rarity, delete (Phase 3)
- [ ] **Card Detail View** — full artwork, set info, mana cost, rules text, flavour text, price (USD/EUR), format legalities (Phase 4)
- [ ] **Test Coverage** — unit tests for business logic (80%+ target), widget tests for all screens (loading/success/error/empty), integration tests for key flows (Phase 6)

### Out of Scope

- **Backend server / API proxy** — Scryfall is open and requires no auth; a proxy adds complexity with zero benefit (ADR-005)
- **Online sync / user accounts** — v1 is fully local; no backend infrastructure planned
- **Deck-building features** — explicitly excluded from v1 (Confluence open questions)
- **Offline card image caching** — `cached_network_image` handles in-memory caching; persistent disk pre-fetching not scoped for v1
- **Theme switcher** — dark mode only; no light mode planned for v1

## Context

- **Codebase state (2026-04-10):** Infrastructure layers (Dio, Riverpod, GoRouter, theme, `MagicCard` model, `CardRepository`) are complete. The `CardSwipeScreen` is a placeholder — RM-13 is the next active ticket.
- **Local storage:** Hive CE (`hive_ce 2.19.3`) chosen over Isar due to AGP 8.x incompatibility and `source_gen` conflicts (see ADR-006). Hive CE is pure Dart, no code-gen step required.
- **Riverpod:** Upgraded to 3.x (`flutter_riverpod 3.3.1`). Code-gen via `@riverpod` annotation; `build_runner` must run after provider changes.
- **Double-faced cards:** `MagicCard.fromJson()` falls back to `card_faces[0].image_uris` if top-level `image_uris` is null.
- **Scryfall rate limit:** ~10 req/s; single fetch per swipe gesture means rate limiting is not a concern in normal usage.

## Constraints

- **Tech stack:** Flutter stable channel, Dart ^3.11.4 — no version pinning beyond what pubspec.yaml declares
- **No hardcoded values:** All colours via `AppColors` / `Theme.of(context)`, all spacing via `AppSpacing`
- **No cross-feature imports:** Features must not import each other's `data/` or `presentation/` layers; shared types go in `lib/shared/`
- **`flutter analyze` must be clean:** `--fatal-infos` in CI; any lint warning is a build failure
- **Result<T> pattern:** All repository and API client methods return `Result<T>` — never throw across layer boundaries

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flutter over React Native | Superior animation/rendering control for swipe-heavy UI (ADR-001) | — Pending |
| Riverpod over BLoC/Provider | Compile-safe, testable, code-gen reduces boilerplate (ADR-002) | — Pending |
| Hive CE over Isar | Isar 3.x unmaintained; AGP 8.x blocker; `source_gen` conflict (ADR-006) | — Pending |
| Feature-first folder structure | Agent-friendly scope isolation; maps to Jira epics (ADR-004) | — Pending |
| No backend proxy | Scryfall is free, open, no auth required; proxy = unnecessary complexity (ADR-005) | — Pending |
| Riverpod 3.x upgrade | No longer blocked by Isar's `source_gen` constraint | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-10 after initialization (brownfield — inferred from existing codebase + Confluence + Jira)*
