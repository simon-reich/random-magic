# CLAUDE.md — Random Magic

This file is the primary briefing document for Claude Code and all sub-agents working on this
repository. Read it fully before writing any code, running any commands, or making any
architectural decisions.

---

## Project Overview

**Random Magic** is a cross-platform mobile app built with Flutter that lets users discover
Magic: The Gathering cards by swiping through randomised results from the Scryfall API. Users
can filter results by colour, type, rarity, and release date, save filter presets by name, and
maintain a favourites collection with its own filtering and swipe view.

- **GitHub:** https://github.com/simon-reich/random-magic
- **Jira Board:** https://allmyplaygrounds.atlassian.net/jira/software/projects/RM/boards/68
- **Confluence:** https://allmyplaygrounds.atlassian.net/wiki/spaces/RMFA
- **API:** https://scryfall.com/docs/api/cards/random

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart, stable channel) |
| State Management | Riverpod 2.x with code generation (`@riverpod`) |
| Local Database | Isar (favourites + filter presets) |
| HTTP Client | Dio |
| Navigation | GoRouter |
| Testing | flutter_test + mockito |
| CI/CD | GitHub Actions |
| API | Scryfall REST API (no auth required) |

---

## Folder Structure

```
lib/
├── core/
│   ├── constants/        # App-wide constants, spacing, colours
│   ├── router/           # GoRouter configuration (app_router.dart)
│   ├── theme/            # AppTheme, ThemeData (dark mode)
│   └── network/          # Dio client setup, interceptors
├── features/
│   ├── card_discovery/   # Swipe screen + random card fetching
│   │   ├── data/         # ScryfallApiClient, DTOs
│   │   ├── domain/       # MagicCard model, repository interface
│   │   └── presentation/ # CardSwipeScreen, providers
│   ├── filters/          # Filter settings + preset management
│   │   ├── data/         # ScryfallQueryBuilder, FilterPresetRepository
│   │   ├── domain/       # FilterPreset model, FilterSettings model
│   │   └── presentation/ # FilterSettingsScreen, providers
│   ├── favourites/       # Favourites save/view/delete/filter
│   │   ├── data/         # FavouritesRepository (Isar)
│   │   ├── domain/       # FavouriteCard model
│   │   └── presentation/ # FavouritesScreen, FavouriteSwipeScreen, providers
│   └── card_detail/      # Card detail view
│       ├── domain/       # (reuses MagicCard from shared)
│       └── presentation/ # CardDetailScreen
├── shared/
│   ├── models/           # MagicCard, shared enums (MtgColor, CardType, Rarity)
│   └── widgets/          # Reusable UI components (error states, empty states, etc.)
└── main.dart
```

**Rules:**
- Features must not import from each other's `data/` or `presentation/` layers directly.
- Cross-feature shared types go in `shared/models/` or `shared/widgets/`.
- `core/` is for app-wide infrastructure only — not feature logic.

---

## Architecture Decisions

All significant decisions are documented in Confluence ADRs:
https://allmyplaygrounds.atlassian.net/wiki/spaces/RMFA/pages/7536643

**Summary of accepted decisions:**
- Flutter chosen over React Native for superior animation and rendering control
- Riverpod chosen over BLoC / Provider for testability and compile-safety
- Isar chosen over Hive for reactive queries and better performance on complex objects
- Feature-first folder structure for isolation and agent-friendly scope boundaries
- Scryfall called directly from the Flutter app — no backend proxy

---

## Agent Roles

When working on this project, Claude Code operates in one of the following agent modes
depending on the task at hand. Switch modes explicitly when the task changes.

### 🏛️ App Architect Agent
**Activate when:** Setting up structure, adding new features, making dependency decisions,
writing ADRs, reviewing overall codebase health.

**Responsibilities:**
- Define and enforce folder structure and naming conventions
- Decide on packages and write ADRs for significant choices
- Ensure feature isolation — no cross-feature data layer imports
- Keep `CLAUDE.md` and Confluence architecture docs up to date

**Rules:**
- Do not write UI code in this mode
- Document every significant decision as an ADR before implementing it

---

### 🎨 Frontend Agent
**Activate when:** Building screens, widgets, animations, gesture handling, navigation.

**Responsibilities:**
- Implement Flutter screens and widgets in `presentation/` layers
- Implement card swipe gestures using `GestureDetector` or a swipe package
- Ensure all screens have loading, success, error, and empty states
- Follow the dark theme — no hardcoded colours, use `Theme.of(context)`
- Use `GoRouter` for all navigation — no direct `Navigator.push`

**Rules:**
- Never access Isar or make HTTP calls directly from widgets — go through providers
- All public widget classes must have a doc comment
- Avoid `setState` — use Riverpod `ConsumerWidget` or `ConsumerStatefulWidget`

---

