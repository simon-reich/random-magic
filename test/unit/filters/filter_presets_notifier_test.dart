import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:random_magic/features/filters/domain/filter_preset.dart';
import 'package:random_magic/features/filters/domain/filter_settings.dart';
import 'package:random_magic/features/filters/presentation/providers.dart';
import 'package:random_magic/shared/models/mtg_color.dart';

import '../../fixtures/fake_preset.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    Hive.init(Directory.systemTemp.path);
    // Guard against double-registration across test runs
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FilterPresetAdapter());
    }
    final box = await Hive.openBox<FilterPreset>('filter_presets');
    await box.clear();
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
  });

  group('FilterPresetsNotifier', () {
    test('initial state is empty when box is empty (FILT-06)', () async {
      expect(container.read(filterPresetsProvider), isEmpty);
    });

    test('save stores preset (FILT-06)', () async {
      final preset = fakeBudgetAggroPreset();
      final notifier = container.read(filterPresetsProvider.notifier);
      final result = notifier.save(preset);
      expect(result, isTrue);
      expect(
        container.read(filterPresetsProvider).map((p) => p.name),
        contains('Budget Aggro'),
      );
    });

    test('save blocks duplicate name (FILT-09)', () async {
      final preset = fakeBudgetAggroPreset();
      final notifier = container.read(filterPresetsProvider.notifier);
      notifier.save(preset);
      final result = notifier.save(preset);
      expect(result, isFalse);
      // Box unchanged — only one entry
      expect(container.read(filterPresetsProvider).length, equals(1));
    });

    test('save with upsert=true replaces existing (FILT-08/D-08)', () async {
      final original = fakeBudgetAggroPreset();
      final updated = FilterPreset(
        name: 'Budget Aggro',
        settings: FilterSettings(colors: {MtgColor.blue}),
      );
      final notifier = container.read(filterPresetsProvider.notifier);
      notifier.save(original);
      final result = notifier.save(updated, upsert: true);
      expect(result, isTrue);
      final presets = container.read(filterPresetsProvider);
      expect(presets.length, equals(1));
      expect(presets.first.settings.colors, equals({MtgColor.blue}));
    });

    test('delete removes preset (FILT-08)', () async {
      final preset = fakeBudgetAggroPreset();
      final notifier = container.read(filterPresetsProvider.notifier);
      notifier.save(preset);
      notifier.delete('Budget Aggro');
      expect(
        container.read(filterPresetsProvider).map((p) => p.name),
        isNot(contains('Budget Aggro')),
      );
    });

    test('loading preset restores FilterSettings (FILT-07)', () async {
      final preset = fakeBudgetAggroPreset();
      final notifier = container.read(filterPresetsProvider.notifier);
      notifier.save(preset);
      final stored = container
          .read(filterPresetsProvider)
          .firstWhere((p) => p.name == 'Budget Aggro');
      expect(stored.settings.colors, equals({MtgColor.red}));
      expect(stored.settings.types, equals({'Creature'}));
    });
  });
}
