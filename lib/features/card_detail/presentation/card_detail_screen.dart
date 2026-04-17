import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:random_magic/core/theme/app_theme.dart';
import 'package:random_magic/shared/models/magic_card.dart';

/// Full-screen detail view for a single Magic: The Gathering card.
///
/// Receives [card] via GoRouter [state.extra] — no Scryfall re-fetch occurs.
/// If [card] is null (e.g. route restored after OS kill), shows an error widget.
///
/// Implements CARD-01 through CARD-05.
class CardDetailScreen extends ConsumerStatefulWidget {
  const CardDetailScreen({super.key, required this.card});

  /// The card to display. Null when GoRouter extra was lost (OS kill / deep link).
  final MagicCard? card;

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    if (card == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.onSurfaceMuted, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Card not available. Go back and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }
    // Full implementation delivered in plan 04-02.
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(card.name),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
