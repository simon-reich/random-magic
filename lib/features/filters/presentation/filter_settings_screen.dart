import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:random_magic/core/constants/spacing.dart';
import 'package:random_magic/core/router/app_router.dart';
import 'package:random_magic/core/theme/app_theme.dart';
import 'package:random_magic/features/filters/domain/filter_preset.dart';
import 'package:random_magic/features/filters/domain/filter_settings.dart';
import 'package:random_magic/features/filters/presentation/providers.dart';
import 'package:random_magic/shared/models/mtg_color.dart';

/// Screen for configuring card discovery filters (FILT-01 through FILT-09).
///
/// Provides mana colour toggles, type and rarity chips, release date pickers,
/// named preset save/select/delete, and a reset control. All filter state
/// is managed by [FilterSettingsNotifier] via Riverpod — no local setState
/// except for the preset-name validation error display.
class FilterSettingsScreen extends ConsumerStatefulWidget {
  /// Creates the filter settings screen.
  const FilterSettingsScreen({super.key});

  @override
  ConsumerState<FilterSettingsScreen> createState() =>
      _FilterSettingsScreenState();
}

class _FilterSettingsScreenState extends ConsumerState<FilterSettingsScreen> {
  final _presetNameController = TextEditingController();

  /// Validation error shown below the preset name field (FILT-09).
  ///
  /// This is the only field that uses [setState] — all filter state lives
  /// in Riverpod providers.
  String? _saveError;

  static const _types = [
    'Creature',
    'Instant',
    'Sorcery',
    'Enchantment',
    'Artifact',
    'Land',
    'Planeswalker',
    'Battle',
  ];

  static const _rarities = [
    ('common', 'Common'),
    ('uncommon', 'Uncommon'),
    ('rare', 'Rare'),
    ('mythic', 'Mythic'),
  ];

