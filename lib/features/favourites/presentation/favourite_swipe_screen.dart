import 'package:flutter/material.dart';

/// Placeholder for the individual favourite swipe screen.
///
/// Receives [favouriteId] from the `/favourites/:id` route parameter.
/// Will be replaced with the full swipe implementation in a later ticket.
class FavouriteSwipeScreen extends StatelessWidget {
  const FavouriteSwipeScreen({super.key, required this.favouriteId});

  /// The local favourite ID passed via the route.
  final String favouriteId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favourite')),
      body: Center(
        child: Text('Favourite ID: $favouriteId'),
      ),
    );
  }
}
