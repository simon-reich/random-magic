---
phase: 05-tests
plan: "01"
subsystem: card_discovery/tests
tags: [testing, unit-tests, fixtures, card-discovery]
dependency_graph:
  requires: []
  provides:
    - test/fixtures/fake_card_repository.dart
    - test/unit/card_discovery/magic_card_from_json_test.dart
    - test/unit/card_discovery/random_card_notifier_test.dart
  affects:
    - test/fixtures/ (new shared fixture for Plan 02 widget tests)
    - pubspec.yaml (integration_test dev_dependency for Plan 03)
tech_stack:
  added:
    - integration_test SDK package (dev_dependency)
  patterns:
    - Sentinel object pattern for distinguishing absent JSON keys from null values
    - awaitSettled() helper using hasError||hasValue (not !isLoading) for Riverpod 3.x keepAlive AsyncNotifier error states
    - FakeCardRepository / StallingFakeRepository / FailingFakeRepository test doubles
key_files:
  created:
    - test/fixtures/fake_card_repository.dart
    - test/unit/card_discovery/magic_card_from_json_test.dart
    - test/unit/card_discovery/random_card_notifier_test.dart
  modified:
    - pubspec.yaml (added integration_test dev_dependency)
    - pubspec.lock (updated after flutter pub get)
decisions:
  - "awaitSettled() uses hasError||hasValue not !isLoading: Riverpod 3.x keepAlive AsyncNotifier produces state where isLoading=true AND hasError=true simultaneously when build() throws — confirmed via debug test"
  - "All three repository fakes are public (no underscore prefix): Plan 02 widget tests import them directly from test/fixtures/"
  - "DFC test removes image_uris key from JSON map (json.remove) rather than passing null: MagicCard.fromJson checks for key absence, not null value"
metrics:
  duration: "12 minutes"
  completed: "2026-04-18"
  tasks_completed: 3
  files_created: 3
  files_modified: 2
---

# Phase 5 Plan 01: Unit Tests — Card Discovery Summary

**One-liner:** Unit test fixture layer (FakeCardRepository + 3 doubles) and 25 passing tests for MagicCard.fromJson() and RandomCardNotifier covering the full TEST-02 edge-case matrix.

## What Was Created

### pubspec.yaml
Added `integration_test: sdk: flutter` under `dev_dependencies` after the `mockito` entry. Required for Plan 03 integration tests.

### test/fixtures/fake_card_repository.dart
Shared test fixture providing three `CardRepository` implementations:

| Class | Behaviour |
|-------|-----------|
| `FakeCardRepository` | Returns pre-configured `Result<MagicCard>`; defaults to `Success(fakeMagicCard())` |
| `StallingFakeRepository` | `getRandomCard()` / `getCardById()` never resolve (Completer without completion); holds provider in AsyncLoading |
| `FailingFakeRepository` | Returns `Failure(failure)` immediately for every call |

All three are **public** (no underscore) so Plan 02 widget tests can import them.

### test/unit/card_discovery/magic_card_from_json_test.dart
20 test cases across 4 groups covering the full TEST-02 matrix:

| Group | Tests |
|-------|-------|
| Normal card (all fields present) | 7 — id/name/rarity, manaCost/typeLine/oracleText/flavorText, imageUris, prices, legalities, colors, cardFaces=null |
| Double-faced card (DFC) | 5 — imageUris from face[0], cardFaces non-null length=2, face names, back face manaCost=null |
| Null prices | 2 — prices key null → card.prices null; all-null sub-fields → prices non-null with null fields |
| Nullable text fields + defensive parsing | 6 — absent oracle_text, flavor_text, mana_cost, legalities, colors, type_line |

**Result:** 20/20 pass, 0 skipped.

### test/unit/card_discovery/random_card_notifier_test.dart
5 test cases for `RandomCardNotifier`:

| Test | Covers |
|------|--------|
| build() returns AsyncData on Success | Happy path |
| build() returns AsyncError(CardNotFoundFailure) | Failure propagation |
| build() returns AsyncError(NetworkFailure) | Failure propagation |
| refresh() resolves to AsyncData | Refresh happy path |
| refresh() resolves to AsyncError | Refresh failure path |

**Result:** 5/5 pass, 0 skipped.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] DFC JSON test used null image_uris instead of absent key**
- **Found during:** Task 2 first run
- **Issue:** Plan template passed `imageUris: null` to `baseJson()`, which fell through to the default `image_uris` value because `null ?? default` evaluates to the default. `MagicCard.fromJson` checks key absence (`json['image_uris'] as Map?`), so the test was hitting the single-faced path.
- **Fix:** Built DFC JSON from `baseJson()` then called `json.remove('image_uris')` to omit the key entirely, matching real Scryfall DFC payloads.
- **Files modified:** `test/unit/card_discovery/magic_card_from_json_test.dart`
- **Commit:** 6144bcd

**2. [Rule 1 - Bug] awaitSettled() used !isLoading which never became true for error states**
- **Found during:** Task 3 first and second run
- **Issue:** Riverpod 3.x `keepAlive AsyncNotifier` produces `AsyncValue` where `isLoading=true` AND `hasError=true` simultaneously when `build()` throws. Both a listener-based Completer and a polling loop checking `!isLoading` hung for 30 seconds.
- **Root cause confirmed:** Debug test showed `isLoading` stays `true` indefinitely even after error is set.
- **Fix:** Changed `awaitSettled()` to poll `hasValue || hasError` with `Future.delayed(Duration.zero)` yields (100 iterations max). Fast fakes resolve in < 1ms; this terminates in 1–2 iterations.
- **Files modified:** `test/unit/card_discovery/random_card_notifier_test.dart`
- **Commit:** 48e351a

## Known Stubs

None. All three files contain only test infrastructure — no UI rendering paths and no stubbed data flows.

## Threat Flags

None. Test fixtures contain only fake Scryfall data; no real PII, credentials, or network endpoints introduced.

## Self-Check: PASSED

Files created:
- test/fixtures/fake_card_repository.dart — FOUND
- test/unit/card_discovery/magic_card_from_json_test.dart — FOUND
- test/unit/card_discovery/random_card_notifier_test.dart — FOUND

Commits:
- be1c7f8 (Task 1) — FOUND
- 6144bcd (Task 2) — FOUND
- 48e351a (Task 3) — FOUND

Test results: 112 total tests pass, 0 failures, 0 skips.
`flutter analyze --fatal-infos`: No issues found.
