---
phase: 01-cardswipescreen
plan: "01"
subsystem: core/theme + pubspec
tags: [dependencies, theming, skeletonizer, flutter_card_swiper]
dependency_graph:
  requires: []
  provides: [flutter_card_swiper dependency, skeletonizer dependency, SkeletonizerConfigData.dark theme extension, AppColors.networkError]
  affects: [lib/core/theme/app_theme.dart, pubspec.yaml]
tech_stack:
  added: [flutter_card_swiper ^7.0.0, skeletonizer ^1.4.0]
  patterns: [ThemeData extensions for global shimmer configuration]
key_files:
  created: []
  modified:
    - pubspec.yaml
    - lib/core/theme/app_theme.dart
    - .planning/ROADMAP.md
decisions:
  - Pin flutter_card_swiper at ^7.0.0 and skeletonizer at ^1.4.0 with caret constraints; lock via pubspec.lock committed to git
  - Register SkeletonizerConfigData.dark() as ThemeData extension (not per-widget) so all Skeletonizer widgets inherit dark shimmer globally
  - AppColors.networkError declared here to comply with CLAUDE.md no-hardcoded-colours rule
metrics:
  duration: ~5 minutes
  completed: "2026-04-12"
  tasks_completed: 2
  files_modified: 3
---

# Phase 1 Plan 01: Add Swiper + Skeletonizer Dependencies and Theme Configuration Summary

**One-liner:** Added flutter_card_swiper ^7.0.0 and skeletonizer ^1.4.0, configured SkeletonizerConfigData.dark() as a ThemeData extension, and declared AppColors.networkError for blue-grey error states.

## What Was Built

Two packages added to pubspec.yaml and flutter pub get resolved cleanly. AppTheme.dark now registers SkeletonizerConfigData.dark() as a ThemeData extension so every Skeletonizer widget in the app automatically uses the dark shimmer palette without per-widget configuration. AppColors.networkError (0xFF607D8B, blue-grey) was added to the palette for network-unreachable and rate-limit error states. ROADMAP.md Phase 1 UAT updated to reflect the full card face display (no separate metadata overlay).

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Add flutter_card_swiper and skeletonizer to pubspec.yaml | d5f3bc1 | pubspec.yaml, pubspec.lock |
| 2 | Configure SkeletonizerConfigData.dark() in AppTheme, add AppColors.networkError, update ROADMAP UAT | cff778e | lib/core/theme/app_theme.dart |

## Decisions Made

- **ThemeData extensions for global shimmer:** Registering SkeletonizerConfigData.dark() in ThemeData.extensions means every Skeletonizer widget inherits dark colours automatically, avoiding scattered per-widget configuration.
- **AppColors.networkError declared in plan 01:** CLAUDE.md mandates no hardcoded colours — this constant must exist before plan 03 uses it for error state rendering.
- **Caret version constraints:** ^7.0.0 and ^1.4.0 allow patch-level updates while locking major/minor; pubspec.lock is committed to prevent dependency drift.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, or trust boundary changes introduced.

## Self-Check

### Files exist:

- pubspec.yaml — FOUND (contains flutter_card_swiper: ^7.0.0 and skeletonizer: ^1.4.0)
- lib/core/theme/app_theme.dart — FOUND (contains SkeletonizerConfigData.dark(), AppColors.networkError, skeletonizer import)
- .planning/ROADMAP.md — FOUND (contains "Full card face image" UAT wording)

### Commits exist:

- d5f3bc1 — feat(01-01): add flutter_card_swiper and skeletonizer to pubspec.yaml
- cff778e — feat(01-01): configure SkeletonizerConfigData.dark() in AppTheme, add AppColors.networkError

## Self-Check: PASSED
