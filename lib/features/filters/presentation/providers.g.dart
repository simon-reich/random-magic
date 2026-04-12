// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the active Scryfall query string for card discovery.
///
/// Returns `null` when no filters are active, producing an unrestricted
/// random card query. Phase 2 replaces this stub with real filter state.

@ProviderFor(activeFilterQuery)
final activeFilterQueryProvider = ActiveFilterQueryProvider._();

/// Provides the active Scryfall query string for card discovery.
///
/// Returns `null` when no filters are active, producing an unrestricted
/// random card query. Phase 2 replaces this stub with real filter state.

final class ActiveFilterQueryProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// Provides the active Scryfall query string for card discovery.
  ///
  /// Returns `null` when no filters are active, producing an unrestricted
  /// random card query. Phase 2 replaces this stub with real filter state.
  ActiveFilterQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeFilterQueryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeFilterQueryHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return activeFilterQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$activeFilterQueryHash() => r'9d8ad27bd2248e44879c5f64efc238d5f31b7f50';
