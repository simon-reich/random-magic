import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:random_magic/core/constants/spacing.dart';
import 'package:random_magic/core/theme/app_theme.dart';
import 'package:random_magic/features/favourites/domain/favourite_card.dart';
import 'package:random_magic/features/favourites/presentation/providers.dart';

/// The main Favourites overview screen.
///
/// Displays saved cards in a 3-column art-crop grid (FAV-02). Supports:
/// - True empty state when no cards are saved (FAV-06)
/// - Filtered-empty state when active filters match nothing (FAV-07)
/// - Long-press multi-select with batch delete + Undo Snackbar (D-06, D-07, D-09)
/// - Filter bottom sheet (D-10, D-11)
/// - Tap on cell navigates to the favourites swipe view (FAV-03)
class FavouritesScreen extends ConsumerStatefulWidget {
  /// Creates the [FavouritesScreen].
  const FavouritesScreen({super.key});

  @override
  ConsumerState<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends ConsumerState<FavouritesScreen> {
  /// Whether multi-select mode is currently active (D-06).
  bool _isSelecting = false;

  /// The set of card IDs currently selected for batch deletion (D-06).
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredFavouritesProvider);
    final allFavourites = ref.watch(favouritesProvider);
    final filter = ref.watch(favouritesFilterProvider);

