import 'package:dio/dio.dart';
import 'package:random_magic/shared/failures.dart';
import 'package:random_magic/shared/models/magic_card.dart';
import 'package:random_magic/shared/result.dart';

/// Client for the Scryfall REST API, scoped to card discovery.
///
/// All methods return [Result] — this class never throws. Callers use
/// exhaustive pattern matching on [Success] / [Failure] to handle outcomes.
///
/// Inject [Dio] via the constructor so tests can supply a mock without
/// touching the real network.
class ScryfallApiClient {
  const ScryfallApiClient(this._dio);

  final Dio _dio;

  /// Fetches a single random card from Scryfall.
  ///
  /// [query] is an optional Scryfall syntax filter string (e.g. `"color:R type:Creature"`).
  /// When null or empty, Scryfall returns an unrestricted random card.
  ///
  /// Returns:
  /// - [Success<MagicCard>] on HTTP 200 with a parseable response.
  /// - [Failure<CardNotFoundFailure>] on HTTP 404 (no cards match [query]).
  /// - [Failure<InvalidQueryFailure>] on HTTP 422 (malformed [query] syntax).
  /// - [Failure<NetworkFailure>] on timeout or no network connection.
  Future<Result<MagicCard>> getRandomCard({String? query}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/cards/random',
        queryParameters: _buildQueryParams(query),
      );

      final card = MagicCard.fromJson(response.data!);
      return Success(card);
    } on DioException catch (e) {
      return Failure(_mapDioException(e));
    }
  }

  /// Builds the query parameter map for the `/cards/random` endpoint.
  ///
  /// Omits the `q` parameter entirely when [query] is null or blank so
  /// Scryfall returns a fully unrestricted random card.
  Map<String, dynamic>? _buildQueryParams(String? query) {
    if (query == null || query.trim().isEmpty) return null;
    return {'q': query.trim()};
  }

  /// Maps a [DioException] to a typed [AppFailure].
  ///
  /// HTTP status codes take precedence over connection-level errors.
  AppFailure _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;

    if (statusCode == 404) return const CardNotFoundFailure();
    if (statusCode == 422) return const InvalidQueryFailure();

    // Everything else (timeout, no internet, DNS failure, etc.) is a network error.
    return NetworkFailure(message: e.message);
  }
}
