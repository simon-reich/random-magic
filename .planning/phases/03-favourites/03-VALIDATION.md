---
phase: 3
slug: favourites
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-16
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (bundled with Flutter 3.41.6) + mockito 5.6.4 |
| **Config file** | No separate config — standard `flutter test` discovery |
| **Quick run command** | `flutter test test/unit/favourites/ test/widgets/favourites/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/favourites/ test/widgets/favourites/`
- **After every plan wave:** Run `flutter test && flutter analyze`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 0 | FAV-01 | — | N/A | unit | `flutter test test/unit/favourites/favourites_notifier_test.dart` | ❌ W0 | ⬜ pending |
| 03-01-02 | 01 | 0 | FAV-07 | — | N/A | unit | `flutter test test/unit/favourites/favourites_filter_test.dart` | ❌ W0 | ⬜ pending |
| 03-01-03 | 01 | 0 | FAV-02/06 | — | N/A | widget | `flutter test test/widgets/favourites/favourites_screen_test.dart` | ❌ W0 | ⬜ pending |
| 03-02-01 | 02 | 1 | FAV-01 | — | N/A | unit | `flutter test test/unit/favourites/favourites_notifier_test.dart` | ❌ W0 | ⬜ pending |
| 03-02-02 | 02 | 1 | FAV-04 | — | N/A | unit | `flutter test test/unit/favourites/favourites_notifier_test.dart` | ❌ W0 | ⬜ pending |
| 03-02-03 | 02 | 1 | FAV-05 | — | N/A | unit | `flutter test test/unit/favourites/favourites_notifier_test.dart` | ❌ W0 | ⬜ pending |
| 03-03-01 | 03 | 2 | FAV-01 | — | N/A | widget | `flutter test test/widgets/card_discovery/` | ❌ W0 | ⬜ pending |
| 03-04-01 | 04 | 2 | FAV-02 | — | N/A | widget | `flutter test test/widgets/favourites/favourites_screen_test.dart` | ❌ W0 | ⬜ pending |
| 03-04-02 | 04 | 2 | FAV-03 | — | N/A | widget | `flutter test test/widgets/favourites/favourites_screen_test.dart` | ❌ W0 | ⬜ pending |
| 03-04-03 | 04 | 2 | FAV-06 | — | N/A | widget | `flutter test test/widgets/favourites/favourites_screen_test.dart` | ❌ W0 | ⬜ pending |
| 03-04-04 | 04 | 2 | FAV-07 | — | N/A | unit | `flutter test test/unit/favourites/favourites_filter_test.dart` | ❌ W0 | ⬜ pending |
| 03-05-01 | 05 | 2 | FAV-04 | — | N/A | widget | `flutter test test/widgets/favourites/` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/fixtures/fake_favourite_card.dart` — shared fixture factory (parallel to `fake_preset.dart`)
- [ ] `test/unit/favourites/favourites_notifier_test.dart` — stubs for FAV-01, FAV-04, FAV-05
- [ ] `test/unit/favourites/favourites_filter_test.dart` — stubs for FAV-07
- [ ] `test/widgets/favourites/favourites_screen_test.dart` — stubs for FAV-02, FAV-03, FAV-06

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Snackbar "Saved to Favourites" shows on card save | FAV-01 | Snackbar host context tricky to assert in widget test without real scaffold | Save card via button tap; confirm Snackbar appears at bottom of screen |
| Undo Snackbar restores deleted card within 3s | FAV-04 | Timer-based dismissal hard to control in widget tests | Delete card; tap Undo within 3 seconds; confirm card reappears |
| Multi-select batch delete restores all cards via single undo | FAV-04 | Complex multi-step interaction | Long-press grid; select 3 cards; delete; tap Undo; confirm all 3 restored |
| Saved cards persist after hot restart | FAV-05 | Requires actual Hive flush to disk | Save card; hot restart app; open Favourites; confirm card present |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