    return PopScope(
      // Back button exits multi-select instead of navigating back (D-07).
      canPop: !_isSelecting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() {
            _isSelecting = false;
            _selectedIds.clear();
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            _buildBody(context, filtered, allFavourites, filter),
          ],
        ),
      ),
    );
  }

  /// Builds the [SliverAppBar] that adapts to multi-select mode (D-06).
  ///
  /// In default mode: shows "Favourites" title and filter icon.
  /// In selecting mode: shows "{count} selected" title and delete icon.
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      floating: true,
      title: Text(
        _isSelecting
            ? _Strings.selectingTitle(_selectedIds.length)
            : _Strings.title,
      ),
      actions: [
        if (_isSelecting)
          IconButton(
            tooltip: _Strings.tooltipDelete,
            icon: const Icon(Icons.delete, color: AppColors.error),
            onPressed: _selectedIds.isEmpty ? null : _batchDelete,
          )
        else
          IconButton(
            tooltip: _Strings.tooltipFilter,
            icon: const Icon(Icons.filter_list),
            onPressed: () => _openFilterSheet(context),
          ),
      ],
    );
  }

  /// Builds the main body sliver, handling all interaction states.
  ///
  /// States in order of precedence:
  /// 1. No favourites at all — true empty state (FAV-06)
  /// 2. Favourites exist but filter matches nothing — filtered-empty state (FAV-07)
  /// 3. Success — 3-column art-crop grid (FAV-02)
  Widget _buildBody(
    BuildContext context,
    List<FavouriteCard> filtered,
    List<FavouriteCard> all,
    FavouritesFilter filter,
  ) {
    if (all.isEmpty) {
      // True empty state — no favourites saved at all (FAV-06).
      return SliverFillRemaining(
        child: _EmptyStateWidget(
          icon: Icons.favorite_outline,
          heading: _Strings.emptyHeading,
          body: _Strings.emptyBody,
        ),
      );
    }

    if (filtered.isEmpty) {
      // Filter is active but no cards match — offer to clear filters.
      return SliverFillRemaining(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _Strings.filteredEmptyMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () =>
                  ref.read(favouritesFilterProvider.notifier).reset(),
              child: const Text(_Strings.clearFilters),
            ),
          ],
        ),
      );
    }

    // Success state — 3-column art-crop grid (FAV-02, D-05).
    return SliverGrid.count(
      crossAxisCount: 3,
      mainAxisSpacing: AppSpacing.xs,
      crossAxisSpacing: AppSpacing.xs,
      // Square cells — art crop images have a 1:1 aspect ratio.
      childAspectRatio: 1.0,
      children: filtered
          .map(
            (card) => _FavouriteGridCell(
              card: card,
              isSelected: _selectedIds.contains(card.id),
              isSelecting: _isSelecting,
              onTap: () => _onCellTap(card),
              onLongPress: () => _onCellLongPress(card),
            ),
          )
          .toList(),
    );
  }

  /// Handles tap on a grid cell.
  ///
  /// In normal mode: navigates to the swipe view (FAV-03).
  /// In multi-select mode: toggles the card's selection (D-06).
  void _onCellTap(FavouriteCard card) {
    if (_isSelecting) {
      setState(() {
        if (_selectedIds.contains(card.id)) {
          _selectedIds.remove(card.id);
        } else {
          _selectedIds.add(card.id);
        }
      });
    } else {
      // Navigate to swipe view starting at this card (FAV-03).
      context.go('/favourites/${Uri.encodeComponent(card.id)}');
    }
  }

  /// Long-press enters multi-select mode and selects the pressed card (D-06).
  ///
  /// If already in multi-select mode, long-press on any cell exits it (D-07).
  void _onCellLongPress(FavouriteCard card) {
    setState(() {
      if (_isSelecting) {
        // Second long-press exits multi-select (D-07).
        _isSelecting = false;
        _selectedIds.clear();
      } else {
        _isSelecting = true;
        _selectedIds.add(card.id);
      }
    });
  }

  /// Deletes all selected cards immediately and shows an Undo Snackbar (D-09).
  ///
  /// Captures the deleted cards before removal so the undo closure can restore them.
  void _batchDelete() {
    final allFavourites = ref.read(favouritesProvider);
    // Capture deleted cards before removing so the undo closure holds valid references.
    final deleted = allFavourites
        .where((c) => _selectedIds.contains(c.id))
        .toList();

    setState(() {
      _isSelecting = false;
      _selectedIds.clear();
    });

    final notifier = ref.read(favouritesProvider.notifier);
    for (final card in deleted) {
      notifier.remove(card.id);
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(_Strings.batchDeleteMessage(deleted.length)),
          action: SnackBarAction(
            textColor: AppColors.primary,
            label: _Strings.undo,
            onPressed: () {
              // Restore all deleted cards in one batch (D-09 — single undo for batch).
              // FavouritesNotifier.add() is idempotent by card.id, so concurrent
              // additions during the undo window are handled safely (T-03-04-01).
              for (final card in deleted) {
                notifier.add(card);
              }
            },
          ),
        ),
      );
  }

  /// Opens the filter bottom sheet (D-10, FAV-07).
  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => _FavouritesFilterSheet(widgetRef: ref),
    );
  }
}

/// A single cell in the favourites grid.
///
/// Renders the art-crop image with a selection overlay when in multi-select mode
/// (D-05, D-06). Null [FavouriteCard.artCropUrl] falls back to a coloured box.
class _FavouriteGridCell extends StatelessWidget {
  const _FavouriteGridCell({
    required this.card,
    required this.isSelected,
    required this.isSelecting,
    required this.onTap,
    required this.onLongPress,
  });

