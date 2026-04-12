import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Provides the active Scryfall query string for card discovery.
///
/// Returns `null` when no filters are active, producing an unrestricted
/// random card query. Phase 2 replaces this stub with real filter state.
@Riverpod(keepAlive: true)
String? activeFilterQuery(Ref ref) => null;
