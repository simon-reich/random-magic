import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_magic/features/favourites/domain/favourite_card.dart';
import 'package:random_magic/features/favourites/presentation/providers.dart';
import 'package:random_magic/features/filters/domain/filter_preset.dart';
import 'package:random_magic/features/filters/domain/filter_settings.dart';
import 'package:random_magic/features/filters/presentation/filter_settings_screen.dart';
import 'package:random_magic/features/filters/presentation/providers.dart';

// ──────────────────────────────────────────────────────────────────────────────
// SVG HTTP mock
//
// SvgPicture.network loads mana symbols from Scryfall via dart:io HttpClient.
// The flutter_test binding intercepts all HTTP and returns 400, which causes
// vector_graphics to propagate an "Invalid SVG data" error as an uncaught zone
// error *after* the test future resolves — impossible to suppress from outside.
// The fix: replace the global HttpOverrides with one that returns a valid
// minimal SVG so the parser never fails and no zone error is produced.
// ──────────────────────────────────────────────────────────────────────────────

class _SvgHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeSvgClient();
}

class _FakeSvgClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeSvgRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeSvgRequest();
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeSvgRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _FakeSvgResponse();
  @override
  HttpHeaders get headers => _FakeHttpHeaders();
  @override
  Future<void> addStream(Stream<List<int>> stream) async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeSvgResponse extends Stream<List<int>> implements HttpClientResponse {
  static final _svgBytes =
      utf8.encode(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"/>');

  @override
  int get statusCode => HttpStatus.ok;
  @override
  int get contentLength => _svgBytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  HttpHeaders get headers => _FakeHttpHeaders();
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => false;
  @override
  String get reasonPhrase => 'OK';
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  Future<HttpClientResponse> redirect(
          [String? method, Uri? url, bool? followLoops]) async =>
      this;
  @override
  X509Certificate? get certificate => null;
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream<List<int>>.fromIterable([_svgBytes]).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  List<String>? operator [](String name) => null;
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

// ──────────────────────────────────────────────────────────────────────────────
// Provider stubs
// ──────────────────────────────────────────────────────────────────────────────

/// Stub for [FavouritesNotifier] — avoids requiring Hive.box('favourites').
class _StubFavouritesNotifier extends FavouritesNotifier {
  @override
  List<FavouriteCard> build() => const [];

  @override
  bool isFavourite(String id) => false;
}

/// Stub for [FilterPresetsNotifier] — avoids requiring Hive.box('filter_presets').
class _StubPresetsNotifier extends FilterPresetsNotifier {
  @override
  List<FilterPreset> build() => const [];
}

/// Stub that returns a single preset — for testing the preset chip row.
class _OnePresetNotifier extends FilterPresetsNotifier {
  @override
  List<FilterPreset> build() => [
        FilterPreset(name: 'Red Creatures', settings: const FilterSettings()),
      ];
}

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────

/// Pumps [FilterSettingsScreen] with no-Hive stubs.
///
/// Uses [pump()] rather than [pumpAndSettle()] to avoid infinite animation
/// loops that can arise if SVG loading triggers repeated frame requests.
Future<void> pumpFilterScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        favouritesProvider.overrideWith(_StubFavouritesNotifier.new),
        filterPresetsProvider.overrideWith(_StubPresetsNotifier.new),
      ],
      child: const MaterialApp(home: FilterSettingsScreen()),
    ),
  );
  await tester.pump();
}

// ──────────────────────────────────────────────────────────────────────────────
// Tests
// ──────────────────────────────────────────────────────────────────────────────

void main() {
  late HttpOverrides? savedHttpOverrides;

  setUpAll(() {
    // Replace the default 400-returning test HTTP client with one that returns
    // a valid minimal SVG, preventing vector_graphics parse errors entirely.
    savedHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = _SvgHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = savedHttpOverrides;
  });

  group('FilterSettingsScreen — colour toggles (FILT-01)', () {
    testWidgets('finds W/U/B/R/G/C/M colour toggle buttons on screen',
        (tester) async {
      await pumpFilterScreen(tester);
      // Each MtgColor is wrapped in an InkWell by _ManaToggleButton — verify 7 present.
      final inkWells = find.descendant(
        of: find.byType(FilterSettingsScreen),
        matching: find.byType(InkWell),
      );
      expect(inkWells.evaluate().length, greaterThanOrEqualTo(7));
    });
  });

  group('FilterSettingsScreen — type chips (FILT-02)', () {
    testWidgets(
        'finds Creature/Instant/Sorcery/Enchantment/Artifact/Land/Planeswalker/Battle chips',
        (tester) async {
      await pumpFilterScreen(tester);
      for (final type in [
        'Creature',
        'Instant',
        'Sorcery',
        'Enchantment',
        'Artifact',
        'Land',
        'Planeswalker',
        'Battle',
      ]) {
        expect(
          find.text(type),
          findsWidgets,
          reason: 'Type chip "$type" not found on FilterSettingsScreen',
        );
      }
    });
  });

  group('FilterSettingsScreen — rarity chips (FILT-03)', () {
    testWidgets('finds Common/Uncommon/Rare/Mythic rarity chips', (tester) async {
      await pumpFilterScreen(tester);
      for (final rarity in ['Common', 'Uncommon', 'Rare', 'Mythic']) {
        expect(
          find.text(rarity),
          findsWidgets,
          reason: 'Rarity chip "$rarity" not found on FilterSettingsScreen',
        );
      }
    });
  });

  group('FilterSettingsScreen — date pickers (FILT-04)', () {
    testWidgets('finds Released After and Released Before date input fields',
        (tester) async {
      await pumpFilterScreen(tester);
      expect(find.text('Released After'), findsOneWidget);
      expect(find.text('Released Before'), findsOneWidget);
    });
  });

  group('FilterSettingsScreen — preset row (FILT-07)', () {
    testWidgets('finds preset chips at top of screen when presets exist',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favouritesProvider.overrideWith(_StubFavouritesNotifier.new),
            filterPresetsProvider.overrideWith(_OnePresetNotifier.new),
          ],
          child: const MaterialApp(home: FilterSettingsScreen()),
        ),
      );
      await tester.pump();
      expect(find.text('Red Creatures'), findsOneWidget);
    });
  });
}
