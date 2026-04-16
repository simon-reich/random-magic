/// Shared re-export of the Favourites providers for cross-feature access.
///
/// CLAUDE.md prohibits features from importing each other's `presentation/` layers
/// directly. This file exposes [favouritesProvider] and [FavouritesNotifier] through
/// the `shared/` layer so that `card_discovery` can legally depend on it.
///
/// Source of truth: [lib/features/favourites/presentation/providers.dart].
/// Do not duplicate logic here — only re-export.
library;

export 'package:random_magic/features/favourites/presentation/providers.dart'
    show favouritesProvider, FavouritesNotifier;
