/// API-level constants shared across the network layer.
///
/// All Scryfall connection settings live here — no magic numbers in client code.
abstract final class ApiConstants {
  /// Scryfall REST API base URL.
  static const String baseUrl = 'https://api.scryfall.com';

  /// User-Agent sent with every request, as requested by Scryfall's API etiquette.
  static const String userAgent = 'RandomMagicApp/1.0';

  /// Time allowed to establish a TCP connection before giving up.
  static const Duration connectTimeout = Duration(seconds: 10);

  /// Time allowed to receive the full response body before giving up.
  static const Duration receiveTimeout = Duration(seconds: 10);
}
