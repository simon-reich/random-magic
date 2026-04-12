---
plan: "02-01"
phase: "02-filter-settings-presets"
status: completed
wave: 1
completed_at: "2026-04-12"
---

# Plan 02-01 Summary — Domain Foundation

## What Was Built

Laid the domain foundation for Phase 2. Added `flutter_svg` to pubspec, created the `MtgColor`
enum, `FilterSettings` immutable value class, and the `FilterPreset` Hive CE model with its
hand-written TypeAdapter. Initialized Hive CE in `main.dart` before `runApp()`.

## Key Files

### Created
- `lib/shared/models/mtg_color.dart` — `MtgColor` enum with 7 values (W/U/B/R/G/C/M), `code`, `displayName`, `svgUrl` fields, and `fromCode` static factory
- `lib/features/filters/domain/filter_settings.dart` — immutable `FilterSettings` class with `colors`, `types`, `rarities`, `releasedAfter`, `releasedBefore` fields, `isEmpty` getter, and `copyWith` with nullable-date-clear support
- `lib/features/filters/domain/filter_preset.dart` — `FilterPreset` class (name + settings) and hand-written `FilterPresetAdapter` (typeId: 0) with full BinaryReader/BinaryWriter serialisation

### Modified
- `pubspec.yaml` — added `flutter_svg: ^2.2.4`
- `pubspec.lock` — resolved flutter_svg dependency tree
- `lib/main.dart` — made `main()` async, added `WidgetsFlutterBinding.ensureInitialized()`, `Hive.initFlutter()`, `Hive.registerAdapter(FilterPresetAdapter())`, `Hive.openBox<FilterPreset>('filter_presets')`

## Commits
- `c77c558` feat(02-01): add flutter_svg and async Hive CE init in main.dart
- `dac702d` feat(02-01): add MtgColor enum, FilterSettings, FilterPreset + FilterPresetAdapter

## Self-Check

### must_haves verification
- [x] `flutter_svg` is in pubspec.yaml and resolves without conflict
- [x] `MtgColor` enum exists with W/U/B/R/G/C/M values, code, displayName, and fromCode constructor
- [x] `FilterSettings` immutable class exists with colors/types/rarities/releasedAfter/releasedBefore + isEmpty + copyWith
- [x] `FilterPreset` class exists with name + settings fields
- [x] `FilterPresetAdapter` extends `TypeAdapter<FilterPreset>` with typeId: 0, read(), and write()
- [x] `main.dart` calls `Hive.initFlutter()` and awaits `Hive.openBox` before `runApp()`
- [x] `flutter analyze --fatal-infos` passes clean

### Self-Check: PASSED
