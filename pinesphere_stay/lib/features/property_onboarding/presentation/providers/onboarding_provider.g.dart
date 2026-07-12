// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OnboardingNotifier)
final onboardingProvider = OnboardingNotifierProvider._();

final class OnboardingNotifierProvider
    extends $NotifierProvider<OnboardingNotifier, OnboardingFormState> {
  OnboardingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingNotifierHash();

  @$internal
  @override
  OnboardingNotifier create() => OnboardingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingFormState>(value),
    );
  }
}

String _$onboardingNotifierHash() =>
    r'3eea665db7502a21aef327518da82a17b5acdac7';

abstract class _$OnboardingNotifier extends $Notifier<OnboardingFormState> {
  OnboardingFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<OnboardingFormState, OnboardingFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OnboardingFormState, OnboardingFormState>,
              OnboardingFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
