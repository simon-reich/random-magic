---
phase: 05-tests
plan: 02
status: complete
---

# Plan 05-02 Summary — Widget Tests

## What was done

Wrote widget tests for `FilterSettingsScreen` (FILT-01 through FILT-04, FILT-07) and
`ActiveFilterBar` (DISC-10). FILT-06/08/09 were already covered by existing unit tests in
`test/unit/filters/filter_presets_notifier_test.dart` — no widget duplication needed.

## Files created / modified

| File | Change |
|------|--------|
| `test/widgets/filters/filter_settings_screen_test.dart` | Rewritten — 5 widget tests with HttpOverrides SVG mock |
| `test/widgets/card_discovery/card_swipe_screen_filter_bar_test.dart` | Created — 3 widget tests for ActiveFilterBar |
| `test/widgets/card_discovery/card_swipe_screen_tap_test.dart` | Updated comment referencing integration test |
| `lib/features/filters/presentation/filter_settings_screen.dart` | Added `errorBuilder` to `SvgPicture.network` |

## SVG mocking approach

`SvgPicture.network` uses `package:http`'s `IOClient`, which wraps `dart:io`'s `HttpClient`.
The `TestWidgetsFlutterBinding` sets up a global HTTP override that returns 400 for all
requests. This caused `vector_graphics` to fire an uncaught zone error after the test future
resolved — impossible to suppress from test code.

**Fix:** Install a custom `HttpOverrides` in `setUpAll` that returns a valid minimal SVG
(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"/>`) with status 200. The SVG
parser succeeds, no zone error is generated. Teardown restores the saved override.

The fake client implements:
- `HttpClient.getUrl` and `HttpClient.openUrl` (both called by `IOClient`)
- `HttpClientRequest.close`, `addStream`, `headers`
- `HttpClientResponse.statusCode`, `contentLength`, `compressionState`, `headers`,
  `isRedirect`, `persistentConnection`, `reasonPhrase`, `redirects`, `redirect`,
  `certificate`, `connectionInfo`, `listen`

## Test results

- 5 widget tests pass: FILT-01 (colour toggles), FILT-02 (type chips), FILT-03 (rarity chips),
  FILT-04 (date pickers), FILT-07 (preset chip row)
- 3 widget tests pass: DISC-10 (ActiveFilterBar hidden, chip visible, chip deletion)
- `flutter analyze` clean (zero warnings)
