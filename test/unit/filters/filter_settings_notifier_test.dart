import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_magic/features/filters/domain/filter_settings.dart';
import 'package:random_magic/features/filters/presentation/providers.dart';
import 'package:random_magic/shared/models/mtg_color.dart';

import '../../fixtures/fake_preset.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('FilterSettingsNotifier', () {
    test('initial state is empty FilterSettings (FILT-05)', () {
      final state = container.read(filterSettingsProvider);
      expect(state.isEmpty, isTrue);
    });

    test('initial activePresetName is null (D-12)', () {
      final notifier = container.read(filterSettingsProvider.notifier);
      expect(notifier.activePresetName, isNull);
    });

    test('setColors updates colors in state (FILT-05)', () {
      final notifier = container.read(filterSettingsProvider.notifier);
      notifier.setColors({MtgColor.red});
      expect(container.read(filterSettingsProvider).colors,
          equals({MtgColor.red}));
    });

    test('setColors clears activePresetName (D-12)', () {
      final notifier = container.read(filterSettingsProvider.notifier);
      notifier.loadPreset(const FilterSettings(), presetName: 'Test');
      notifier.setColors({MtgColor.red});
      expect(notifier.activePresetName, isNull);
    });

    test('setTypes updates types in state (FILT-05)', () {
      final notifier = container.read(filterSettingsProvider.notifier);
      notifier.setTypes({'Creature'});
      expect(container.read(filterSettingsProvider).types,
          equals({'Creature'}));
    });

    test('setTypes clears activePresetName (D-12)', () {
      final notifier = container.read(filterSettingsProvider.notifier);
      notifier.loadPreset(const FilterSettings(), presetName: 'Test');
      notifier.setTypes({'Creature'});
      expect(notifier.activePresetName, isNull);
    });

    test('setRarities updates rarities in state (FILT-05)', () {
      final notifier = container.read(filterSettingsProvider.notifier);
      notifier.setRarities({'rare'});
      expect(container.read(filterSettingsProvider).rarities,
          equals({'rare'}));
    });

    test('setRarities clears activePresetName (D-12)', () {
      final notifier = container.read(filterSettingsProvider.notifier);
      notifier.loadPreset(const FilterSettings(), presetName: 'Test');
      notifier.setRarities({'rare'});
      expect(notifier.activePresetName, isNull);
    });

    test('setReleasedAfter updates date in state (FILT-05)', () {
      final notifier = container.read(filterSettingsProvider.notifier);
      notifier.setReleasedAfter(DateTime(2020, 1, 1));
      expect(container.read(filterSettingsProvider).releasedAfter,
          equals(DateTime(2020, 1, 1)));
    });

    test('setReleasedAfter clears activePresetName (D-12)', () {
      final notifier = container.read(filterSettingsProvider.notifier);
      notifier.loadPreset(const FilterSettings(), presetName: 'Test');
      notifier.setReleasedAfter(DateTime(2020, 1, 1));
      expect(notifier.activePresetName, isNull);
    });

    test('setReleasedBefore updates date in state (FILT-05)', () {
      final notifier = container.read(filterSettingsProvider.notifier);
      notifier.setReleasedBefore(DateTime(2023, 12, 31));
      expect(container.read(filterSettingsProvider).releasedBefore,
          equals(DateTime(2023, 12, 31)));
    });

    test('setReleasedBefore clears activePresetName (D-12)', () {
      final notifier = container.read(filterSettingsProvider.notifier);
      notifier.loadPreset(const FilterSettings(), presetName: 'Test');
      notifier.setReleasedBefore(DateTime(2023, 12, 31));
      expect(notifier.activePresetName, isNull);
    });

    test('loadPreset restores FilterSettings from preset (FILT-05)', () {
      final preset = fakeBudgetAggroPreset();
      final notifier = container.read(filterSettingsProvider.notifier);
      notifier.loadPreset(preset.settings, presetName: preset.name);
      expect(container.read(filterSettingsProvider), equals(preset.settings));
    });

    test('loadPreset sets activePresetName; mutation clears it (D-12)', () {
      final notifier = container.read(filterSettingsProvider.notifier);
      notifier.loadPreset(fakeBudgetAggroPreset().settings,
          presetName: 'Budget Aggro');
      expect(notifier.activePresetName, equals('Budget Aggro'));
      notifier.setColors({MtgColor.blue});
      expect(notifier.activePresetName, isNull);
    });

    test('reset clears all filter state (FILT-05)', () {
      final notifier = container.read(filterSettingsProvider.notifier);
      notifier.setColors({MtgColor.red});
      notifier.reset();
      expect(container.read(filterSettingsProvider).isEmpty, isTrue);
    });

    test('reset clears activePresetName (D-12)', () {
      final notifier = container.read(filterSettingsProvider.notifier);
      notifier.loadPreset(const FilterSettings(), presetName: 'Test');
      notifier.reset();
      expect(notifier.activePresetName, isNull);
    });

    test('isEmpty returns true when no filters set (FILT-05)', () {
      expect(container.read(filterSettingsProvider).isEmpty, isTrue);
    });
  });

  group('activeFilterQueryProvider', () {
    test('returns null when FilterSettings is empty (FILT-10)', () {
      expect(container.read(activeFilterQueryProvider), isNull);
    });

    test('returns query string when colors are set', () {
      container.read(filterSettingsProvider.notifier)
          .setColors({MtgColor.red});
      final query = container.read(activeFilterQueryProvider);
      expect(query, isNotNull);
      expect(query, contains('color:R'));
    });
  });
}
