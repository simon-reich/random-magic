import 'package:flutter/material.dart';

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
    return const MaterialApp(
      title: 'Random Magic',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text('Random Magic'),
        ),
      ),
    );
  }
}
