// ignore_for_file: unused_import
import 'package:random_magic/features/filters/domain/filter_preset.dart';
import 'package:random_magic/features/filters/domain/filter_settings.dart';
import 'package:random_magic/shared/models/mtg_color.dart';

/// Returns a [FilterPreset] named 'Budget Aggro' with R (Red) and Creature filters.
FilterPreset fakeBudgetAggroPreset() => FilterPreset(
      name: 'Budget Aggro',
      settings: FilterSettings(
        colors: {MtgColor.red},
        types: {'Creature'},
        rarities: {'common'},
      ),
    );
