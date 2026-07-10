// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'housekeeping_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(housekeepingService)
final housekeepingServiceProvider = HousekeepingServiceProvider._();

final class HousekeepingServiceProvider
    extends
        $FunctionalProvider<
          HousekeepingService,
          HousekeepingService,
          HousekeepingService
        >
    with $Provider<HousekeepingService> {
  HousekeepingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'housekeepingServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$housekeepingServiceHash();

  @$internal
  @override
  $ProviderElement<HousekeepingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HousekeepingService create(Ref ref) {
    return housekeepingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HousekeepingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HousekeepingService>(value),
    );
  }
}

String _$housekeepingServiceHash() =>
    r'd83c9510b11d8210fe229ddd83fd3f2f0b608e6d';
