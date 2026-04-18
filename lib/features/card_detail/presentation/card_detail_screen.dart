import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:random_magic/core/constants/spacing.dart';
import 'package:random_magic/core/theme/app_theme.dart';
import 'package:random_magic/features/favourites/domain/favourite_card.dart';
import 'package:random_magic/features/favourites/presentation/providers.dart'
    show favouritesProvider;
import 'package:random_magic/shared/models/magic_card.dart';

/// Layout constant — height of the expanded SliverAppBar artwork area.
/// Derived from standard MTG card ratio (63:88) at ~315px width ≈ 440px height.
const double _kDetailArtworkHeight = 440.0;

/// Formats a Scryfall ISO date string (e.g. "2009-07-17") as "July 2009".
String _formatReleaseDate(String iso) {
  final parts = iso.split('-');
  if (parts.length < 2) return iso;
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  final month = int.tryParse(parts[1]);
  if (month == null || month < 1 || month > 12) return iso;
  return '${months[month - 1]} ${parts[0]}';
}

/// Full-screen detail view for a single Magic: The Gathering card.
///
/// Receives [card] via GoRouter [state.extra] — no Scryfall re-fetch occurs
/// in this screen (CARD-01, D-01). If [card] is null (route restored after OS
/// kill), shows an error widget with a Back button.
///
/// Implements CARD-02 through CARD-05.
class CardDetailScreen extends ConsumerStatefulWidget {
  const CardDetailScreen({super.key, required this.card});

  /// The card to display. Null when GoRouter extra was lost (OS kill / deep link).
  final MagicCard? card;

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  /// Tracks which face to show on double-faced cards.
  /// false = front face (default); true = back face (D-04, CARD-05).
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;

    // Null guard: extra lost after OS kill — show error widget (Pitfall 2).
    if (card == null) {
      return _buildErrorScaffold(context);
    }

    // Derive display values from active face (D-04).
    final backFace = (_showBack && (card.cardFaces?.length ?? 0) >= 2)
        ? card.cardFaces![1]
        : null;

    final displayName = backFace?.name ?? card.name;
    final displayTypeLine = backFace?.typeLine ?? card.typeLine;
    final displayArtist = backFace?.artist ?? card.artist;

    // D-06: large format for detail screen; fall back to normal.
    final displayImageUrl = backFace != null
        ? (backFace.imageUris.large ?? backFace.imageUris.normal ?? '')
        : (card.imageUris.large ?? card.imageUris.normal ?? '');

    // Reactive favourite state — rebuilds when favourites change.
    final isFav = ref.watch(
      favouritesProvider.select((cards) => cards.any((c) => c.id == card.id)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      // D-05: flip FAB shown only for DFCs (CARD-05).
      floatingActionButton: card.cardFaces != null
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              tooltip: _showBack ? 'Show front face' : 'Show back face',
              onPressed: () => setState(() => _showBack = !_showBack),
              child: const Icon(Icons.flip),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: _kDetailArtworkHeight,
            pinned: true,
            stretch: false,
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.onBackground,
            // Explicit back button — works for both button tap and Android system back.
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                color: isFav ? AppColors.error : AppColors.onBackground,
                tooltip: isFav ? 'Remove from favourites' : 'Add to favourites',
                onPressed: () {
                  final notifier =
                      ref.read(favouritesProvider.notifier);
                  if (isFav) {
                    notifier.remove(card.id);
                  } else {
                    notifier.add(FavouriteCard(
                      id: card.id,
                      name: card.name,
                      typeLine: card.typeLine,
                      rarity: card.rarity,
                      setCode: card.setCode,
                      savedAt: DateTime.now(),
                      colors: card.colors,
                      artCropUrl: card.imageUris.artCrop,
                      normalImageUrl: card.imageUris.normal,
                      manaCost: card.manaCost,
                    ));
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              // No title — card name appears below the artwork, not overlaid on it.
              background: _CardArtwork(imageUrl: displayImageUrl),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.lg),
                // Card name below artwork
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  displayTypeLine,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurfaceMuted,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Flavour text — hidden entirely when null (CARD-02, D-07)
                if (card.flavorText != null)
                  _FlavorTextSection(flavorText: card.flavorText!),
                const Divider(
                  color: AppColors.surfaceContainer,
                  height: AppSpacing.xl,
                ),
                // Set info section (CARD-02)
                _SetInfoSection(card: card, artist: displayArtist),
                const Divider(
                  color: AppColors.surfaceContainer,
                  height: AppSpacing.xl,
                ),
                // Prices section (CARD-03)
                _PricesSection(prices: card.prices),
                const Divider(
                  color: AppColors.surfaceContainer,
                  height: AppSpacing.xl,
                ),
                // Format legalities section (CARD-04)
                _LegalitiesSection(legalities: card.legalities),
                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the error scaffold shown when [widget.card] is null.
  Widget _buildErrorScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.onSurfaceMuted,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Card not available. Go back and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays the card artwork as a full-bleed image with shimmer placeholder.
///
/// Used as the [FlexibleSpaceBar.background] inside [SliverAppBar].
class _CardArtwork extends StatelessWidget {
  const _CardArtwork({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return imageUrl.isEmpty
        ? const ColoredBox(color: AppColors.surface)
        : CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                const ColoredBox(color: AppColors.surface),
            errorWidget: (context, url, error) => const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: AppColors.onSurfaceMuted,
                size: 48,
              ),
            ),
          );
  }
}

/// Flavour text section — italic body text.
///
/// Only rendered when [flavorText] is non-null (CARD-02, D-07).
class _FlavorTextSection extends StatelessWidget {
  const _FlavorTextSection({required this.flavorText});

  final String flavorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
      child: Text(
        flavorText,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.onSurfaceMuted,
            ),
      ),
    );
  }
}