  @override
  void dispose() {
    _presetNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(filterSettingsProvider);
    final notifier = ref.read(filterSettingsProvider.notifier);
    final presets = ref.watch(filterPresetsProvider);
    final presetsNotifier = ref.read(filterPresetsProvider.notifier);
    // Watch activePresetNameProvider so chip labels rebuild immediately when a
    // preset is loaded or any filter is mutated (D-12 dirty-state tracking).
    final activePresetName = ref.watch(activePresetNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        backgroundColor: AppColors.surface,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Preset chip row ──────────────────────────────────────────
            if (presets.isNotEmpty) ...[
              _sectionHeader(context, 'Presets'),
              const SizedBox(height: AppSpacing.xs),
              // Wrap so chips flow into multiple lines — never overflow/clip.
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: presets
                    .map(
                      (preset) => InputChip(
                        label: Text(
                          // D-12: * suffix shows while this preset is loaded
                          // and no filter has been mutated since. Watched via
                          // activePresetNameProvider for immediate rebuilds.
                          activePresetName == preset.name
                              ? '${preset.name}*'
                              : preset.name,
                        ),
                        backgroundColor: AppColors.surfaceContainer,
                        labelStyle: const TextStyle(
                          color: AppColors.onBackground,
                        ),
                        deleteIcon: const Icon(
                          Icons.close,
                          size: AppSpacing.md,
                        ),
                        onPressed: () {
                          // D-07: load preset, fire refresh signal (triggers
                          // new card even if query unchanged), then navigate.
                          notifier.loadPreset(
                            preset.settings,
                            presetName: preset.name,
                          );
                          ref
                              .read(filterRefreshSignalProvider.notifier)
                              .trigger();
                          context.go(AppRoutes.discovery);
                        },
                        onDeleted: () => presetsNotifier.delete(preset.name),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Colour toggles (FILT-01) ─────────────────────────────────
            _sectionHeader(context, 'Colour'),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: MtgColor.values
                    .map(
                      (color) => _ManaToggleButton(
                        color: color,
                        selected: filterState.colors.contains(color),
                        onTap: () {
                          final current = filterState.colors;
                          notifier.setColors(
                            current.contains(color)
                                ? current.difference({color})
                                : {...current, color},
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Type chips (FILT-02) ─────────────────────────────────────
            _sectionHeader(context, 'Type'),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: _types
                  .map(
                    (type) => FilterChip(
                      label: Text(type),
                      selected: filterState.types.contains(type),
                      showCheckmark: false,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      onSelected: (selected) {
                        final current = filterState.types;
                        notifier.setTypes(
                          selected
                              ? {...current, type}
                              : current.difference({type}),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Rarity chips (FILT-03) ───────────────────────────────────
            _sectionHeader(context, 'Rarity'),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: _rarities
                  .map(
                    ((String, String) entry) => FilterChip(
                      label: Text(entry.$2),
                      selected: filterState.rarities.contains(entry.$1),
                      showCheckmark: false,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      onSelected: (selected) {
                        final current = filterState.rarities;
                        notifier.setRarities(
                          selected
                              ? {...current, entry.$1}
                              : current.difference({entry.$1}),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Date range (FILT-04) ─────────────────────────────────────
            _sectionHeader(context, 'Release Date'),
            const SizedBox(height: AppSpacing.xs),
            _DateRow(
              label: 'Released After',
              date: filterState.releasedAfter,
              onPick: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: filterState.releasedAfter ?? DateTime.now(),
                  firstDate: DateTime(1993),
                  lastDate: DateTime.now(),
                );
                if (picked != null) notifier.setReleasedAfter(picked);
              },
              onClear: () => notifier.setReleasedAfter(null),
            ),
            _DateRow(
              label: 'Released Before',
              date: filterState.releasedBefore,
              onPick: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: filterState.releasedBefore ?? DateTime.now(),
                  firstDate: DateTime(1993),
                  lastDate: DateTime.now(),
                );
                if (picked != null) notifier.setReleasedBefore(picked);
              },
              onClear: () => notifier.setReleasedBefore(null),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Preset save section (FILT-06, FILT-09, D-08) ─────────────
            _sectionHeader(context, 'Save as Preset'),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _presetNameController,
                    maxLength: 50,
                    decoration: InputDecoration(
                      hintText: 'Preset name',
                      errorText: _saveError,
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: () => _savePreset(filterState, presetsNotifier),
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Reset button (FILT-10) ───────────────────────────────────
            Center(
              child: TextButton(
                onPressed: notifier.reset,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                child: const Text('Reset All Filters'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  /// Saves the current filter state as a named preset.
  ///
  /// Shows an inline error if the name is empty or already exists (FILT-09).
  void _savePreset(FilterSettings filterState, FilterPresetsNotifier notifier) {
    final name = _presetNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _saveError = 'Please enter a preset name');
      return;
    }
    final saved = notifier.save(
      FilterPreset(name: name, settings: filterState),
    );
    if (saved) {
      _presetNameController.clear();
      setState(() => _saveError = null);
    } else {
      setState(
        () => _saveError = 'A preset with that name already exists',
      );
    }
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(color: AppColors.onBackground),
    );
  }
}

/// A toggle button for a single MTG mana colour symbol.
///
/// Shows the Scryfall SVG icon for most colours. [MtgColor.multicolor]
/// renders a gradient sweep widget instead (no official SVG symbol).
class _ManaToggleButton extends StatelessWidget {
  const _ManaToggleButton({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final MtgColor color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.xxl),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? null : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSpacing.xxl),
          border: selected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Center(child: _symbolWidget()),
      ),
    );
  }

  Widget _symbolWidget() {
    if (color == MtgColor.multicolor) {
      return _MulticolorSymbol();
    }
    return SvgPicture.network(
      color.svgUrl!,
      width: 32,
      height: 32,
      placeholderBuilder: (_) => _ManaSymbolFallback(label: color.code),
    );
  }
}

/// Gradient sweep circle representing the multicolor (M) mana symbol.
///
/// Scryfall has no SVG for multicolor, so we render a custom widget using
/// Flutter SDK named colours for the gradient segments.
class _MulticolorSymbol extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        // Flutter SDK named colours — not app-specific magic numbers
        gradient: SweepGradient(
          colors: [
            Colors.white,
            Colors.blue,
            Colors.black,
            Colors.red,
            Colors.green,
            Colors.white,
          ],
        ),
      ),
      child: const Center(
        child: Text(
          'M',
          style: TextStyle(
            color: AppColors.onBackground,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Fallback widget shown while an SVG mana symbol is loading or on error.
class _ManaSymbolFallback extends StatelessWidget {
  const _ManaSymbolFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: AppColors.surfaceContainer,
      radius: 16,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.onBackground,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// A row showing a date label and a tap-to-pick button with an optional clear X.
class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.onSurfaceMuted),
            ),
          ),
          TextButton(
            onPressed: onPick,
            child: Text(
              date != null ? _formatDate(date!) : 'Any',
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
          if (date != null)
            IconButton(
              icon: const Icon(
                Icons.close,
                size: AppSpacing.md,
                color: AppColors.onSurfaceMuted,
              ),
              onPressed: onClear,
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
