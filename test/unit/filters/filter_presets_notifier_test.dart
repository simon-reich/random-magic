import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:random_magic/features/filters/domain/filter_preset.dart';
import 'package:random_magic/features/filters/presentation/providers.dart';

import '../../../fixtures/fake_preset.dart';

// Wave 0 stubs — all test bodies are skipped until Plan 02 implements the
// FilterPresetsNotifier, FilterPreset, and FilterPresetAdapter classes.

void main() {
  setUp(() async {
    Hive.init(Directory.systemTemp.path);
    Hive.registerAdapter(FilterPresetAdapter());
    await Hive.openBox<FilterPreset>('filter_presets');
  });

  tearDown(() async {
    await Hive.close();
  });

  group('FilterPresetsNotifier', () {
    test('save stores preset (FILT-06)', () async {
      expect(true, true, skip: 'Wave 0 stub — implement in Plan 02');
    });

    test('save blocks duplicate name (FILT-09)', () async {
      expect(true, true, skip: 'Wave 0 stub — implement in Plan 02');
    });

    test('save with upsert=true replaces existing (FILT-08/D-08)', () async {
      expect(true, true, skip: 'Wave 0 stub — implement in Plan 02');
    });

    test('delete removes preset (FILT-08)', () async {
      expect(true, true, skip: 'Wave 0 stub — implement in Plan 02');
    });

    test('loading preset restores FilterSettings (FILT-07)', () async {
      expect(true, true, skip: 'Wave 0 stub — implement in Plan 02');
    });
  });
}
