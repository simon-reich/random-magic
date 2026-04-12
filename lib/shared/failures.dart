/// Base sealed class for all typed application failures.
///
/// Consumers use exhaustive pattern matching so the compiler enforces
/// that every failure case is handled:
/// ```dart
/// switch (failure) {
///   case CardNotFoundFailure() => showEmptyState(),
///   case InvalidQueryFailure() => showFilterError(),
///   case NetworkFailure()      => showRetryButton(),
/// }
/// ```
sealed class AppFailure {
  const AppFailure();
}

/// Scryfall returned HTTP 404 — no cards match the current query.
///
/// Typically caused by an overly restrictive filter combination.
/// UI should show a "No cards found" empty state.
final class CardNotFoundFailure extends AppFailure {
  const CardNotFoundFailure();
}

/// Scryfall returned HTTP 422 — the query string is syntactically invalid.
///
/// Should not occur under normal usage; indicates a bug in [ScryfallQueryBuilder].
/// UI should show an "Invalid filter settings" error with a prompt to reset filters.
final class InvalidQueryFailure extends AppFailure {
  const InvalidQueryFailure();
}

/// A network-level error occurred before a response was received.
///
/// Covers connection timeouts, no internet, and DNS failures.
/// UI should show a "Could not reach Scryfall" error with a retry button.
final class NetworkFailure extends AppFailure {
  const NetworkFailure({this.message});

  /// Optional underlying error description for debugging.
  final String? message;
}

/// Scryfall returned HTTP 429 — the app has exceeded the rate limit (10 req/s).
///
/// UI should show a "Too many requests" message and suggest waiting before retrying.
final class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure();
}

/// A preset with the same name already exists (FILT-09).
///
/// UI should display an inline validation error below the preset name field.
final class DuplicatePresetNameFailure extends AppFailure {
  const DuplicatePresetNameFailure();
}
