import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

@freezed
class Payment with _$Payment {
  const factory Payment({
    required String paymentId,
    String? invoiceId,
    String? bookingId,
    required String transactionId,
    String? referenceNumber,
    required String paymentMode,
    required double amount,
    String? upiId,
    String? bankName,
    String? cardLast4,
    String? collectedBy,
    String? remarks,
    required String status,
    @Default(false) bool synced,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
}

@freezed
class SplitPayment with _$SplitPayment {
  const factory SplitPayment({
    required String mode,
    required double amount,
  }) = _SplitPayment;

  factory SplitPayment.fromJson(Map<String, dynamic> json) => _$SplitPaymentFromJson(json);
}

@freezed
class PaymentCreateRequest with _$PaymentCreateRequest {
  const factory PaymentCreateRequest({
    String? invoiceId,
    String? bookingId,
    required String paymentMode,
    required double amount,
    String? upiId,
    String? bankName,
    String? cardLast4,
    String? remarks,
    List<SplitPayment>? splitPayments,
  }) = _PaymentCreateRequest;

  factory PaymentCreateRequest.fromJson(Map<String, dynamic> json) => _$PaymentCreateRequestFromJson(json);
}
