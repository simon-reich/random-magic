/// A single face of a double-faced Magic: The Gathering card.
///
/// Only populated when [MagicCard.cardFaces] is non-null (i.e. the card is a
/// double-faced card). Single-faced cards have [MagicCard.cardFaces] == null.
class CardFace {
  const CardFace({
    required this.imageUris,
    required this.name,
    required this.typeLine,
    this.oracleText,
    this.manaCost,
    this.artist,
  });

  /// Image URLs for this face. May contain only a subset of sizes.
  final CardImageUris imageUris;

  /// Name of this face (e.g. 'Delver of Secrets').
  final String name;

  /// Full type line for this face.
  final String typeLine;

  /// Rules text for this face. Null on faces with no text box.
  final String? oracleText;

  /// Mana cost for this face. Null on back faces that have no casting cost.
  final String? manaCost;

  /// Artist credit for this face. Null when absent (some tokens/emblems).
  final String? artist;

  /// Deserialises a single entry from Scryfall's `card_faces` array.
  factory CardFace.fromJson(Map<String, dynamic> json) {
    return CardFace(
      imageUris: CardImageUris.fromJson(
        (json['image_uris'] as Map<String, dynamic>?) ?? {},
      ),
      name: json['name'] as String,
      // token cards may omit type_line — fall back to empty string (CR-01)
      typeLine: (json['type_line'] as String?) ?? '',
      oracleText: json['oracle_text'] as String?,
      manaCost: json['mana_cost'] as String?,
      artist: json['artist'] as String?,
    );
  }
}

/// Represents a single Magic: The Gathering card as returned by the Scryfall API.
///
/// All fields are immutable. Use [MagicCard.fromJson] to deserialise a
/// Scryfall `/cards/random` or `/cards/{id}` response.
class MagicCard {
  const MagicCard({
    required this.id,
    required this.name,
    required this.typeLine,
    required this.rarity,
    required this.setCode,
    required this.setName,
    required this.collectorNumber,
    required this.releasedAt,
    required this.imageUris,
    required this.legalities,
    required this.colors,
    this.manaCost,
    this.oracleText,
    // Intentionally nullable — hidden in UI when absent (not shown as blank).
    this.flavorText,
    this.prices,
    this.cardFaces,
    this.artist,
  });

  final String id;
  final String name;

  /// Formatted mana cost string, e.g. `{2}{R}{R}`. Null for land cards.
  final String? manaCost;

  final String typeLine;

  /// Rules text. May be null on tokens or cards with no text box.
  final String? oracleText;

  /// Flavour text. Null when absent — consumers must hide the field, not show blank.
  final String? flavorText;

  final String rarity;
  final String setCode;
  final String setName;
  final String collectorNumber;

  /// ISO 8601 date string, e.g. `"2009-07-17"`.
  final String releasedAt;

  final CardImageUris imageUris;

  /// Current market prices. All sub-fields are nullable — UI shows "N/A" when null.
  final CardPrices? prices;

  /// Artist credit. Null when absent (some tokens/emblems).
  final String? artist;

  /// Per-face data for double-faced cards. Null for single-faced cards.
  ///
  /// When non-null, contains exactly 2 entries: index 0 = front face,
  /// index 1 = back face. Use [CardFace.imageUris], [CardFace.name],
  /// [CardFace.typeLine], and [CardFace.oracleText] for face-specific display.
  final List<CardFace>? cardFaces;

  /// Map of format name → legality string (e.g. `"modern"` → `"legal"`).
  final Map<String, String> legalities;

  /// Scryfall color identity for this card (e.g. `['R', 'G']` for Gruul).
  ///
  /// Empty list for colourless cards. Used by [FavouriteCard] for client-side
  /// colour filtering in the Favourites feature (FAV-07).
  final List<String> colors;

