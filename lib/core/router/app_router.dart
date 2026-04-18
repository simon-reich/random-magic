import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:random_magic/features/card_detail/presentation/card_detail_screen.dart';
import 'package:random_magic/shared/models/magic_card.dart';
import 'package:random_magic/features/card_discovery/presentation/card_swipe_screen.dart';
import 'package:random_magic/features/favourites/presentation/favourite_swipe_screen.dart';
import 'package:random_magic/features/favourites/presentation/favourites_screen.dart';
import 'package:random_magic/features/filters/presentation/filter_settings_screen.dart';

/// Named route constants — use these instead of raw path strings.
abstract final class AppRoutes {
  static const discovery = '/';
  /// Card detail reached from the Discover tab — nested so bottom nav stays visible.
  static const cardDetailFromDiscovery = '/card/:id';
  /// Card detail reached from the Favourites tab — nested so bottom nav stays visible.
  static const cardDetailFromFavourites = '/favourites/card/:id';
  static const filters = '/filters';
  static const favourites = '/favourites';
  static const favouriteSwipe = '/favourites/:id';
}

GoRoute _cardDetailRoute(String path) => GoRoute(
      path: path,
      builder: (context, state) {
        // Guard: extra may be null if the route is restored after an OS kill.
        final card = state.extra is MagicCard ? state.extra as MagicCard : null;
        return CardDetailScreen(card: card);
      },
    );

/// The [GoRouter] instance for the app.
///
/// Uses a [StatefulShellRoute] so each bottom-nav tab maintains its own
/// navigation stack and scroll position across tab switches.
///
/// Card detail is nested inside each branch rather than sitting above the shell,
/// so the bottom navigation bar stays visible and re-tapping the active tab
/// resets the branch to its root (acting as an additional back gesture).
final appRouter = GoRouter(
  initialLocation: AppRoutes.discovery,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _ShellScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.discovery,
              builder: (context, state) => const CardSwipeScreen(),
              routes: [
                // 'card/:id' resolves to '/card/:id' — nested under Discover branch.
                _cardDetailRoute('card/:id'),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.favourites,
              builder: (context, state) => const FavouritesScreen(),
              routes: [
                // 'card/:id' defined before ':id' so the literal segment wins
                // over the wildcard when the path starts with 'card/'.
                _cardDetailRoute('card/:id'),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => FavouriteSwipeScreen(
                    favouriteId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.filters,
              builder: (context, state) => const FilterSettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Shell scaffold that wraps tab content with the bottom navigation bar.
class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Re-tapping the active tab resets it to its initial route.
          // When on card detail, this acts as a second back path.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favourites',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Filters',
          ),
        ],
      ),
    );
  }
}
