import 'package:random_magic/features/favourites/domain/favourite_card.dart';

/// Returns a [FavouriteCard] with sensible test defaults.
/// All parameters are optional — override individually per test case.
FavouriteCard fakeFavouriteCard({
  String id = 'abc-123',
  String name = 'Lightning Bolt',
  String typeLine = 'Instant',
  String rarity = 'common',
  String setCode = 'lea',
  String? artCropUrl = 'https://example.com/art_crop.jpg',
  String? normalImageUrl = 'https://example.com/normal.jpg',
  String? manaCost = '{R}',
  DateTime? savedAt,
  List<String> colors = const ['R'],
}) =>
    FavouriteCard(
      id: id,
      name: name,
      typeLine: typeLine,
      rarity: rarity,
      setCode: setCode,
      artCropUrl: artCropUrl,
      normalImageUrl: normalImageUrl,
      manaCost: manaCost,
      savedAt: savedAt ?? DateTime(2024, 1, 15, 12, 0),
      colors: colors,
    );