/// Set info section — set name, collector number, release date, and artist (CARD-02).
class _SetInfoSection extends StatelessWidget {
  const _SetInfoSection({required this.card, required this.artist});

  final MagicCard card;
  final String? artist;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Info',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        _InfoRow(label: 'Set', value: card.setName),
        _InfoRow(label: 'Number', value: card.collectorNumber),
        _InfoRow(label: 'Released', value: _formatReleaseDate(card.releasedAt)),
        if (artist != null) _InfoRow(label: 'Artist', value: artist!),
      ],
    );
  }
}

/// A single label/value row for set info display.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Prices section — USD, USD Foil, EUR; shows 'N/A' when null (CARD-03).
class _PricesSection extends StatelessWidget {
  const _PricesSection({required this.prices});

  final CardPrices? prices;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prices',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        _PriceRow(label: 'USD', value: prices?.usd ?? 'N/A'),
        _PriceRow(label: 'USD Foil', value: prices?.usdFoil ?? 'N/A'),
        _PriceRow(label: 'EUR', value: prices?.eur ?? 'N/A'),
      ],
    );
  }
}

/// A single price row with label and value.
class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Format legalities section (CARD-04).
///
/// Shows Standard, Modern, Legacy, Commander at minimum (D-08).
/// Additional formats (Pioneer, Vintage, Pauper) included for completeness.
class _LegalitiesSection extends StatelessWidget {
  const _LegalitiesSection({required this.legalities});

  final Map<String, String> legalities;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Format Legalities',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        _LegalityRow(format: 'Standard', status: legalities['standard']),
        _LegalityRow(format: 'Modern', status: legalities['modern']),
        _LegalityRow(format: 'Legacy', status: legalities['legacy']),
        _LegalityRow(format: 'Commander', status: legalities['commander']),
        _LegalityRow(format: 'Pioneer', status: legalities['pioneer']),
        _LegalityRow(format: 'Vintage', status: legalities['vintage']),
        _LegalityRow(format: 'Pauper', status: legalities['pauper']),
      ],
    );
  }
}

/// A single format row with a colored legality badge (D-08).
///
/// Badge colors:
///   legal      → AppColors.legal (green, #4CAF50)
///   banned     → AppColors.error (red, #CF6679)
///   restricted → AppColors.primaryVariant (amber, #F0A500)
///   other/null → AppColors.onSurfaceMuted (grey, #9E9EAE)
class _LegalityRow extends StatelessWidget {
  const _LegalityRow({required this.format, required this.status});

  final String format;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final badgeColor = switch (status) {
      'legal'      => AppColors.legal,
      'banned'     => AppColors.error,
      'restricted' => AppColors.primaryVariant,
      _            => AppColors.onSurfaceMuted,
    };

    final badgeLabel = switch (status) {
      'legal'      => 'Legal',
      'banned'     => 'Banned',
      'restricted' => 'Restricted',
      _            => 'Not Legal',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(format, style: Theme.of(context).textTheme.bodyMedium),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              border: Border.all(color: badgeColor),
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Text(
              badgeLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: badgeColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
