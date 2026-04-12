// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks the name of the last-loaded preset for dirty-state display (D-12).
///
/// A separate provider so that [FilterSettingsScreen] can [ref.watch] it and
/// rebuild the chip label immediately when a preset is loaded — even if the
/// filter state itself hasn't changed (e.g. same preset re-selected).
/// Cleared by any mutation method on [FilterSettingsNotifier].

@ProviderFor(ActivePresetName)
final activePresetNameProvider = ActivePresetNameProvider._();

/// Tracks the name of the last-loaded preset for dirty-state display (D-12).
///
/// A separate provider so that [FilterSettingsScreen] can [ref.watch] it and
/// rebuild the chip label immediately when a preset is loaded — even if the
/// filter state itself hasn't changed (e.g. same preset re-selected).
/// Cleared by any mutation method on [FilterSettingsNotifier].
final class ActivePresetNameProvider
    extends $NotifierProvider<ActivePresetName, String?> {
  /// Tracks the name of the last-loaded preset for dirty-state display (D-12).
  ///
  /// A separate provider so that [FilterSettingsScreen] can [ref.watch] it and
  /// rebuild the chip label immediately when a preset is loaded — even if the
  /// filter state itself hasn't changed (e.g. same preset re-selected).
  /// Cleared by any mutation method on [FilterSettingsNotifier].
  ActivePresetNameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activePresetNameProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activePresetNameHash();

  @$internal
  @override
  ActivePresetName create() => ActivePresetName();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$activePresetNameHash() => r'4e8987e4a988dea56ad1c0b8856de76d1a3b57a1';

/// Tracks the name of the last-loaded preset for dirty-state display (D-12).
///
/// A separate provider so that [FilterSettingsScreen] can [ref.watch] it and
/// rebuild the chip label immediately when a preset is loaded — even if the
/// filter state itself hasn't changed (e.g. same preset re-selected).
/// Cleared by any mutation method on [FilterSettingsNotifier].

abstract class _$ActivePresetName extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Incremented whenever a preset is applied, so [RandomCardNotifier] re-fetches
/// even when the filter query string hasn't changed (e.g. same preset tapped twice).

@ProviderFor(FilterRefreshSignal)
final filterRefreshSignalProvider = FilterRefreshSignalProvider._();

/// Incremented whenever a preset is applied, so [RandomCardNotifier] re-fetches
/// even when the filter query string hasn't changed (e.g. same preset tapped twice).
final class FilterRefreshSignalProvider
    extends $NotifierProvider<FilterRefreshSignal, int> {
  /// Incremented whenever a preset is applied, so [RandomCardNotifier] re-fetches
  /// even when the filter query string hasn't changed (e.g. same preset tapped twice).
  FilterRefreshSignalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filterRefreshSignalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filterRefreshSignalHash();

  @$internal
  @override
  FilterRefreshSignal create() => FilterRefreshSignal();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$filterRefreshSignalHash() =>
    r'efa6e13119cd2e4c87f4515effc56a73f05f9f17';

/// Incremented whenever a preset is applied, so [RandomCardNotifier] re-fetches
/// even when the filter query string hasn't changed (e.g. same preset tapped twice).

abstract class _$FilterRefreshSignal extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

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
    r'80608cdbcb05b0de5ec237a3e01d8a17c28838a2';

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
