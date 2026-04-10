import 'package:flutter/material.dart';
import 'package:random_magic/core/router/app_router.dart';
import 'package:random_magic/core/theme/app_theme.dart';

void main() {
  runApp(const RandomMagicApp());
}

/// Root widget of the Random Magic application.
///
/// Wires up the [appRouter] and [AppTheme.dark]. Riverpod [ProviderScope]
/// will wrap this once providers are introduced in a later ticket.
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
