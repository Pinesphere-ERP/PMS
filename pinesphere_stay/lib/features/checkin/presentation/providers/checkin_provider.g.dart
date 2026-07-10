// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CheckInNotifier)
final checkInProvider = CheckInNotifierProvider._();

final class CheckInNotifierProvider
    extends $NotifierProvider<CheckInNotifier, CheckInState> {
  CheckInNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkInProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkInNotifierHash();

  @$internal
  @override
  CheckInNotifier create() => CheckInNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckInState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckInState>(value),
    );
  }
}

String _$checkInNotifierHash() => r'814e937b42e9a4a6c65a8f65b0fa68490c0bbf34';

abstract class _$CheckInNotifier extends $Notifier<CheckInState> {
  CheckInState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CheckInState, CheckInState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CheckInState, CheckInState>,
              CheckInState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
