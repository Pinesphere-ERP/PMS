// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'housekeeping_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HousekeepingNotifier)
final housekeepingProvider = HousekeepingNotifierProvider._();

final class HousekeepingNotifierProvider
    extends $NotifierProvider<HousekeepingNotifier, HousekeepingState> {
  HousekeepingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'housekeepingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$housekeepingNotifierHash();

  @$internal
  @override
  HousekeepingNotifier create() => HousekeepingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HousekeepingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HousekeepingState>(value),
    );
  }
}

String _$housekeepingNotifierHash() =>
    r'079740a1a3df5c2823bbb09e518798e30bcadbaa';

abstract class _$HousekeepingNotifier extends $Notifier<HousekeepingState> {
  HousekeepingState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<HousekeepingState, HousekeepingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HousekeepingState, HousekeepingState>,
              HousekeepingState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
