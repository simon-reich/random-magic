// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the live filter state for the current session.
///
/// State is kept alive across tab navigation ([keepAlive: true]).
/// Changing any field automatically propagates to [activeFilterQueryProvider],
/// which [RandomCardNotifier] watches — triggering a new card fetch (D-13, FILT-05).

@ProviderFor(FilterSettingsNotifier)
final filterSettingsProvider = FilterSettingsNotifierProvider._();

/// Manages the live filter state for the current session.
///
/// State is kept alive across tab navigation ([keepAlive: true]).
/// Changing any field automatically propagates to [activeFilterQueryProvider],
/// which [RandomCardNotifier] watches — triggering a new card fetch (D-13, FILT-05).
final class FilterSettingsNotifierProvider
    extends $NotifierProvider<FilterSettingsNotifier, FilterSettings> {
  /// Manages the live filter state for the current session.
  ///
  /// State is kept alive across tab navigation ([keepAlive: true]).
  /// Changing any field automatically propagates to [activeFilterQueryProvider],
  /// which [RandomCardNotifier] watches — triggering a new card fetch (D-13, FILT-05).
  FilterSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filterSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filterSettingsNotifierHash();

  @$internal
  @override
  FilterSettingsNotifier create() => FilterSettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FilterSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FilterSettings>(value),
    );
  }
}

String _$filterSettingsNotifierHash() =>
    r'a0ec0a76f60db9f1c385a32ffa48ec847fe28b09';

/// Manages the live filter state for the current session.
///
/// State is kept alive across tab navigation ([keepAlive: true]).
/// Changing any field automatically propagates to [activeFilterQueryProvider],
/// which [RandomCardNotifier] watches — triggering a new card fetch (D-13, FILT-05).

abstract class _$FilterSettingsNotifier extends $Notifier<FilterSettings> {
  FilterSettings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FilterSettings, FilterSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FilterSettings, FilterSettings>,
              FilterSettings,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provides the active Scryfall query string for card discovery.
///
/// Replaces the Phase 1 stub. Returns null when no filters are active (FILT-10),
/// which causes [RandomCardNotifier] to fetch without a `q` parameter.
///
/// The provider name [activeFilterQueryProvider] is preserved so that
/// [RandomCardNotifier.build()] continues to work without modification.

@ProviderFor(activeFilterQuery)
final activeFilterQueryProvider = ActiveFilterQueryProvider._();

/// Provides the active Scryfall query string for card discovery.
///
/// Replaces the Phase 1 stub. Returns null when no filters are active (FILT-10),
/// which causes [RandomCardNotifier] to fetch without a `q` parameter.
///
/// The provider name [activeFilterQueryProvider] is preserved so that
/// [RandomCardNotifier.build()] continues to work without modification.

final class ActiveFilterQueryProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// Provides the active Scryfall query string for card discovery.
  ///
  /// Replaces the Phase 1 stub. Returns null when no filters are active (FILT-10),
  /// which causes [RandomCardNotifier] to fetch without a `q` parameter.
  ///
  /// The provider name [activeFilterQueryProvider] is preserved so that
  /// [RandomCardNotifier.build()] continues to work without modification.
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

String _$activeFilterQueryHash() => r'9d76a99bee331ba16cc0149a36e1761c0dbe9e69';

/// Manages named filter presets persisted in Hive CE.
///
/// State is kept alive across tab navigation ([keepAlive: true]).
/// Initial state loads all presets from the open Hive box.

@ProviderFor(FilterPresetsNotifier)
final filterPresetsProvider = FilterPresetsNotifierProvider._();

/// Manages named filter presets persisted in Hive CE.
///
/// State is kept alive across tab navigation ([keepAlive: true]).
/// Initial state loads all presets from the open Hive box.
final class FilterPresetsNotifierProvider
    extends $NotifierProvider<FilterPresetsNotifier, List<FilterPreset>> {
  /// Manages named filter presets persisted in Hive CE.
  ///
  /// State is kept alive across tab navigation ([keepAlive: true]).
  /// Initial state loads all presets from the open Hive box.
  FilterPresetsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filterPresetsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filterPresetsNotifierHash();

  @$internal
  @override
  FilterPresetsNotifier create() => FilterPresetsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FilterPreset> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FilterPreset>>(value),
    );
  }
}

String _$filterPresetsNotifierHash() =>
    r'fb87bce839158aeea97341399f8c56ef5a220616';

/// Manages named filter presets persisted in Hive CE.
///
/// State is kept alive across tab navigation ([keepAlive: true]).
/// Initial state loads all presets from the open Hive box.

abstract class _$FilterPresetsNotifier extends $Notifier<List<FilterPreset>> {
  List<FilterPreset> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<FilterPreset>, List<FilterPreset>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<FilterPreset>, List<FilterPreset>>,
              List<FilterPreset>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
