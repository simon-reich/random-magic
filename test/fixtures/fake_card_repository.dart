import 'dart:async';

import 'package:random_magic/features/card_discovery/domain/card_repository.dart';
import 'package:random_magic/shared/failures.dart';
import 'package:random_magic/shared/models/magic_card.dart';
import 'package:random_magic/shared/result.dart';

import 'fake_magic_card.dart';

/// A [CardRepository] test double that returns a pre-configured [Result].
///
/// Defaults to returning [Success] wrapping [fakeMagicCard()] when no result
/// is provided. Override [result] to test specific success values or failures.
class FakeCardRepository implements CardRepository {
  /// Creates a fake repository returning [result] from every fetch method.
  ///
  /// Defaults to [Success(fakeMagicCard())] when [result] is null.
  FakeCardRepository({Result<MagicCard>? result})
      : _result = result ?? Success(fakeMagicCard());

  final Result<MagicCard> _result;

  @override
  Future<Result<MagicCard>> getRandomCard({String? query}) async => _result;

  @override
  Future<Result<MagicCard>> getCardById(String id) async => _result;
}

/// A [CardRepository] that never resolves — holds [randomCardProvider] in AsyncLoading.
///
/// Used in widget tests to assert the loading state without a race condition.
class StallingFakeRepository implements CardRepository {
  @override
  Future<Result<MagicCard>> getRandomCard({String? query}) =>
      Completer<Result<MagicCard>>().future;

  @override
  Future<Result<MagicCard>> getCardById(String id) =>
      Completer<Result<MagicCard>>().future;
}

/// A [CardRepository] that immediately returns a [Failure] for every call.
///
/// Use to drive [randomCardProvider] into AsyncError with a specific [AppFailure].
class FailingFakeRepository implements CardRepository {
  /// Creates a repository that returns [Failure(failure)] from every fetch.
  const FailingFakeRepository(this.failure);

  final AppFailure failure;

  @override
  Future<Result<MagicCard>> getRandomCard({String? query}) async =>
      Failure(failure);

  @override
  Future<Result<MagicCard>> getCardById(String id) async => Failure(failure);
}
