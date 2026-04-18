import 'package:flutter_test/flutter_test.dart';
import 'package:random_magic/shared/models/magic_card.dart';

/// Unit tests for [MagicCard.fromJson] — covers the full edge-case matrix (TEST-02).
///
/// Each group modifies exactly one aspect of the minimal base JSON, keeping
/// test isolation clean.
void main() {
  // Minimal valid Scryfall card JSON. All required fields present.
  // Tests override specific keys to exercise each parsing branch.
  Map<String, dynamic> baseJson({
    String id = 'test-id',
    String name = 'Lightning Bolt',
    Object? manaCost = _kDefaultMana, // use Object? to allow omission via _kOmit
    Object? typeLine = _kDefaultTypeLine, // use Object? to allow omission via _kOmit
    Object? oracleText = _kDefaultOracleText,
    Object? flavorText = _kDefaultFlavorText,
    String rarity = 'common',
    String set = 'lea',
    String setName = 'Limited Edition Alpha',
    String collectorNumber = '161',
    String releasedAt = '1993-08-05',
    Map<String, dynamic>? imageUris,
    Object? prices = _kDefaultPrices,
    Object? legalities = _kDefaultLegalities,
    Object? colors = _kDefaultColors,
    List<dynamic>? cardFaces,
  }) {
    final json = <String, dynamic>{
      'id': id,
      'name': name,
      'rarity': rarity,
      'set': set,
      'set_name': setName,
      'collector_number': collectorNumber,
      'released_at': releasedAt,
      'image_uris': imageUris ??
          {
            'normal': 'https://example.com/normal.jpg',
            'large': 'https://example.com/large.jpg',
            'art_crop': 'https://example.com/art.jpg',
          },
    };
    // Only add nullable fields when not using the sentinel _kOmit
    if (!identical(manaCost, _kOmit)) {
      json['mana_cost'] =
          identical(manaCost, _kDefaultMana) ? '{R}' : manaCost;
    }
    if (!identical(typeLine, _kOmit)) {
      json['type_line'] =
          identical(typeLine, _kDefaultTypeLine) ? 'Instant' : typeLine;
    }
    if (!identical(oracleText, _kOmit)) {
      json['oracle_text'] = identical(oracleText, _kDefaultOracleText)
          ? 'Deals 3 damage.'
          : oracleText;
    }
    if (!identical(flavorText, _kOmit)) {
      json['flavor_text'] = identical(flavorText, _kDefaultFlavorText)
          ? 'The sky disapproves.'
          : flavorText;
    }
    if (!identical(prices, _kOmit)) {
      json['prices'] = identical(prices, _kDefaultPrices)
          ? {'usd': '0.50', 'usd_foil': '1.25', 'eur': '0.45', 'eur_foil': null}
          : prices;
    }
    if (!identical(legalities, _kOmit)) {
      json['legalities'] = identical(legalities, _kDefaultLegalities)
          ? {'modern': 'legal', 'legacy': 'legal'}
          : legalities;
    }
    if (!identical(colors, _kOmit)) {
      json['colors'] =
          identical(colors, _kDefaultColors) ? ['R'] : colors;
    }
    if (cardFaces != null) json['card_faces'] = cardFaces;
    return json;
  }

  group('MagicCard.fromJson — normal card (all fields present)', () {
    test('parses id, name, rarity, setCode, setName, collectorNumber, releasedAt', () {
      final card = MagicCard.fromJson(baseJson());
      expect(card.id, 'test-id');
      expect(card.name, 'Lightning Bolt');
      expect(card.rarity, 'common');
      expect(card.setCode, 'lea');
      expect(card.setName, 'Limited Edition Alpha');
      expect(card.collectorNumber, '161');
      expect(card.releasedAt, '1993-08-05');
    });

    test('parses manaCost, typeLine, oracleText, flavorText', () {
      final card = MagicCard.fromJson(baseJson());
      expect(card.manaCost, '{R}');
      expect(card.typeLine, 'Instant');
      expect(card.oracleText, 'Deals 3 damage.');
      expect(card.flavorText, 'The sky disapproves.');
    });

    test('parses imageUris.normal from top-level image_uris', () {
      final card = MagicCard.fromJson(baseJson());
      expect(card.imageUris.normal, 'https://example.com/normal.jpg');
    });

    test('parses prices.usd and prices.eur from prices object', () {
      final card = MagicCard.fromJson(baseJson());
      expect(card.prices, isNotNull);
      expect(card.prices!.usd, '0.50');
      expect(card.prices!.eur, '0.45');
    });

    test('parses legalities map defensively (string keys and values)', () {
      final card = MagicCard.fromJson(baseJson());
      expect(card.legalities['modern'], 'legal');
    });

    test('parses colors list', () {
      final card = MagicCard.fromJson(baseJson());
      expect(card.colors, ['R']);
    });

    test('cardFaces is null for single-faced card', () {
      final card = MagicCard.fromJson(baseJson());
      expect(card.cardFaces, isNull);
    });
  });

  group('MagicCard.fromJson — double-faced card (DFC)', () {
    // DFC cards omit the top-level image_uris key entirely — not null, absent.
    // Build the JSON manually so we can control which keys are present.
    Map<String, dynamic> dfcJson() {
      final json = baseJson(
        name: 'Delver of Secrets // Insectile Aberration',
        cardFaces: [
          {
            'name': 'Delver of Secrets',
            'type_line': 'Creature — Human Wizard',
            'oracle_text': 'At the beginning of your upkeep...',
            'mana_cost': '{U}',
            'image_uris': {'normal': 'https://example.com/front.jpg'},
          },
          {
            'name': 'Insectile Aberration',
            'type_line': 'Creature — Human Insect',
            'oracle_text': 'Flying',
            'mana_cost': null,
            'image_uris': {'normal': 'https://example.com/back.jpg'},
          },
        ],
      );
      // Remove top-level image_uris so MagicCard.fromJson falls back to card_faces[0].
      json.remove('image_uris');
      return json;
    }

    test('imageUris.normal comes from card_faces[0].image_uris', () {
      final card = MagicCard.fromJson(dfcJson());
      expect(card.imageUris.normal, 'https://example.com/front.jpg');
    });

    test('cardFaces is non-null with exactly 2 entries', () {
      final card = MagicCard.fromJson(dfcJson());
      expect(card.cardFaces, isNotNull);
      expect(card.cardFaces!.length, 2);
    });

    test('cardFaces[0].name is front face name', () {
      final card = MagicCard.fromJson(dfcJson());
      expect(card.cardFaces![0].name, 'Delver of Secrets');
    });

    test('cardFaces[1].name is back face name', () {
      final card = MagicCard.fromJson(dfcJson());
      expect(card.cardFaces![1].name, 'Insectile Aberration');
    });

    test('cardFaces[1].manaCost is null (back face has no casting cost)', () {
      final card = MagicCard.fromJson(dfcJson());
      expect(card.cardFaces![1].manaCost, isNull);
    });
  });

  group('MagicCard.fromJson — null prices', () {
    test('prices is null when json prices key is null', () {
      final card = MagicCard.fromJson(baseJson(prices: null));
      expect(card.prices, isNull);
    });

    test('prices fields are null when all price sub-fields are null', () {
      final card = MagicCard.fromJson(baseJson(
        prices: {'usd': null, 'usd_foil': null, 'eur': null, 'eur_foil': null},
      ));
      expect(card.prices, isNotNull);
      expect(card.prices!.usd, isNull);
      expect(card.prices!.usdFoil, isNull);
      expect(card.prices!.eur, isNull);
      expect(card.prices!.eurFoil, isNull);
    });
  });

  group('MagicCard.fromJson — nullable text fields', () {
    test('oracleText is null when oracle_text key is absent', () {
      final card = MagicCard.fromJson(baseJson(oracleText: _kOmit));
      expect(card.oracleText, isNull);
    });

    test('flavorText is null when flavor_text key is absent', () {
      final card = MagicCard.fromJson(baseJson(flavorText: _kOmit));
      expect(card.flavorText, isNull);
    });

    test('manaCost is null when mana_cost key is absent (land card)', () {
      final card = MagicCard.fromJson(baseJson(manaCost: _kOmit));
      expect(card.manaCost, isNull);
    });
  });

  group('MagicCard.fromJson — defensive parsing', () {
    test('legalities is empty map when legalities key is absent', () {
      final card = MagicCard.fromJson(baseJson(legalities: _kOmit));
      expect(card.legalities, isEmpty);
    });

    test('colors is empty list when colors key is absent (colourless card)', () {
      final card = MagicCard.fromJson(baseJson(colors: _kOmit));
      expect(card.colors, isEmpty);
    });

    test('typeLine is empty string when type_line key is absent (token)', () {
      final card = MagicCard.fromJson(baseJson(typeLine: _kOmit));
      expect(card.typeLine, '');
    });
  });
}

// Sentinel objects to distinguish "caller passed null" from "caller omitted the key".
const Object _kOmit = _Omit();
const Object _kDefaultPrices = _DefaultPrices();
const Object _kDefaultLegalities = _DefaultLegalities();
const Object _kDefaultColors = _DefaultColors();
const Object _kDefaultMana = _DefaultMana();
const Object _kDefaultTypeLine = _DefaultTypeLine();
const Object _kDefaultOracleText = _DefaultOracleText();
const Object _kDefaultFlavorText = _DefaultFlavorText();

class _Omit {
  const _Omit();
}

class _DefaultPrices {
  const _DefaultPrices();
}

class _DefaultLegalities {
  const _DefaultLegalities();
}

class _DefaultColors {
  const _DefaultColors();
}

class _DefaultMana {
  const _DefaultMana();
}

class _DefaultTypeLine {
  const _DefaultTypeLine();
}

class _DefaultOracleText {
  const _DefaultOracleText();
}

class _DefaultFlavorText {
  const _DefaultFlavorText();
}
