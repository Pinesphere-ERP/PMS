import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

@freezed
abstract class Payment with _$Payment {
  const factory Payment({
    @JsonKey(name: 'payment_id') required String paymentId,
    @JsonKey(name: 'invoice_id') String? invoiceId,
    @JsonKey(name: 'booking_id') String? bookingId,
    @JsonKey(name: 'transaction_id') required String transactionId,
    @JsonKey(name: 'reference_number') String? referenceNumber,
    @JsonKey(name: 'payment_mode') required String paymentMode,
    @JsonKey(name: 'amount', fromJson: _parseDouble) required double amount,
    @JsonKey(name: 'upi_id') String? upiId,
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'card_last4') String? cardLast4,
    @JsonKey(name: 'collected_by') String? collectedBy,
    @JsonKey(name: 'remarks') String? remarks,
    @JsonKey(name: 'status') required String status,
    @JsonKey(name: 'synced') @Default(false) bool synced,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
}

@freezed
abstract class SplitPayment with _$SplitPayment {
  const factory SplitPayment({
    @JsonKey(name: 'mode') required String mode,
    @JsonKey(name: 'amount', fromJson: _parseDouble) required double amount,
  }) = _SplitPayment;

  factory SplitPayment.fromJson(Map<String, dynamic> json) => _$SplitPaymentFromJson(json);
}

@freezed
abstract class PaymentCreateRequest with _$PaymentCreateRequest {
  const factory PaymentCreateRequest({
    @JsonKey(name: 'invoice_id') String? invoiceId,
    @JsonKey(name: 'booking_id') String? bookingId,
    @JsonKey(name: 'payment_mode') required String paymentMode,
    @JsonKey(name: 'amount', fromJson: _parseDouble) required double amount,
    @JsonKey(name: 'upi_id') String? upiId,
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'card_last4') String? cardLast4,
    @JsonKey(name: 'remarks') String? remarks,
    @JsonKey(name: 'split_payments') List<SplitPayment>? splitPayments,
  }) = _PaymentCreateRequest;

  factory PaymentCreateRequest.fromJson(Map<String, dynamic> json) => _$PaymentCreateRequestFromJson(json);
}
