---
phase: 5
slug: tests
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-18
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (built-in SDK) + integration_test |
| **Config file** | none — SDK built-in |
| **Quick run command** | `flutter test test/unit/ test/widgets/` |
| **Full suite command** | `flutter test --coverage` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/ test/widgets/`
- **After every plan wave:** Run `flutter test --coverage`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 5-01-01 | 01 | 1 | TEST-01 | — | N/A | unit | `flutter test test/unit/card_discovery/magic_card_from_json_test.dart` | ❌ W0 | ⬜ pending |
| 5-01-02 | 01 | 1 | TEST-02 | — | N/A | unit | `flutter test test/unit/card_discovery/` | ❌ W0 | ⬜ pending |
| 5-02-01 | 02 | 1 | TEST-03 | — | N/A | widget | `flutter test test/widgets/card_discovery/card_swipe_screen_test.dart` | ❌ W0 | ⬜ pending |
| 5-02-02 | 02 | 1 | TEST-04 | — | N/A | widget | `flutter test test/widgets/filters/filter_settings_screen_test.dart` | ✅ | ⬜ pending |
| 5-03-01 | 03 | 2 | TEST-06 | — | N/A | integration | `flutter test integration_test/core_flow_test.dart` | ❌ W0 | ⬜ pending |
| 5-03-02 | 03 | 2 | QA-01 | — | N/A | coverage | `flutter test --coverage && lcov --summary coverage/lcov.info` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/card_discovery/magic_card_from_json_test.dart` — stubs for TEST-01 edge cases
- [ ] `test/widgets/card_discovery/card_swipe_screen_test.dart` — stubs for all 5 CardSwipeScreen states
- [ ] `integration_test/core_flow_test.dart` — integration test stub for TEST-06

*All other test infrastructure is already present.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Integration test network calls Scryfall | TEST-06 | Requires live network; not suitable for CI unit test suite | Run `flutter test integration_test/` on local machine with network access |
| 80%+ coverage on lib/features/ + lib/shared/ | QA-01 | Coverage measurement needs lcov/genhtml | Run `flutter test --coverage`, check coverage/lcov.info |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
