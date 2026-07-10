// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Payment _$PaymentFromJson(Map<String, dynamic> json) => _Payment(
  paymentId: json['paymentId'] as String,
  invoiceId: json['invoiceId'] as String?,
  bookingId: json['bookingId'] as String?,
  transactionId: json['transactionId'] as String,
  referenceNumber: json['referenceNumber'] as String?,
  paymentMode: json['paymentMode'] as String,
  amount: (json['amount'] as num).toDouble(),
  upiId: json['upiId'] as String?,
  bankName: json['bankName'] as String?,
  cardLast4: json['cardLast4'] as String?,
  collectedBy: json['collectedBy'] as String?,
  remarks: json['remarks'] as String?,
  status: json['status'] as String,
  synced: json['synced'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$PaymentToJson(_Payment instance) => <String, dynamic>{
  'paymentId': instance.paymentId,
  'invoiceId': instance.invoiceId,
  'bookingId': instance.bookingId,
  'transactionId': instance.transactionId,
  'referenceNumber': instance.referenceNumber,
  'paymentMode': instance.paymentMode,
  'amount': instance.amount,
  'upiId': instance.upiId,
  'bankName': instance.bankName,
  'cardLast4': instance.cardLast4,
  'collectedBy': instance.collectedBy,
  'remarks': instance.remarks,
  'status': instance.status,
  'synced': instance.synced,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

_SplitPayment _$SplitPaymentFromJson(Map<String, dynamic> json) =>
    _SplitPayment(
      mode: json['mode'] as String,
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$SplitPaymentToJson(_SplitPayment instance) =>
    <String, dynamic>{'mode': instance.mode, 'amount': instance.amount};

_PaymentCreateRequest _$PaymentCreateRequestFromJson(
  Map<String, dynamic> json,
) => _PaymentCreateRequest(
  invoiceId: json['invoiceId'] as String?,
  bookingId: json['bookingId'] as String?,
  paymentMode: json['paymentMode'] as String,
  amount: (json['amount'] as num).toDouble(),
  upiId: json['upiId'] as String?,
  bankName: json['bankName'] as String?,
  cardLast4: json['cardLast4'] as String?,
  remarks: json['remarks'] as String?,
  splitPayments: (json['splitPayments'] as List<dynamic>?)
      ?.map((e) => SplitPayment.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PaymentCreateRequestToJson(
  _PaymentCreateRequest instance,
) => <String, dynamic>{
  'invoiceId': instance.invoiceId,
  'bookingId': instance.bookingId,
  'paymentMode': instance.paymentMode,
  'amount': instance.amount,
  'upiId': instance.upiId,
  'bankName': instance.bankName,
  'cardLast4': instance.cardLast4,
  'remarks': instance.remarks,
  'splitPayments': instance.splitPayments,
};
