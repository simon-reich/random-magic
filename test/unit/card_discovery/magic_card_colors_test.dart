import 'package:flutter_test/flutter_test.dart';
import 'package:random_magic/shared/models/magic_card.dart';

/// Unit tests for [MagicCard.colors] field parsing from Scryfall JSON.
///
/// Validates that the colors field is correctly extracted from the
/// Scryfall `json['colors']` array, with safe handling of absent or null values.
/// Required for colour filtering in the Favourites feature (FAV-07, D-12).
void main() {
  /// Minimal valid Scryfall card JSON with all required fields populated.
  Map<String, dynamic> baseJson({List<dynamic>? colors, bool omitColors = false}) {
    final json = <String, dynamic>{
      'id': 'test-id',
      'name': 'Test Card',
      'mana_cost': '{R}',
      'type_line': 'Instant',
      'rarity': 'common',
      'set': 'tst',
      'set_name': 'Test Set',
      'collector_number': '1',
      'released_at': '2024-01-01',
      'image_uris': {
        'small': null,
        'normal': 'https://example.com/normal.jpg',
        'large': null,
        'png': null,
        'art_crop': 'https://example.com/art.jpg',
        'border_crop': null,
      },
      'prices': null,
      'legalities': <String, dynamic>{},
    };
    if (!omitColors) {
      json['colors'] = colors;
    }
    return json;
  }

  group('MagicCard.colors parsing', () {
    test('parses single-color card correctly', () {
      final card = MagicCard.fromJson(baseJson(colors: ['R']));
      expect(card.colors, ['R']);
    });

    test('parses multi-color card correctly', () {
      final card = MagicCard.fromJson(baseJson(colors: ['W', 'U']));
      expect(card.colors, ['W', 'U']);
    });

    test('parses empty list for colourless card (colors: [])', () {
      final card = MagicCard.fromJson(baseJson(colors: []));
      expect(card.colors, isEmpty);
    });

    test('returns empty list when colors key is null', () {
      final card = MagicCard.fromJson(baseJson(colors: null));
      expect(card.colors, isEmpty);
    });

    test('returns empty list when colors key is absent from JSON', () {
      final card = MagicCard.fromJson(baseJson(omitColors: true));
      expect(card.colors, isEmpty);
    });

    test('constructed MagicCard stores colors field', () {
      final card = MagicCard.fromJson(baseJson(colors: ['R', 'G']));
      expect(card.colors, ['R', 'G']);
    });
  });
}
