import 'package:flutter/material.dart';
import 'package:random_magic/core/theme/app_theme.dart';

void main() {
  runApp(const RandomMagicApp());
}

/// Root widget of the Random Magic application.
///
/// Initialises providers and the router once those are wired up in later
/// tickets. For now this acts as a verified-clean entry point.
class RandomMagicApp extends StatelessWidget {
  const RandomMagicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Magic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const Scaffold(
        body: Center(
          child: Text('Random Magic'),
        ),
      ),
    );
  }
}
