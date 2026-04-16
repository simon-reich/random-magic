import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:random_magic/core/router/app_router.dart';
import 'package:random_magic/core/theme/app_theme.dart';
import 'package:random_magic/features/favourites/domain/favourite_card.dart';
import 'package:random_magic/features/filters/domain/filter_preset.dart';

/// Entry point for the Random Magic application.
///
/// Initialises Hive CE before launching the widget tree so that the
/// `filter_presets` and `favourites` boxes are open when their respective
/// notifiers first call [Hive.box].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(FilterPresetAdapter());
  await Hive.openBox<FilterPreset>('filter_presets');
  Hive.registerAdapter(FavouriteCardAdapter());
  await Hive.openBox<FavouriteCard>('favourites');
  runApp(const ProviderScope(child: RandomMagicApp()));
}

/// Root widget of the Random Magic application.
///
/// Wrapped in [ProviderScope] in [main] to initialise the Riverpod container.
/// Wires up [appRouter] and [AppTheme.dark].
class RandomMagicApp extends StatelessWidget {
  const RandomMagicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Random Magic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
