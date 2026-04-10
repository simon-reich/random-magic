import 'package:random_magic/shared/models/magic_card.dart';
import 'package:random_magic/shared/result.dart';

/// Contract for fetching random Magic cards.
///
/// Abstracted so the presentation layer never depends on Dio or Scryfall
/// directly — and so tests can inject a fake implementation.
abstract interface class CardRepository {
  /// Fetches a single random card, optionally filtered by [query].
  ///
  /// [query] follows Scryfall syntax (e.g. `"color:R type:Creature"`).
  /// Passing null returns an unrestricted random card.
  Future<Result<MagicCard>> getRandomCard({String? query});
}
