import 'package:random_magic/features/card_discovery/data/scryfall_api_client.dart';
import 'package:random_magic/features/card_discovery/domain/card_repository.dart';
import 'package:random_magic/shared/models/magic_card.dart';
import 'package:random_magic/shared/result.dart';

/// Scryfall-backed implementation of [CardRepository].
///
/// Delegates all network calls to [ScryfallApiClient].
class CardRepositoryImpl implements CardRepository {
  const CardRepositoryImpl(this._client);

  final ScryfallApiClient _client;

  @override
  Future<Result<MagicCard>> getRandomCard({String? query}) {
    return _client.getRandomCard(query: query);
  }
}
