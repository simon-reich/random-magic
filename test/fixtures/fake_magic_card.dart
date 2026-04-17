import 'package:random_magic/shared/models/magic_card.dart';

// Sentinel used by fakeMagicCard to distinguish "caller passed null" from
// "caller did not pass the argument at all". Typed as Object so the parameter
// can be declared Object? and accept both CardPrices and null.
const Object _kDefaultPrices = CardPrices(usd: '0.50', usdFoil: '1.25', eur: '0.45');

/// Returns a single-faced [MagicCard] with sensible test defaults.
///
/// All parameters are optional — override individually per test case.
/// Pass `prices: null` explicitly to get a card with no price data (all N/A).
MagicCard fakeMagicCard({
  String id = 'fake-card-001',
  String name = 'Lightning Bolt',
  String manaCost = '{R}',
  String typeLine = 'Instant',
  String oracleText = 'Lightning Bolt deals 3 damage to any target.',
  String? flavorText = "The sky's disapproval is rarely subtle.",
  String rarity = 'common',
  String setCode = 'lea',
  String setName = 'Limited Edition Alpha',
  String collectorNumber = '161',
  String releasedAt = '1993-08-05',
  CardImageUris? imageUris,
  // Sentinel pattern: passing prices: null gives a null CardPrices (no price data).
  // Not passing prices at all uses the default fake prices.
  Object? prices = _kDefaultPrices,
  Map<String, String>? legalities,
  List<String> colors = const ['R'],
  List<CardFace>? cardFaces,
}) =>
    MagicCard(
      id: id,
      name: name,
      manaCost: manaCost,
      typeLine: typeLine,
      oracleText: oracleText,
      flavorText: flavorText,
      rarity: rarity,
      setCode: setCode,
      setName: setName,
      collectorNumber: collectorNumber,
      releasedAt: releasedAt,
      imageUris: imageUris ??
          const CardImageUris(
            small: 'https://example.com/small.jpg',
            normal: 'https://example.com/normal.jpg',
            large: 'https://example.com/large.jpg',
            artCrop: 'https://example.com/art_crop.jpg',
          ),
      // Sentinel check: if caller passed null explicitly, honour it; otherwise use default.
      prices: identical(prices, _kDefaultPrices)
          ? const CardPrices(usd: '0.50', usdFoil: '1.25', eur: '0.45')
          : prices as CardPrices?,
      legalities: legalities ??
          const {
            'standard': 'not_legal',
            'modern': 'legal',
            'legacy': 'legal',
            'commander': 'legal',
            'pioneer': 'not_legal',
            'vintage': 'legal',
          },
      colors: colors,
      cardFaces: cardFaces,
    );

/// Returns a double-faced [MagicCard] representing a DFC like Delver of Secrets.
///
/// [cardFaces] has exactly 2 entries: index 0 = front face, index 1 = back face.
MagicCard fakeDfcMagicCard() => fakeMagicCard(
      id: 'fake-dfc-001',
      name: 'Delver of Secrets',
      manaCost: '{U}',
      typeLine: 'Creature — Human Wizard',
      oracleText: 'At the beginning of your upkeep, look at the top card of your library.',
      flavorText: null,
      rarity: 'common',
      setName: 'Innistrad',
      colors: const ['U'],
      cardFaces: const [
        CardFace(
          imageUris: CardImageUris(
            normal: 'https://example.com/front_normal.jpg',
            large: 'https://example.com/front_large.jpg',
          ),
          name: 'Delver of Secrets',
          typeLine: 'Creature — Human Wizard',
          oracleText:
              'At the beginning of your upkeep, look at the top card of your library.',
          manaCost: '{U}',
        ),
        CardFace(
          imageUris: CardImageUris(
            normal: 'https://example.com/back_normal.jpg',
            large: 'https://example.com/back_large.jpg',
          ),
          name: 'Insectile Aberration',
          typeLine: 'Creature — Human Insect',
          oracleText: 'Flying',
          manaCost: null,
        ),
      ],
    );
