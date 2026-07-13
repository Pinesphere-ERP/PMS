// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CheckOutNotifier)
final checkOutProvider = CheckOutNotifierProvider._();

final class CheckOutNotifierProvider
    extends $NotifierProvider<CheckOutNotifier, CheckOutState> {
  CheckOutNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkOutProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkOutNotifierHash();

  @$internal
  @override
  CheckOutNotifier create() => CheckOutNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckOutState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckOutState>(value),
    );
  }
}

String _$checkOutNotifierHash() => r'65b057f16cf13e624ab15802e83bb2e5498d6587';

abstract class _$CheckOutNotifier extends $Notifier<CheckOutState> {
  CheckOutState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CheckOutState, CheckOutState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CheckOutState, CheckOutState>,
              CheckOutState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
