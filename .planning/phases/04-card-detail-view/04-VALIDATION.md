---
phase: 4
slug: card-detail-view
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-17
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (sdk bundled) |
| **Config file** | analysis_options.yaml (lints only); no separate test config |
| **Quick run command** | `flutter test test/widgets/card_detail/ --no-pub` |
| **Full suite command** | `flutter test --no-pub` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/widgets/card_detail/ --no-pub && flutter analyze --fatal-infos`
- **After every plan wave:** Run `flutter test --no-pub && flutter analyze --fatal-infos`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 4-01-01 | 01 | 0 | CARD-02 | — | N/A | Widget | `flutter test test/widgets/card_detail/ --no-pub` | ❌ W0 | ⬜ pending |
| 4-01-02 | 01 | 0 | CARD-05 | — | N/A | Unit | `flutter test test/unit/card_discovery/ --no-pub` | ❌ W0 | ⬜ pending |
| 4-02-01 | 02 | 1 | CARD-03 | — | N/A | Widget | `flutter test test/widgets/card_detail/ --no-pub` | ❌ W0 | ⬜ pending |
| 4-02-02 | 02 | 1 | CARD-04 | — | N/A | Widget | `flutter test test/widgets/card_detail/ --no-pub` | ❌ W0 | ⬜ pending |
| 4-03-01 | 03 | 2 | CARD-05 | — | N/A | Widget | `flutter test test/widgets/card_detail/ --no-pub` | ❌ W0 | ⬜ pending |
| 4-04-01 | 04 | 2 | CARD-01 | — | N/A | Widget | `flutter test test/widgets/card_discovery/ --no-pub` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/widgets/card_detail/card_detail_screen_test.dart` — stubs for CARD-02, CARD-03, CARD-04, CARD-05
- [ ] `test/fixtures/fake_magic_card.dart` — shared `fakeMagicCard()` helper with DFC variant
- [ ] Extend `test/unit/card_discovery/magic_card_colors_test.dart` to cover `cardFaces` parsing (TEST-02 / CARD-05)
- [ ] CARD-01 tap-to-detail stub in `test/widgets/card_discovery/` (skip-stub; full impl in Phase 5)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Card image fills expanded SliverAppBar header; collapses on scroll | CARD-02 | Visual/gesture behavior not testable via flutter_test headless runner | Run app on simulator, open detail screen, scroll down |
| Flip animation plays when flip button tapped | CARD-05 | Animation visual not testable headlessly | Run app on simulator, open a DFC card, tap flip |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