### ⚙️ Backend Agent
**Activate when:** Implementing API integration, data layer, caching, Isar schemas,
query building.

**Responsibilities:**
- Implement `ScryfallApiClient` using Dio in `core/network/`
- Implement `ScryfallQueryBuilder` in `features/filters/data/`
- Implement Isar schemas for `FavouriteCard` and `FilterPreset`
- Handle all Scryfall error codes (404, 422, network timeout)
- Handle double-faced cards in `MagicCard.fromJson()`

**Rules:**
- Never make real HTTP calls in tests — all API clients must be injectable/mockable
- All repository methods must return typed results (use `Result<T>` pattern or sealed classes)
- Isar schema changes must be accompanied by a migration strategy note

**Scryfall query syntax quick-reference:**
```
color:W/U/B/R/G/C/m    type:Creature/Instant/...    rarity:common/uncommon/rare/mythic
date>=YYYY-MM-DD        date<=YYYY-MM-DD
```
Multiple values: `color:R OR color:G` | Full docs: https://scryfall.com/docs/syntax

---

### 🧪 QA Agent
**Activate when:** Writing tests, reviewing error coverage, checking edge cases.

**Responsibilities:**
- Write unit tests for all business logic (target: 80%+ coverage on logic classes)
- Write widget tests for all screens (loading / success / error / empty states)
- Write integration tests for key user flows
- Run `flutter test` and `flutter analyze` before marking any task done
- Flag uncovered error paths and missing input validation

**Test file locations:**
```
test/unit/<feature>/        → Pure Dart logic
test/widgets/<feature>/     → Flutter widget tests
test/fixtures/              → Fake card data, fake presets
integration_test/           → Full app flow tests
```

**Always test these edge cases:**
- Card with no `image_uris` → must fall back to `card_faces[0].image_uris`
- Card with all price fields null → display "N/A"
- Card with no `flavor_text` → field hidden, not blank
- Filter preset with no filters set → unrestricted query (no `q` param)
- Two presets with identical names → prevent or handle gracefully

---

### 👀 Code Review Agent
**Activate when:** Reviewing a completed feature before it's considered done.

**Checklist — reject if any of these fail:**
- [ ] `flutter analyze` is clean (zero warnings)
- [ ] `flutter test` passes
- [ ] All public classes, methods, and providers have doc comments (`///`)
- [ ] Complex logic blocks have inline comments explaining *why*, not *what*
- [ ] No hardcoded colours, strings, or magic numbers (use constants)
- [ ] No direct Scryfall calls from presentation layer
- [ ] Error states handled for every async operation
- [ ] New Isar schema changes documented

---

## Coding Standards

### Comments
- **Every public class, method, and Riverpod provider** must have a `///` doc comment
- **Complex logic** (query building, error parsing, gesture math) must have inline `//` comments
- Comments explain **why**, not what — `// build_runner generates this, do not edit` ✓, `// this is a list` ✗

### Dart Style
- Follow official Dart style guide: https://dart.dev/guides/language/effective-dart/style
- Use `const` constructors wherever possible
- Prefer named parameters for widget constructors with 2+ params
- Use sealed classes / `Result<T, E>` pattern for error-propagating repository methods

### Naming
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Providers: `camelCaseProvider` (Riverpod generated)
- Isar collections: `@Collection()` classes in `domain/` with `snake_case` file names

### No magic numbers
```dart
// ✗ Bad
SizedBox(height: 16)

// ✓ Good
SizedBox(height: AppSpacing.md)
```

---

## Definition of Done

A Jira ticket is only Done when ALL of these are true:

- [ ] Feature implemented and matches Jira acceptance criteria
- [ ] `flutter analyze` clean
- [ ] `flutter test` passing (new tests written if applicable)
- [ ] Code commented per standards above
- [ ] PR reviewed by Code Review Agent checklist
- [ ] Confluence updated if architecture or API integration changed

---

## Working with Jira

- Jira project key: `RM`
- Board: https://allmyplaygrounds.atlassian.net/jira/software/projects/RM/boards/68
- Reference the Jira ticket key in commit messages: `git commit -m "RM-2: Initialize Flutter project structure"`
- Move tickets to "In Progress" when starting, "Done" only when Definition of Done is met

---

## Scryfall API Quick Reference

```
Base URL:   https://api.scryfall.com
Endpoint:   GET /cards/random?q=<query>
Auth:       None required
Rate limit: 10 req/s max
User-Agent: RandomMagicApp/1.0
```

Error codes to handle:
- `404` → No cards match query → show "No cards found" empty state
- `422` → Invalid query syntax → show "Invalid filter settings" error
- Network timeout → show "Could not reach Scryfall" + retry button

Full API integration notes: https://allmyplaygrounds.atlassian.net/wiki/spaces/RMFA/pages/7503874
