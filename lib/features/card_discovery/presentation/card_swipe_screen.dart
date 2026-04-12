import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:random_magic/core/constants/spacing.dart';
import 'package:random_magic/core/router/app_router.dart';
import 'package:random_magic/core/theme/app_theme.dart';
import 'package:random_magic/features/card_discovery/presentation/providers.dart';
import 'package:random_magic/shared/failures.dart';
import 'package:random_magic/shared/models/magic_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// The main card discovery screen.
///
/// Displays a random MTG card and allows the user to swipe left or right
/// to load the next card. Shows a skeletonizer loading state during fetch
/// and three distinct card-shaped error states on failure.
class CardSwipeScreen extends ConsumerStatefulWidget {
  const CardSwipeScreen({super.key});

  @override
  ConsumerState<CardSwipeScreen> createState() => _CardSwipeScreenState();
}

class _CardSwipeScreenState extends ConsumerState<CardSwipeScreen> {
  // CardSwiperController is a UI concern — lives on state, not in Riverpod (D-08).
  late final CardSwiperController _swiperController;

  @override
  void initState() {
    super.initState();
    _swiperController = CardSwiperController();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardState = ref.watch(randomCardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: AspectRatio(
              aspectRatio: 63 / 88, // Standard MTG card ratio (D-02)
              child: cardState.when(
                loading: () => _buildLoadingCard(),
                data: (card) => _buildSwipeStack(card, isLoading: false),
                error: (error, _) => _buildErrorCard(error),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Renders a skeletonizer shimmer in the card shape while fetching (D-04, D-18).
  ///
  /// Uses a real [_CardFaceWidget] as the skeleton shape so the shimmer matches
  /// the actual card layout exactly. No fake data is shown — placeholder card
  /// has empty strings throughout.
  Widget _buildLoadingCard() {
    // Skeletonizer wraps the real widget tree — no separate skeleton layout (D-18).
    // A placeholder card with empty fields is used purely for widget shape.
    const placeholder = MagicCard(
      id: '',
      name: '',
      typeLine: '',
      rarity: '',
      setCode: '',
      setName: '',
      collectorNumber: '',
      releasedAt: '',
      imageUris: CardImageUris(),
      legalities: {}, // const required — {} alone is not a const expression
    );
    return Skeletonizer(
      enabled: true,
      child: _CardFaceWidget(card: placeholder),
    );
  }

  /// Renders the swiper widget wrapping the card face (D-01, D-05, D-06, D-07).
  ///
  /// [isLoading] gates the swiper so new requests cannot be triggered while
  /// the previous fetch is in flight — but loading state is handled via the
  /// [loading] branch above, so isLoading is always false here (D-06).
  Widget _buildSwipeStack(MagicCard card, {required bool isLoading}) {
    return CardSwiper(
      controller: _swiperController,
      cardsCount: 1,
      isDisabled: isLoading, // always false — swipe gating achieved by widget replacement in the loading: branch
      onSwipe: (previousIndex, currentIndex, direction) {
        // Both left and right load the next random card (D-07).
        ref.read(randomCardProvider.notifier).refresh();
        return true;
      },
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        // flutter_card_swiper provides int percentage values (0–100); normalize to 0.0–1.0.
        return _CardFaceWidget(
          card: card,
          swipePercentX: percentThresholdX / 100.0,
        );
      },
    );
  }

  /// Builds the appropriate card-shaped error widget for [error].
  ///
  /// All error states render inside the AspectRatio(63/88) card slot (D-14).
  Widget _buildErrorCard(Object error) {
    if (error is CardNotFoundFailure) {
      return _CardErrorWidget(
        icon: Icons.search_off_rounded,
        accentColor: AppColors.primaryVariant, // amber/orange (D-16)
        title: 'No cards found',
        subtitle: 'Your current filters returned no results.\nTry adjusting them.',
        actionLabel: 'Adjust Filters', // D-17
        onAction: () => context.go(AppRoutes.filters),
      );
    }
    if (error is InvalidQueryFailure) {
      return _CardErrorWidget(
        icon: Icons.error_outline_rounded,
        accentColor: AppColors.error, // red (D-16)
        title: 'Invalid filter settings',
        subtitle: 'The current filter combination is not valid.\nPlease fix your filters.',
        actionLabel: 'Fix Filters', // D-17
        onAction: () => context.go(AppRoutes.filters),
      );
    }
    if (error is RateLimitedFailure) {
      // Blue-grey accent matches NetworkFailure — both mean "can't get a card right now, try again".
      // Message is distinct: rate limit vs. connectivity (DISC-09).
      return _CardErrorWidget(
        icon: Icons.hourglass_top_rounded,
        accentColor: AppColors.networkError, // blue-grey (D-16)
        title: 'Too Many Requests',
        subtitle: 'Scryfall rate limit hit.\nWait a moment before trying again.',
        actionLabel: 'Retry',
        onAction: () => ref.read(randomCardProvider.notifier).refresh(),
      );
    }
    // NetworkFailure and unknown errors (D-16: blue-grey accent).
    return _CardErrorWidget(
      icon: Icons.cloud_off_rounded,
      accentColor: AppColors.networkError, // blue-grey — defined in AppColors (Plan 01)
      title: 'Could not reach Scryfall',
      subtitle: 'Check your connection and try again.',
      actionLabel: 'Retry', // D-17
      onAction: () => ref.read(randomCardProvider.notifier).refresh(),
    );
  }
}

/// Displays the full card face image and swipe overlay label.
///
/// [swipePercentX] drives the overlay opacity — 0.0 when idle, approaching
/// 1.0 as the card is dragged to threshold.
class _CardFaceWidget extends StatelessWidget {
  const _CardFaceWidget({required this.card, this.swipePercentX = 0.0});

  final MagicCard card;

  /// Horizontal drag percentage normalized to –1.0 to 1.0 from CardSwiper.
  final double swipePercentX;

  @override
  Widget build(BuildContext context) {
    // D-04: null image URL guard — use normal format; fall back to empty string
    // (CardImageUris.normal is nullable; double-faced fallback handled in fromJson).
    final imageUrl = card.imageUris.normal ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Full card face image (D-01) — normal format (~488×680 px).
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: imageUrl.isEmpty
              ? const ColoredBox(color: AppColors.surface)
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const ColoredBox(color: AppColors.surface),
                  errorWidget: (context, url, error) =>
                      const ColoredBox(color: AppColors.surface),
                ),
        ),
        // Swipe overlay label (D-10, D-11) — fades in during drag.
        // "REVEAL" — MTG-flavored, discovery theme, ≤8 chars.
        if (swipePercentX.abs() > 0.05)
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.center,
                child: Opacity(
                  opacity: (swipePercentX.abs() * 2.0).clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primary, // D-12: accent palette
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                    child: Text(
                      'REVEAL', // D-11: MTG-flavored discovery label
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary, // D-12
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Card-shaped error placeholder widget.
///
/// Renders inside the same AspectRatio(63/88) slot as the card image,
/// keeping layout stable across all states (D-14). Column layout:
/// icon → title → subtitle → action button (D-15).
class _CardErrorWidget extends StatelessWidget {
  const _CardErrorWidget({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppSpacing.xxl, color: accentColor),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: accentColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: AppColors.background,
              shape: const StadiumBorder(),
            ),
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
