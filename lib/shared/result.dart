import 'package:random_magic/shared/failures.dart';

/// A discriminated union representing either a successful value or a failure.
///
/// Use pattern matching to handle both cases:
/// ```dart
/// switch (result) {
///   case Success(:final value) => print(value),
///   case Failure(:final error) => print(error),
/// }
/// ```
sealed class Result<T> {
  const Result();
}

/// Represents a successful outcome carrying [value].
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

/// Represents a failed outcome carrying a typed [AppFailure].
final class Failure<T> extends Result<T> {
  const Failure(this.error);

  final AppFailure error;
}
