import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:random_magic/core/constants/spacing.dart';
import 'package:random_magic/core/theme/app_theme.dart';
import 'package:random_magic/features/card_discovery/presentation/providers.dart'
    show cardRepositoryProvider;
import 'package:random_magic/features/favourites/domain/favourite_card.dart';
import 'package:random_magic/features/favourites/presentation/providers.dart';
import 'package:random_magic/shared/result.dart';

/// Swipe-through view for saved favourites.
///
/// Displays all favourites in a card-swiper starting at the card matching
/// [favouriteId]. Provides a delete button in the AppBar with an Undo Snackbar (FAV-04).
class FavouriteSwipeScreen extends ConsumerStatefulWidget {
  const FavouriteSwipeScreen({super.key, required this.favouriteId});

  /// The Scryfall card ID passed via the `/favourites/:id` route parameter.
  final String favouriteId;

  @override
  ConsumerState<FavouriteSwipeScreen> createState() =>
      _FavouriteSwipeScreenState();
}

class _FavouriteSwipeScreenState extends ConsumerState<FavouriteSwipeScreen> {
  // CardSwiperController is a UI concern — lives on state, not in Riverpod (D-08).
  late final CardSwiperController _swiperController;

  // Track current displayed card index so the delete button knows which card to remove.
  late int _currentIndex;

  // Explicit timer to dismiss the Undo Snackbar — belt-and-suspenders against the
  // Flutter built-in duration mechanism not firing reliably with nested scaffolds
  // inside a GoRouter StatefulShellRoute.
  Timer? _snackBarTimer;

  // Incremented when CardSwiper must be rebuilt from scratch (e.g. after deleting
  // the last card so the swiper seeks to the new last index via initialIndex).
  // CardSwiper ignores initialIndex changes after creation; a new key forces it.
  int _swiperKey = 0;

  @override
  void initState() {
    super.initState();
    _swiperController = CardSwiperController();
    // Seek to the card matching favouriteId in the sorted list.
    // initialIndex is verified to exist in flutter_card_swiper 7.2.0 constructor.
    final favourites = ref.read(favouritesProvider);
    _currentIndex = favourites.indexWhere((c) => c.id == widget.favouriteId);
    // Guard: if id not found (card was deleted between tap and navigation), default to 0.
    if (_currentIndex < 0) _currentIndex = 0;
  }

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favourites = ref.watch(favouritesProvider);

