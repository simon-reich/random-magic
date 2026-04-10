import 'package:flutter/material.dart';

/// Placeholder for the card detail screen.
///
/// Receives [cardId] from the `/card/:id` route parameter.
/// Will be replaced with the full detail implementation in a later ticket.
class CardDetailScreen extends StatelessWidget {
  const CardDetailScreen({super.key, required this.cardId});

  /// The Scryfall card ID passed via the route.
  final String cardId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card Detail')),
      body: Center(
        child: Text('Card ID: $cardId'),
      ),
    );
  }
}