  final FavouriteCard card;
  final bool isSelected;
  final bool isSelecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isSelected ? '${card.name}, selected' : card.name,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Art crop image (D-05) — null guard per Pitfall 6.
            card.artCropUrl != null
                ? CachedNetworkImage(
                    imageUrl: card.artCropUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const ColoredBox(color: AppColors.surfaceContainer),
                    errorWidget: (context, url, error) =>
                        const ColoredBox(color: AppColors.surfaceContainer),
                  )
                : const ColoredBox(color: AppColors.surfaceContainer),
            // Multi-select overlay — shown when this cell is selected (D-06).
            if (isSelected)
              Positioned.fill(
                child: Container(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.onBackground,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reusable empty state widget — icon, heading, and body copy (FAV-06).
class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget({
    required this.icon,
    required this.heading,
    required this.body,
  });

  final IconData icon;
  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.xxl, color: AppColors.onSurfaceMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            heading,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: AppColors.onBackground),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter bottom sheet for the Favourites grid.
///
/// Shows colour/type/rarity chip rows, matching the Phase 2 [FilterSettingsScreen]
/// chip style (D-11). Filter state is read/written via [FavouritesFilterNotifier].
class _FavouritesFilterSheet extends ConsumerWidget {
  const _FavouritesFilterSheet({required this.widgetRef});

  /// The [WidgetRef] from the parent screen — passed so this sheet can call
  /// [favouritesFilterProvider.notifier] on the same provider scope.
  final WidgetRef widgetRef;

  /// Card types available for filtering (same set as Phase 2 filter screen).
  static const List<String> _types = [
    'Creature',
    'Instant',
    'Sorcery',
    'Enchantment',
    'Artifact',
    'Land',
    'Planeswalker',
    'Battle',
  ];

  static const List<String> _rarities = [
    'common',
    'uncommon',
    'rare',
    'mythic',
  ];

  /// Colour codes — Scryfall single-char codes matching [FavouriteCard.colors] values.
  static const List<(String code, String label)> _colors = [
    ('W', 'White'),
    ('U', 'Blue'),
    ('B', 'Black'),
    ('R', 'Red'),
    ('G', 'Green'),
    ('C', 'Colorless'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(favouritesFilterProvider);
    final notifier = ref.read(favouritesFilterProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sheet title
          Text(
            _Strings.filterSheetTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          // Colour section
          Text('Colour', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _colors.map((entry) {
              final code = entry.$1;
              final label = entry.$2;
              return FilterChip(
                label: Text(label),
                selected: filter.colors.contains(code),
                showCheckmark: false,
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                onSelected: (selected) {
                  final updated = Set<String>.from(filter.colors);
                  selected ? updated.add(code) : updated.remove(code);
                  notifier.setColors(updated);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          // Type section
          Text('Type', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _types
                .map(
                  (type) => FilterChip(
                    label: Text(type),
                    selected: filter.types.contains(type),
                    showCheckmark: false,
                    selectedColor:
                        AppColors.primary.withValues(alpha: 0.2),
                    onSelected: (selected) {
                      final updated = Set<String>.from(filter.types);
                      selected ? updated.add(type) : updated.remove(type);
                      notifier.setTypes(updated);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          // Rarity section
          Text('Rarity', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _rarities
                .map(
                  (rarity) => FilterChip(
                    label: Text(
                      rarity[0].toUpperCase() + rarity.substring(1),
                    ),
                    selected: filter.rarities.contains(rarity),
                    showCheckmark: false,
                    selectedColor:
                        AppColors.primary.withValues(alpha: 0.2),
                    onSelected: (selected) {
                      final updated = Set<String>.from(filter.rarities);
                      selected
                          ? updated.add(rarity)
                          : updated.remove(rarity);
                      notifier.setRarities(updated);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Clear Filters button
          Center(
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: notifier.reset,
              child: const Text(_Strings.clearFilters),
            ),
          ),
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// All UI string literals for [FavouritesScreen] and its private widgets.
///
/// Centralised here to make copy-editing and localisation straightforward.
abstract final class _Strings {
  static const String title = 'Favourites';
  static String selectingTitle(int count) => '$count selected';
  static const String tooltipDelete = 'Remove from Favourites';
  static const String tooltipFilter = 'Filter Favourites';
  static const String emptyHeading = 'No Favourites Yet';
  static const String emptyBody = 'Swipe up on any card to save it here.';
  static const String filteredEmptyMessage = 'No cards match your filters.';
  static const String clearFilters = 'Clear Filters';
  static const String filterSheetTitle = 'Filter Favourites';
  static const String undo = 'Undo';
  static String batchDeleteMessage(int count) => '$count cards removed';
}
