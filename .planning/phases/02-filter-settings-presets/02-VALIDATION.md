---
phase: 2
slug: filter-settings-presets
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-12
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (SDK bundled) |
| **Config file** | `analysis_options.yaml` (no separate test config) |
| **Quick run command** | `flutter test test/unit/filters/` |
| **Full suite command** | `flutter test && flutter analyze --fatal-infos` |
| **Estimated runtime** | ~10 seconds (unit only), ~30 seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/filters/`
- **After every plan wave:** Run `flutter test && flutter analyze --fatal-infos`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds (unit), 30 seconds (full)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 2-01-01 | 01 | 1 | FILT-06/07/08/09 | — | N/A | unit | `flutter test test/unit/filters/filter_presets_notifier_test.dart` | ❌ Wave 0 | ⬜ pending |
| 2-02-01 | 02 | 1 | FILT-01/02/03/04/10 | — | N/A | unit | `flutter test test/unit/filters/scryfall_query_builder_test.dart` | ❌ Wave 0 | ⬜ pending |
| 2-02-02 | 02 | 1 | FILT-05 | — | N/A | unit | `flutter test test/unit/filters/filter_settings_notifier_test.dart` | ❌ Wave 0 | ⬜ pending |
| 2-03-01 | 03 | 2 | FILT-05 | — | N/A | unit | `flutter test test/unit/filters/filter_settings_notifier_test.dart` | ❌ Wave 0 | ⬜ pending |
| 2-04-01 | 04 | 2 | FILT-01–09 | — | N/A | widget | `flutter test test/widgets/filters/filter_settings_screen_test.dart` | ❌ Wave 0 | ⬜ pending |
| 2-05-01 | 05 | 3 | DISC-10 | — | N/A | widget | `flutter test test/widgets/card_discovery/card_swipe_screen_test.dart` | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/filters/scryfall_query_builder_test.dart` — stubs for FILT-01 through FILT-04, FILT-10
- [ ] `test/unit/filters/filter_settings_notifier_test.dart` — stubs for FILT-05
- [ ] `test/unit/filters/filter_presets_notifier_test.dart` — stubs for FILT-06, FILT-07, FILT-08, FILT-09; uses `Hive.init(Directory.systemTemp.path)` (not `initFlutter`) in `setUp`, `Hive.close()` in `tearDown`
- [ ] `test/widgets/card_discovery/card_swipe_screen_test.dart` — extend existing placeholder for DISC-10
- [ ] `test/widgets/filters/filter_settings_screen_test.dart` — stubs for FILT-01–09 widget tests
- [ ] `test/fixtures/fake_preset.dart` — `FilterPreset` factory for tests

*Hive CE in tests: Use `Hive.init(Directory.systemTemp.path)`, register adapter in `setUp`, call `Hive.close()` in `tearDown`.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Mana SVG icons render correctly | FILT-01 | Network dependency on Scryfall SVG API | Run app on device/simulator, open Filter tab, verify W/U/B/R/G/C icons are visible |
| Preset chip auto-navigates to Discover | FILT-07 | Navigation side-effect hard to assert in widget tests | Tap a saved preset chip, verify app navigates to Discover tab |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