    // If all favourites deleted, navigate back to the grid (FAV-04 edge case).
    // T-03-05-02: CardSwiper must never render with cardsCount: 0 — guard here.
    if (favourites.isEmpty) {
      // Use addPostFrameCallback to navigate after build completes.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SizedBox.shrink(),
      );
    }

    // Clamp current index in case cards were deleted while swiping.
    if (_currentIndex >= favourites.length) {
      _currentIndex = favourites.length - 1;
    }

    final currentCard = favourites[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(currentCard.name),
        actions: [
          IconButton(
            tooltip: _Strings.tooltipDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _deleteCurrent(currentCard),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: AspectRatio(
              aspectRatio: 63 / 88, // Standard MTG card ratio
              child: CardSwiper(
                key: ValueKey(_swiperKey),
                controller: _swiperController,
                cardsCount: favourites.length,
                numberOfCardsDisplayed: 1,
                // initialIndex verified in flutter_card_swiper 7.2.0 source (card_swiper.dart:143).
                // Seeks the swiper to the card the user tapped in the grid (FAV-03).
                initialIndex: _currentIndex,
                onSwipe: (previousIndex, currentIndex, direction) {
                  // Always return true — advance normally on all swipe directions.
                  // Deletion is handled exclusively via the AppBar delete button (D-08).
                  // Returning true is correct: we verified from package source that
                  // false cancels the animation, true completes it and advances the index.
                  setState(() {
                    _currentIndex = currentIndex ?? previousIndex;
                  });
                  return true;
                },
                cardBuilder: (context, index, percentX, percentY) {
                  // Guard: CardSwiper may call the builder with a stale index
                  // in the frame between a delete and the widget's cardsCount update.
                  if (index >= favourites.length) return const SizedBox.shrink();
                  final card = favourites[index];
                  // CARD-01 / Pitfall 6 resolution: FavouriteCard lacks the full
                  // metadata CardDetailScreen requires (legalities, prices, etc.).
                  // Fetch the full MagicCard via getCardById before navigating so
                  // CardDetailScreen receives all data without re-fetching itself.
                  // Goes through repository — no direct API call from presentation.
                  return GestureDetector(
                    onTap: () async {
                      final result = await ref
                          .read(cardRepositoryProvider)
                          .getCardById(card.id);
                      switch (result) {
                        case Success(:final value):
                          // context.mounted guard required after the await boundary.
                          if (context.mounted) {
                            context.push('/card/${value.id}', extra: value);
                          }
                        case Failure():
                          // Show generic snackbar on failure — no API detail exposed
                          // (T-04-11: information disclosure accept).
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not load card details. Try again.',
                                ),
                              ),
                            );
                          }
                      }
                    },
                    child: _FavouriteCardFace(card: card),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Deletes [card] immediately from Hive and shows a 3-second Undo Snackbar (D-08).
  void _deleteCurrent(FavouriteCard card) {
    // Capture before removing — needed for undo closure.
    final deleted = card;
    ref.read(favouritesProvider.notifier).remove(deleted.id);

    // If we just deleted the last card in the list, step _currentIndex back and
    // force CardSwiper to rebuild via _swiperKey — CardSwiper ignores initialIndex
    // changes after creation, so a key change is required to seek to the new index.
    final remaining = ref.read(favouritesProvider).length;
    if (remaining > 0 && _currentIndex >= remaining) {
      setState(() {
        _currentIndex = remaining - 1;
        _swiperKey++;
      });
    }
    // remaining == 0 is handled by the isEmpty guard in build().

    _snackBarTimer?.cancel();
    final messenger = ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          // Floating renders above the bottom nav bar.
          behavior: SnackBarBehavior.floating,
          // duration is set for correctness; explicit timer below is the reliable path
          // because Flutter's built-in dismissal doesn't fire reliably with nested
          // scaffolds inside a GoRouter StatefulShellRoute.
          duration: const Duration(days: 1),
          content: Text(_Strings.deleteMessage(deleted.name)),
          action: SnackBarAction(
            textColor: AppColors.primary,
            label: _Strings.undo,
            // Undo closure: re-inserts the deleted card. add() is idempotent by
            // card.id so double-undo within a single Snackbar lifecycle is safe (T-03-05-03).
            onPressed: () {
              _snackBarTimer?.cancel();
              ref.read(favouritesProvider.notifier).add(deleted);
              // Restore _currentIndex to the re-added card so the swiper
              // jumps back to it (mirrors the original delete jump-back).
              final restored = ref
                  .read(favouritesProvider)
                  .indexWhere((c) => c.id == deleted.id);
              if (restored >= 0) {
                setState(() {
                  _currentIndex = restored;
                  _swiperKey++;
                });
              }
            },
          ),
        ),
      );
    // Explicit 3-second dismissal timer — works around nested-scaffold timing issue.
    _snackBarTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) messenger.hideCurrentSnackBar();
    });
  }
}

/// Displays a single favourite card image in the swipe view.
///
/// Uses [FavouriteCard.normalImageUrl] for the full card face image.
/// Falls back to [AppColors.surface] background when the URL is null.
class _FavouriteCardFace extends StatelessWidget {
  const _FavouriteCardFace({required this.card});

  final FavouriteCard card;

  @override
  Widget build(BuildContext context) {
    final imageUrl = card.normalImageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const ColoredBox(color: AppColors.surface),
              errorWidget: (context, url, error) =>
                  const ColoredBox(color: AppColors.surface),
            )
          : const ColoredBox(color: AppColors.surface),
    );
  }
}

/// Private string constants for [FavouriteSwipeScreen].
abstract final class _Strings {
  static const String tooltipDelete = 'Remove from Favourites';
  static String deleteMessage(String name) => '$name removed';
  static const String undo = 'Undo';
}
