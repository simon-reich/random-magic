import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:random_magic/features/card_detail/presentation/card_detail_screen.dart';
import 'package:random_magic/features/card_discovery/presentation/card_swipe_screen.dart';
import 'package:random_magic/features/favourites/presentation/favourite_swipe_screen.dart';
import 'package:random_magic/features/favourites/presentation/favourites_screen.dart';
import 'package:random_magic/features/filters/presentation/filter_settings_screen.dart';

/// Named route constants — use these instead of raw path strings.
abstract final class AppRoutes {
  static const discovery = '/';
  static const cardDetail = '/card/:id';
  static const filters = '/filters';
  static const favourites = '/favourites';
  static const favouriteSwipe = '/favourites/:id';
}

/// The [GoRouter] instance for the app.
///
/// Uses a [StatefulShellRoute] so each bottom-nav tab maintains its own
/// navigation stack and scroll position across tab switches.
final appRouter = GoRouter(
  initialLocation: AppRoutes.discovery,
  routes: [
    // Full-screen routes that sit above the shell (no bottom nav bar).
    GoRoute(
      path: AppRoutes.cardDetail,
      builder: (context, state) => CardDetailScreen(
        cardId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: AppRoutes.favouriteSwipe,
      builder: (context, state) => FavouriteSwipeScreen(
        favouriteId: state.pathParameters['id']!,
      ),
    ),
    // Shell that hosts the three main tabs with a bottom navigation bar.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _ShellScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.discovery,
              builder: (context, state) => const CardSwipeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.favourites,
              builder: (context, state) => const FavouritesScreen(),
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
          // Return to the initial route of a branch when re-tapping its tab.
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
