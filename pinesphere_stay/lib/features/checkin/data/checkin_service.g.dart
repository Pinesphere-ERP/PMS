// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkin_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(checkInService)
final checkInServiceProvider = CheckInServiceProvider._();

final class CheckInServiceProvider
    extends $FunctionalProvider<CheckInService, CheckInService, CheckInService>
    with $Provider<CheckInService> {
  CheckInServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkInServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkInServiceHash();

  @$internal
  @override
  $ProviderElement<CheckInService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CheckInService create(Ref ref) {
    return checkInService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckInService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckInService>(value),
    );
  }
}

String _$checkInServiceHash() => r'edc225ad253750c9b1d3fa7adcb3c61a888faae6';