  /// Deserialises a Scryfall card JSON object into a [MagicCard].
  ///
  /// Handles the two main edge cases:
  /// - **Double-faced cards**: `image_uris` is absent at the top level;
  ///   falls back to `card_faces[0].image_uris`.
  /// - **Null prices**: all price fields are individually nullable in Scryfall
  ///   responses; [CardPrices] preserves that nullability.
  factory MagicCard.fromJson(Map<String, dynamic> json) {
    // Double-faced cards omit top-level image_uris and put them in card_faces.
    final rawImageUris =
        (json['image_uris'] as Map<String, dynamic>?) ??
        _firstFaceImageUris(json);

    final rawPrices = json['prices'] as Map<String, dynamic>?;

    final rawLegalities = json['legalities'] as Map<String, dynamic>? ?? {};

    // Parse double-faced card faces. Requires >= 2 entries to be meaningful.
    // Does NOT conflict with _firstFaceImageUris — both read json['card_faces']
    // as a read-only key lookup; the JSON map is immutable.
    final rawFaces = json['card_faces'] as List<dynamic>?;
    final cardFaces = rawFaces != null && rawFaces.length >= 2
        ? rawFaces
            .cast<Map<String, dynamic>>()
            .map(CardFace.fromJson)
            .toList()
        : null;

    return MagicCard(
      id: json['id'] as String,
      name: json['name'] as String,
      manaCost: json['mana_cost'] as String?,
      // token cards may omit type_line — fall back to empty string (CR-01)
      typeLine: (json['type_line'] as String?) ?? '',
      oracleText: json['oracle_text'] as String?,
      flavorText: json['flavor_text'] as String?,
      rarity: json['rarity'] as String,
      setCode: json['set'] as String,
      setName: json['set_name'] as String,
      collectorNumber: json['collector_number'] as String,
      releasedAt: json['released_at'] as String,
      imageUris: CardImageUris.fromJson(rawImageUris),
      prices: rawPrices != null ? CardPrices.fromJson(rawPrices) : null,
      // Defensive conversion — avoids Map<dynamic, dynamic> cast errors from Scryfall JSON.
      legalities: rawLegalities.map((k, v) => MapEntry(k.toString(), v.toString())),
      // Scryfall omits 'colors' for colourless cards — default to empty list.
      colors: (json['colors'] as List<dynamic>?)?.cast<String>() ?? const [],
      cardFaces: cardFaces,
      artist: json['artist'] as String?,
    );
  }

  /// Extracts `image_uris` from the first face of a double-faced card.
  ///
  /// Returns an empty map if neither source exists, so [CardImageUris.fromJson]
  /// can still produce a valid (empty-URL) object rather than throwing.
  static Map<String, dynamic> _firstFaceImageUris(Map<String, dynamic> json) {
    final faces = json['card_faces'] as List<dynamic>?;
    if (faces == null || faces.isEmpty) return {};
    final firstFace = faces[0] as Map<String, dynamic>;
    return (firstFace['image_uris'] as Map<String, dynamic>?) ?? {};
  }
}

/// Image URLs for a card at various resolutions.
///
/// Scryfall serves images in multiple sizes; [normal] is the standard choice
/// for the swipe screen, [artCrop] for thumbnails.
class CardImageUris {
  const CardImageUris({
    this.small,
    this.normal,
    this.large,
    this.png,
    this.artCrop,
    this.borderCrop,
  });

  final String? small;

  /// ~488×680 px JPEG — primary image for the swipe card display.
  final String? normal;

  final String? large;

  /// Lossless PNG — use when image quality matters (e.g. full-screen detail).
  final String? png;

  /// Art only, no card frame — useful for thumbnails and background fills.
  final String? artCrop;

  final String? borderCrop;

  /// Deserialises a Scryfall `image_uris` object.
  factory CardImageUris.fromJson(Map<String, dynamic> json) {
    return CardImageUris(
      small: json['small'] as String?,
      normal: json['normal'] as String?,
      large: json['large'] as String?,
      png: json['png'] as String?,
      artCrop: json['art_crop'] as String?,
      borderCrop: json['border_crop'] as String?,
    );
  }
}

/// Current market prices for a card.
///
/// All fields are nullable — Scryfall omits prices for cards with no market
/// data. UI must render `"N/A"` rather than crashing when a field is null.
class CardPrices {
  const CardPrices({
    this.usd,
    this.usdFoil,
    this.eur,
    this.eurFoil,
  });

  /// Non-foil USD price string, e.g. `"0.50"`. Null if unavailable.
  final String? usd;

  /// Foil USD price string. Null if unavailable.
  final String? usdFoil;

  /// Non-foil EUR price string. Null if unavailable.
  final String? eur;

  /// Foil EUR price string. Null if unavailable.
  final String? eurFoil;

  /// Deserialises a Scryfall `prices` object.
  factory CardPrices.fromJson(Map<String, dynamic> json) {
    return CardPrices(
      usd: json['usd'] as String?,
      usdFoil: json['usd_foil'] as String?,
      eur: json['eur'] as String?,
      eurFoil: json['eur_foil'] as String?,
    );
  }
}
