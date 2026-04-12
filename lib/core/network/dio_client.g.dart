// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider that exposes the configured [Dio] singleton.
///
/// Kept alive for the lifetime of the app — creating a new [Dio] per request
/// would discard connection pooling and interceptor state.

@ProviderFor(dio)
final dioProvider = DioProvider._();

/// Riverpod provider that exposes the configured [Dio] singleton.
///
/// Kept alive for the lifetime of the app — creating a new [Dio] per request
/// would discard connection pooling and interceptor state.

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// Riverpod provider that exposes the configured [Dio] singleton.
  ///
  /// Kept alive for the lifetime of the app — creating a new [Dio] per request
  /// would discard connection pooling and interceptor state.
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'fb0ed7093af583a806def75cf1d3a6465fc26a2e';
