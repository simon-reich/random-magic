# Phase 3: Favourites — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-16
**Phase:** 03-favourites
**Areas discussed:** Save-Button Platzierung, Already-Saved Indikator, Delete-Bestätigung, Filter-State Persistenz

---

## Save-Button Platzierung

| Option | Description | Selected |
|--------|-------------|----------|
| Overlay auf der Karte (unten-rechts) | Positioned inside _CardFaceWidget Stack, no extra UI outside card | ✓ |
| Floating Action Button unter der Karte | FAB between card and bottom nav, requires layout change | |
| Swipe-up only, kein Button | Gesture only, not discoverable — contradicts FAV-01 | |

**User's choice:** Overlay auf der Karte (unten-rechts)

**Follow-up — Swipe-Up zusätzlich:**

| Option | Selected |
|--------|----------|
| Ja, beides (Button + Swipe-Up) | ✓ |
| Nein, nur Button | |

---

## Already-Saved Indikator

| Option | Description | Selected |
|--------|-------------|----------|
| Gefülltes Icon + keine Aktion | ♥ when saved, tapping does nothing | ✓ |
| Gefülltes Icon, Tippen entfernt | Toggle: ♥ tap = remove from favourites | |
| Kein Indikator | Always same icon, upsert on tap | |

**User's choice:** Gefülltes Icon + keine Aktion

---

## Delete-Bestätigung

| Option | Description | Selected |
|--------|-------------|----------|
| Sofort löschen + Undo-Snackbar | Immediate delete, ~3s undo Snackbar | ✓ |
| Confirm-Dialog | AlertDialog before delete | |
| Sofort löschen, kein Undo | Direct delete, no recovery | |

**User's choice:** Sofort löschen + Undo-Snackbar

**Notes:** User additionally requested long-press multi-select on grid cards for batch delete.
Multi-select mode exited via Back-Button or second long-press (no timeout).

---

## Filter-State Persistenz

| Option | Description | Selected |
|--------|-------------|----------|
| Reset beim Verlassen des Tabs | In-memory only, autoDispose acceptable | ✓ |
| Persistent über Sessions | Hive persist, survives app restart | |

**User's choice:** Reset beim Verlassen des Tabs

---

## Claude's Discretion

- Navigation from grid to FavouriteSwipeScreen (load all, seek to card by ID)
- Sort order in grid (newest-saved first)
- FavouritesNotifier keepAlive: true

## Deferred Ideas

None.
