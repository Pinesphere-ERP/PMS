// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(checkOutService)
final checkOutServiceProvider = CheckOutServiceProvider._();

final class CheckOutServiceProvider
    extends
        $FunctionalProvider<CheckOutService, CheckOutService, CheckOutService>
    with $Provider<CheckOutService> {
  CheckOutServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkOutServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkOutServiceHash();

  @$internal
  @override
  $ProviderElement<CheckOutService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CheckOutService create(Ref ref) {
    return checkOutService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckOutService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckOutService>(value),
    );
  }
}

String _$checkOutServiceHash() => r'94cc7f4e2d16d81bc4a3733fd480f3c39c9869d1';
