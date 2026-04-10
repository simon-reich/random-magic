import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_magic/core/router/app_router.dart';
import 'package:random_magic/core/theme/app_theme.dart';

void main() {
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
