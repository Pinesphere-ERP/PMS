// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_history_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(paymentsList)
final paymentsListProvider = PaymentsListProvider._();

final class PaymentsListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Payment>>,
          List<Payment>,
          FutureOr<List<Payment>>
        >
    with $FutureModifier<List<Payment>>, $FutureProvider<List<Payment>> {
  PaymentsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentsListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentsListHash();

  @$internal
  @override
  $FutureProviderElement<List<Payment>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Payment>> create(Ref ref) {
    return paymentsList(ref);
  }
}

String _$paymentsListHash() => r'708b02b86221296af4cf9f03feab06bc5c1fade0';
