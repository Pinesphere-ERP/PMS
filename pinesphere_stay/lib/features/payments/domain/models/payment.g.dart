// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Payment _$PaymentFromJson(Map<String, dynamic> json) => _Payment(
  paymentId: json['payment_id'] as String,
  invoiceId: json['invoice_id'] as String?,
  bookingId: json['booking_id'] as String?,
  transactionId: json['transaction_id'] as String,
  referenceNumber: json['reference_number'] as String?,
  paymentMode: json['payment_mode'] as String,
  amount: _parseDouble(json['amount']),
  upiId: json['upi_id'] as String?,
  bankName: json['bank_name'] as String?,
  cardLast4: json['card_last4'] as String?,
  collectedBy: json['collected_by'] as String?,
  remarks: json['remarks'] as String?,
  status: json['status'] as String,
  synced: json['synced'] as bool? ?? false,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$PaymentToJson(_Payment instance) => <String, dynamic>{
  'payment_id': instance.paymentId,
  'invoice_id': instance.invoiceId,
  'booking_id': instance.bookingId,
  'transaction_id': instance.transactionId,
  'reference_number': instance.referenceNumber,
  'payment_mode': instance.paymentMode,
  'amount': instance.amount,
  'upi_id': instance.upiId,
  'bank_name': instance.bankName,
  'card_last4': instance.cardLast4,
  'collected_by': instance.collectedBy,
  'remarks': instance.remarks,
  'status': instance.status,
  'synced': instance.synced,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

_SplitPayment _$SplitPaymentFromJson(Map<String, dynamic> json) =>
    _SplitPayment(
      mode: json['mode'] as String,
      amount: _parseDouble(json['amount']),
    );

Map<String, dynamic> _$SplitPaymentToJson(_SplitPayment instance) =>
    <String, dynamic>{'mode': instance.mode, 'amount': instance.amount};

_PaymentCreateRequest _$PaymentCreateRequestFromJson(
  Map<String, dynamic> json,
) => _PaymentCreateRequest(
  invoiceId: json['invoice_id'] as String?,
  bookingId: json['booking_id'] as String?,
  paymentMode: json['payment_mode'] as String,
  amount: _parseDouble(json['amount']),
  upiId: json['upi_id'] as String?,
  bankName: json['bank_name'] as String?,
  cardLast4: json['card_last4'] as String?,
  remarks: json['remarks'] as String?,
  splitPayments: (json['split_payments'] as List<dynamic>?)
      ?.map((e) => SplitPayment.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PaymentCreateRequestToJson(
  _PaymentCreateRequest instance,
) => <String, dynamic>{
  'invoice_id': instance.invoiceId,
  'booking_id': instance.bookingId,
  'payment_mode': instance.paymentMode,
  'amount': instance.amount,
  'upi_id': instance.upiId,
  'bank_name': instance.bankName,
  'card_last4': instance.cardLast4,
  'remarks': instance.remarks,
  'split_payments': instance.splitPayments,
};
