import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:random_magic/core/constants/spacing.dart';
import 'package:random_magic/core/theme/app_theme.dart';
import 'package:random_magic/shared/models/magic_card.dart';

/// Layout constant — height of the expanded SliverAppBar artwork area.
/// Derived from standard MTG card ratio (63:88) at ~315px width ≈ 440px height.
const double _kDetailArtworkHeight = 440.0;

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
    // When _showBack is true and cardFaces has a back face, use face[1] values.
    final backFace = (_showBack && (card.cardFaces?.length ?? 0) >= 2)
        ? card.cardFaces![1]
        : null;

    final displayName = backFace?.name ?? card.name;
    final displayTypeLine = backFace?.typeLine ?? card.typeLine;
    final displayOracleText = backFace?.oracleText ?? card.oracleText;

    // D-06: large format for detail screen; fall back to normal.
    final displayImageUrl = backFace != null
        ? (backFace.imageUris.large ?? backFace.imageUris.normal ?? '')
        : (card.imageUris.large ?? card.imageUris.normal ?? '');

    // D-04: mana cost always shows front-face value (back faces often lack mana cost).
    final displayManaCost = card.manaCost ?? card.cardFaces?[0].manaCost;

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
          // D-05: SliverAppBar with expandedHeight; collapses to standard AppBar on scroll.
          SliverAppBar(
            expandedHeight: _kDetailArtworkHeight,
            pinned: true,
            stretch: false,
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.onBackground,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              // Title visible in both expanded and collapsed state;
              // FlexibleSpaceBar handles opacity transition automatically.
              title: Text(
                displayName,
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: _CardArtwork(imageUrl: displayImageUrl),
            ),
          ),
          // Content sections below the artwork (D-07: section order locked).
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.lg),
                // Mana cost + type line header
                if (displayManaCost != null)
                  Text(
                    displayManaCost,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                if (displayManaCost != null) const SizedBox(height: AppSpacing.xs),
                Text(
                  displayTypeLine,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                // Oracle text (CARD-02)
                if (displayOracleText != null)
                  _OracleTextSection(oracleText: displayOracleText),
                // Flavour text — hidden entirely when null (CARD-02, D-07)
                if (card.flavorText != null)
                  _FlavorTextSection(flavorText: card.flavorText!),
                // Divider between text sections and info sections
                const Divider(
                  color: AppColors.surfaceContainer,
                  height: AppSpacing.xl,
                ),
                // Set info section (CARD-02)
                _SetInfoSection(card: card),
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
      appBar: AppBar(backgroundColor: AppColors.background),
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
            // Null placeholder: CachedNetworkImage shows a colored box via placeholder
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

/// Oracle text section — rules text for the card or active face.
///
/// No section heading; oracle text is displayed directly as body text.
class _OracleTextSection extends StatelessWidget {
  const _OracleTextSection({required this.oracleText});

  final String oracleText;

  @override
  Widget build(BuildContext context) {
    return Text(
      oracleText,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

/// Flavour text section — italic body text.
///
/// Only rendered when [flavorText] is non-null (CARD-02, D-07).
/// No section heading.
class _FlavorTextSection extends StatelessWidget {
  const _FlavorTextSection({required this.flavorText});

  final String flavorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
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

/// Set info section — set name, collector number, and release date (CARD-02).
class _SetInfoSection extends StatelessWidget {
  const _SetInfoSection({required this.card});

  final MagicCard card;

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
        _InfoRow(label: 'Released', value: card.releasedAt),
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
        // Required formats (CARD-04, D-08)
        _LegalityRow(format: 'Standard', status: legalities['standard']),
        _LegalityRow(format: 'Modern', status: legalities['modern']),
        _LegalityRow(format: 'Legacy', status: legalities['legacy']),
        _LegalityRow(format: 'Commander', status: legalities['commander']),
        // Additional formats at Claude's discretion (CONTEXT.md §Claude's Discretion)
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
    // Derive badge color from Scryfall legality string (lowercase keys — Pitfall 5).
    final badgeColor = switch (status) {
      'legal'      => AppColors.legal,
      'banned'     => AppColors.error,
      'restricted' => AppColors.primaryVariant,
      _            => AppColors.onSurfaceMuted, // 'not_legal', null
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
              // 15% opacity fill with solid border — D-08 badge visual.
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
