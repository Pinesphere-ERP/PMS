// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Payment {

@JsonKey(name: 'payment_id') String get paymentId;@JsonKey(name: 'invoice_id') String? get invoiceId;@JsonKey(name: 'booking_id') String? get bookingId;@JsonKey(name: 'transaction_id') String get transactionId;@JsonKey(name: 'reference_number') String? get referenceNumber;@JsonKey(name: 'payment_mode') String get paymentMode;@JsonKey(name: 'amount', fromJson: _parseDouble) double get amount;@JsonKey(name: 'upi_id') String? get upiId;@JsonKey(name: 'bank_name') String? get bankName;@JsonKey(name: 'card_last4') String? get cardLast4;@JsonKey(name: 'collected_by') String? get collectedBy;@JsonKey(name: 'remarks') String? get remarks;@JsonKey(name: 'status') String get status;@JsonKey(name: 'synced') bool get synced;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentCopyWith<Payment> get copyWith => _$PaymentCopyWithImpl<Payment>(this as Payment, _$identity);

  /// Serializes this Payment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Payment&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.invoiceId, invoiceId) || other.invoiceId == invoiceId)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.transactionId, transactionId) || other.transactionId == transactionId)&&(identical(other.referenceNumber, referenceNumber) || other.referenceNumber == referenceNumber)&&(identical(other.paymentMode, paymentMode) || other.paymentMode == paymentMode)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.upiId, upiId) || other.upiId == upiId)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.cardLast4, cardLast4) || other.cardLast4 == cardLast4)&&(identical(other.collectedBy, collectedBy) || other.collectedBy == collectedBy)&&(identical(other.remarks, remarks) || other.remarks == remarks)&&(identical(other.status, status) || other.status == status)&&(identical(other.synced, synced) || other.synced == synced)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,paymentId,invoiceId,bookingId,transactionId,referenceNumber,paymentMode,amount,upiId,bankName,cardLast4,collectedBy,remarks,status,synced,createdAt,updatedAt);

@override
String toString() {
  return 'Payment(paymentId: $paymentId, invoiceId: $invoiceId, bookingId: $bookingId, transactionId: $transactionId, referenceNumber: $referenceNumber, paymentMode: $paymentMode, amount: $amount, upiId: $upiId, bankName: $bankName, cardLast4: $cardLast4, collectedBy: $collectedBy, remarks: $remarks, status: $status, synced: $synced, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PaymentCopyWith<$Res>  {
  factory $PaymentCopyWith(Payment value, $Res Function(Payment) _then) = _$PaymentCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'payment_id') String paymentId,@JsonKey(name: 'invoice_id') String? invoiceId,@JsonKey(name: 'booking_id') String? bookingId,@JsonKey(name: 'transaction_id') String transactionId,@JsonKey(name: 'reference_number') String? referenceNumber,@JsonKey(name: 'payment_mode') String paymentMode,@JsonKey(name: 'amount', fromJson: _parseDouble) double amount,@JsonKey(name: 'upi_id') String? upiId,@JsonKey(name: 'bank_name') String? bankName,@JsonKey(name: 'card_last4') String? cardLast4,@JsonKey(name: 'collected_by') String? collectedBy,@JsonKey(name: 'remarks') String? remarks,@JsonKey(name: 'status') String status,@JsonKey(name: 'synced') bool synced,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$PaymentCopyWithImpl<$Res>
    implements $PaymentCopyWith<$Res> {
  _$PaymentCopyWithImpl(this._self, this._then);

  final Payment _self;
  final $Res Function(Payment) _then;

/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? paymentId = null,Object? invoiceId = freezed,Object? bookingId = freezed,Object? transactionId = null,Object? referenceNumber = freezed,Object? paymentMode = null,Object? amount = null,Object? upiId = freezed,Object? bankName = freezed,Object? cardLast4 = freezed,Object? collectedBy = freezed,Object? remarks = freezed,Object? status = null,Object? synced = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
paymentId: null == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String,invoiceId: freezed == invoiceId ? _self.invoiceId : invoiceId // ignore: cast_nullable_to_non_nullable
as String?,bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String?,transactionId: null == transactionId ? _self.transactionId : transactionId // ignore: cast_nullable_to_non_nullable
as String,referenceNumber: freezed == referenceNumber ? _self.referenceNumber : referenceNumber // ignore: cast_nullable_to_non_nullable
as String?,paymentMode: null == paymentMode ? _self.paymentMode : paymentMode // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,upiId: freezed == upiId ? _self.upiId : upiId // ignore: cast_nullable_to_non_nullable
as String?,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,cardLast4: freezed == cardLast4 ? _self.cardLast4 : cardLast4 // ignore: cast_nullable_to_non_nullable
as String?,collectedBy: freezed == collectedBy ? _self.collectedBy : collectedBy // ignore: cast_nullable_to_non_nullable
as String?,remarks: freezed == remarks ? _self.remarks : remarks // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,synced: null == synced ? _self.synced : synced // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Payment].
extension PaymentPatterns on Payment {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Payment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Payment() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Payment value)  $default,){
final _that = this;
switch (_that) {
case _Payment():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Payment value)?  $default,){
final _that = this;
switch (_that) {
case _Payment() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'payment_id')  String paymentId, @JsonKey(name: 'invoice_id')  String? invoiceId, @JsonKey(name: 'booking_id')  String? bookingId, @JsonKey(name: 'transaction_id')  String transactionId, @JsonKey(name: 'reference_number')  String? referenceNumber, @JsonKey(name: 'payment_mode')  String paymentMode, @JsonKey(name: 'amount', fromJson: _parseDouble)  double amount, @JsonKey(name: 'upi_id')  String? upiId, @JsonKey(name: 'bank_name')  String? bankName, @JsonKey(name: 'card_last4')  String? cardLast4, @JsonKey(name: 'collected_by')  String? collectedBy, @JsonKey(name: 'remarks')  String? remarks, @JsonKey(name: 'status')  String status, @JsonKey(name: 'synced')  bool synced, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Payment() when $default != null:
return $default(_that.paymentId,_that.invoiceId,_that.bookingId,_that.transactionId,_that.referenceNumber,_that.paymentMode,_that.amount,_that.upiId,_that.bankName,_that.cardLast4,_that.collectedBy,_that.remarks,_that.status,_that.synced,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'payment_id')  String paymentId, @JsonKey(name: 'invoice_id')  String? invoiceId, @JsonKey(name: 'booking_id')  String? bookingId, @JsonKey(name: 'transaction_id')  String transactionId, @JsonKey(name: 'reference_number')  String? referenceNumber, @JsonKey(name: 'payment_mode')  String paymentMode, @JsonKey(name: 'amount', fromJson: _parseDouble)  double amount, @JsonKey(name: 'upi_id')  String? upiId, @JsonKey(name: 'bank_name')  String? bankName, @JsonKey(name: 'card_last4')  String? cardLast4, @JsonKey(name: 'collected_by')  String? collectedBy, @JsonKey(name: 'remarks')  String? remarks, @JsonKey(name: 'status')  String status, @JsonKey(name: 'synced')  bool synced, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Payment():
return $default(_that.paymentId,_that.invoiceId,_that.bookingId,_that.transactionId,_that.referenceNumber,_that.paymentMode,_that.amount,_that.upiId,_that.bankName,_that.cardLast4,_that.collectedBy,_that.remarks,_that.status,_that.synced,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'payment_id')  String paymentId, @JsonKey(name: 'invoice_id')  String? invoiceId, @JsonKey(name: 'booking_id')  String? bookingId, @JsonKey(name: 'transaction_id')  String transactionId, @JsonKey(name: 'reference_number')  String? referenceNumber, @JsonKey(name: 'payment_mode')  String paymentMode, @JsonKey(name: 'amount', fromJson: _parseDouble)  double amount, @JsonKey(name: 'upi_id')  String? upiId, @JsonKey(name: 'bank_name')  String? bankName, @JsonKey(name: 'card_last4')  String? cardLast4, @JsonKey(name: 'collected_by')  String? collectedBy, @JsonKey(name: 'remarks')  String? remarks, @JsonKey(name: 'status')  String status, @JsonKey(name: 'synced')  bool synced, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Payment() when $default != null:
return $default(_that.paymentId,_that.invoiceId,_that.bookingId,_that.transactionId,_that.referenceNumber,_that.paymentMode,_that.amount,_that.upiId,_that.bankName,_that.cardLast4,_that.collectedBy,_that.remarks,_that.status,_that.synced,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Payment implements Payment {
  const _Payment({@JsonKey(name: 'payment_id') required this.paymentId, @JsonKey(name: 'invoice_id') this.invoiceId, @JsonKey(name: 'booking_id') this.bookingId, @JsonKey(name: 'transaction_id') required this.transactionId, @JsonKey(name: 'reference_number') this.referenceNumber, @JsonKey(name: 'payment_mode') required this.paymentMode, @JsonKey(name: 'amount', fromJson: _parseDouble) required this.amount, @JsonKey(name: 'upi_id') this.upiId, @JsonKey(name: 'bank_name') this.bankName, @JsonKey(name: 'card_last4') this.cardLast4, @JsonKey(name: 'collected_by') this.collectedBy, @JsonKey(name: 'remarks') this.remarks, @JsonKey(name: 'status') required this.status, @JsonKey(name: 'synced') this.synced = false, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt});
  factory _Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);

@override@JsonKey(name: 'payment_id') final  String paymentId;
@override@JsonKey(name: 'invoice_id') final  String? invoiceId;
@override@JsonKey(name: 'booking_id') final  String? bookingId;
@override@JsonKey(name: 'transaction_id') final  String transactionId;
@override@JsonKey(name: 'reference_number') final  String? referenceNumber;
@override@JsonKey(name: 'payment_mode') final  String paymentMode;
@override@JsonKey(name: 'amount', fromJson: _parseDouble) final  double amount;
@override@JsonKey(name: 'upi_id') final  String? upiId;
@override@JsonKey(name: 'bank_name') final  String? bankName;
@override@JsonKey(name: 'card_last4') final  String? cardLast4;
@override@JsonKey(name: 'collected_by') final  String? collectedBy;
@override@JsonKey(name: 'remarks') final  String? remarks;
@override@JsonKey(name: 'status') final  String status;
@override@JsonKey(name: 'synced') final  bool synced;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentCopyWith<_Payment> get copyWith => __$PaymentCopyWithImpl<_Payment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Payment&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.invoiceId, invoiceId) || other.invoiceId == invoiceId)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.transactionId, transactionId) || other.transactionId == transactionId)&&(identical(other.referenceNumber, referenceNumber) || other.referenceNumber == referenceNumber)&&(identical(other.paymentMode, paymentMode) || other.paymentMode == paymentMode)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.upiId, upiId) || other.upiId == upiId)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.cardLast4, cardLast4) || other.cardLast4 == cardLast4)&&(identical(other.collectedBy, collectedBy) || other.collectedBy == collectedBy)&&(identical(other.remarks, remarks) || other.remarks == remarks)&&(identical(other.status, status) || other.status == status)&&(identical(other.synced, synced) || other.synced == synced)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,paymentId,invoiceId,bookingId,transactionId,referenceNumber,paymentMode,amount,upiId,bankName,cardLast4,collectedBy,remarks,status,synced,createdAt,updatedAt);

@override
String toString() {
  return 'Payment(paymentId: $paymentId, invoiceId: $invoiceId, bookingId: $bookingId, transactionId: $transactionId, referenceNumber: $referenceNumber, paymentMode: $paymentMode, amount: $amount, upiId: $upiId, bankName: $bankName, cardLast4: $cardLast4, collectedBy: $collectedBy, remarks: $remarks, status: $status, synced: $synced, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PaymentCopyWith<$Res> implements $PaymentCopyWith<$Res> {
  factory _$PaymentCopyWith(_Payment value, $Res Function(_Payment) _then) = __$PaymentCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'payment_id') String paymentId,@JsonKey(name: 'invoice_id') String? invoiceId,@JsonKey(name: 'booking_id') String? bookingId,@JsonKey(name: 'transaction_id') String transactionId,@JsonKey(name: 'reference_number') String? referenceNumber,@JsonKey(name: 'payment_mode') String paymentMode,@JsonKey(name: 'amount', fromJson: _parseDouble) double amount,@JsonKey(name: 'upi_id') String? upiId,@JsonKey(name: 'bank_name') String? bankName,@JsonKey(name: 'card_last4') String? cardLast4,@JsonKey(name: 'collected_by') String? collectedBy,@JsonKey(name: 'remarks') String? remarks,@JsonKey(name: 'status') String status,@JsonKey(name: 'synced') bool synced,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$PaymentCopyWithImpl<$Res>
    implements _$PaymentCopyWith<$Res> {
  __$PaymentCopyWithImpl(this._self, this._then);

  final _Payment _self;
  final $Res Function(_Payment) _then;

/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? paymentId = null,Object? invoiceId = freezed,Object? bookingId = freezed,Object? transactionId = null,Object? referenceNumber = freezed,Object? paymentMode = null,Object? amount = null,Object? upiId = freezed,Object? bankName = freezed,Object? cardLast4 = freezed,Object? collectedBy = freezed,Object? remarks = freezed,Object? status = null,Object? synced = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_Payment(
paymentId: null == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String,invoiceId: freezed == invoiceId ? _self.invoiceId : invoiceId // ignore: cast_nullable_to_non_nullable
as String?,bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String?,transactionId: null == transactionId ? _self.transactionId : transactionId // ignore: cast_nullable_to_non_nullable
as String,referenceNumber: freezed == referenceNumber ? _self.referenceNumber : referenceNumber // ignore: cast_nullable_to_non_nullable
as String?,paymentMode: null == paymentMode ? _self.paymentMode : paymentMode // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,upiId: freezed == upiId ? _self.upiId : upiId // ignore: cast_nullable_to_non_nullable
as String?,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,cardLast4: freezed == cardLast4 ? _self.cardLast4 : cardLast4 // ignore: cast_nullable_to_non_nullable
as String?,collectedBy: freezed == collectedBy ? _self.collectedBy : collectedBy // ignore: cast_nullable_to_non_nullable
as String?,remarks: freezed == remarks ? _self.remarks : remarks // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,synced: null == synced ? _self.synced : synced // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$SplitPayment {

@JsonKey(name: 'mode') String get mode;@JsonKey(name: 'amount', fromJson: _parseDouble) double get amount;
/// Create a copy of SplitPayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SplitPaymentCopyWith<SplitPayment> get copyWith => _$SplitPaymentCopyWithImpl<SplitPayment>(this as SplitPayment, _$identity);

  /// Serializes this SplitPayment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SplitPayment&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode,amount);

@override
String toString() {
  return 'SplitPayment(mode: $mode, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $SplitPaymentCopyWith<$Res>  {
  factory $SplitPaymentCopyWith(SplitPayment value, $Res Function(SplitPayment) _then) = _$SplitPaymentCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'mode') String mode,@JsonKey(name: 'amount', fromJson: _parseDouble) double amount
});




}
/// @nodoc
class _$SplitPaymentCopyWithImpl<$Res>
    implements $SplitPaymentCopyWith<$Res> {
  _$SplitPaymentCopyWithImpl(this._self, this._then);

  final SplitPayment _self;
  final $Res Function(SplitPayment) _then;

/// Create a copy of SplitPayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,Object? amount = null,}) {
  return _then(_self.copyWith(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [SplitPayment].
extension SplitPaymentPatterns on SplitPayment {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SplitPayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SplitPayment() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SplitPayment value)  $default,){
final _that = this;
switch (_that) {
case _SplitPayment():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SplitPayment value)?  $default,){
final _that = this;
switch (_that) {
case _SplitPayment() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'mode')  String mode, @JsonKey(name: 'amount', fromJson: _parseDouble)  double amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SplitPayment() when $default != null:
return $default(_that.mode,_that.amount);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'mode')  String mode, @JsonKey(name: 'amount', fromJson: _parseDouble)  double amount)  $default,) {final _that = this;
switch (_that) {
case _SplitPayment():
return $default(_that.mode,_that.amount);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'mode')  String mode, @JsonKey(name: 'amount', fromJson: _parseDouble)  double amount)?  $default,) {final _that = this;
switch (_that) {
case _SplitPayment() when $default != null:
return $default(_that.mode,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SplitPayment implements SplitPayment {
  const _SplitPayment({@JsonKey(name: 'mode') required this.mode, @JsonKey(name: 'amount', fromJson: _parseDouble) required this.amount});
  factory _SplitPayment.fromJson(Map<String, dynamic> json) => _$SplitPaymentFromJson(json);

@override@JsonKey(name: 'mode') final  String mode;
@override@JsonKey(name: 'amount', fromJson: _parseDouble) final  double amount;

/// Create a copy of SplitPayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SplitPaymentCopyWith<_SplitPayment> get copyWith => __$SplitPaymentCopyWithImpl<_SplitPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SplitPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SplitPayment&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode,amount);

@override
String toString() {
  return 'SplitPayment(mode: $mode, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$SplitPaymentCopyWith<$Res> implements $SplitPaymentCopyWith<$Res> {
  factory _$SplitPaymentCopyWith(_SplitPayment value, $Res Function(_SplitPayment) _then) = __$SplitPaymentCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'mode') String mode,@JsonKey(name: 'amount', fromJson: _parseDouble) double amount
});




}
/// @nodoc
class __$SplitPaymentCopyWithImpl<$Res>
    implements _$SplitPaymentCopyWith<$Res> {
  __$SplitPaymentCopyWithImpl(this._self, this._then);

  final _SplitPayment _self;
  final $Res Function(_SplitPayment) _then;

/// Create a copy of SplitPayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? amount = null,}) {
  return _then(_SplitPayment(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$PaymentCreateRequest {

@JsonKey(name: 'invoice_id') String? get invoiceId;@JsonKey(name: 'booking_id') String? get bookingId;@JsonKey(name: 'payment_mode') String get paymentMode;@JsonKey(name: 'amount', fromJson: _parseDouble) double get amount;@JsonKey(name: 'upi_id') String? get upiId;@JsonKey(name: 'bank_name') String? get bankName;@JsonKey(name: 'card_last4') String? get cardLast4;@JsonKey(name: 'remarks') String? get remarks;@JsonKey(name: 'split_payments') List<SplitPayment>? get splitPayments;
/// Create a copy of PaymentCreateRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentCreateRequestCopyWith<PaymentCreateRequest> get copyWith => _$PaymentCreateRequestCopyWithImpl<PaymentCreateRequest>(this as PaymentCreateRequest, _$identity);

  /// Serializes this PaymentCreateRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentCreateRequest&&(identical(other.invoiceId, invoiceId) || other.invoiceId == invoiceId)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.paymentMode, paymentMode) || other.paymentMode == paymentMode)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.upiId, upiId) || other.upiId == upiId)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.cardLast4, cardLast4) || other.cardLast4 == cardLast4)&&(identical(other.remarks, remarks) || other.remarks == remarks)&&const DeepCollectionEquality().equals(other.splitPayments, splitPayments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,invoiceId,bookingId,paymentMode,amount,upiId,bankName,cardLast4,remarks,const DeepCollectionEquality().hash(splitPayments));

@override
String toString() {
  return 'PaymentCreateRequest(invoiceId: $invoiceId, bookingId: $bookingId, paymentMode: $paymentMode, amount: $amount, upiId: $upiId, bankName: $bankName, cardLast4: $cardLast4, remarks: $remarks, splitPayments: $splitPayments)';
}


}

/// @nodoc
abstract mixin class $PaymentCreateRequestCopyWith<$Res>  {
  factory $PaymentCreateRequestCopyWith(PaymentCreateRequest value, $Res Function(PaymentCreateRequest) _then) = _$PaymentCreateRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'invoice_id') String? invoiceId,@JsonKey(name: 'booking_id') String? bookingId,@JsonKey(name: 'payment_mode') String paymentMode,@JsonKey(name: 'amount', fromJson: _parseDouble) double amount,@JsonKey(name: 'upi_id') String? upiId,@JsonKey(name: 'bank_name') String? bankName,@JsonKey(name: 'card_last4') String? cardLast4,@JsonKey(name: 'remarks') String? remarks,@JsonKey(name: 'split_payments') List<SplitPayment>? splitPayments
});




}
/// @nodoc
class _$PaymentCreateRequestCopyWithImpl<$Res>
    implements $PaymentCreateRequestCopyWith<$Res> {
  _$PaymentCreateRequestCopyWithImpl(this._self, this._then);

  final PaymentCreateRequest _self;
  final $Res Function(PaymentCreateRequest) _then;

/// Create a copy of PaymentCreateRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? invoiceId = freezed,Object? bookingId = freezed,Object? paymentMode = null,Object? amount = null,Object? upiId = freezed,Object? bankName = freezed,Object? cardLast4 = freezed,Object? remarks = freezed,Object? splitPayments = freezed,}) {
  return _then(_self.copyWith(
invoiceId: freezed == invoiceId ? _self.invoiceId : invoiceId // ignore: cast_nullable_to_non_nullable
as String?,bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String?,paymentMode: null == paymentMode ? _self.paymentMode : paymentMode // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,upiId: freezed == upiId ? _self.upiId : upiId // ignore: cast_nullable_to_non_nullable
as String?,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,cardLast4: freezed == cardLast4 ? _self.cardLast4 : cardLast4 // ignore: cast_nullable_to_non_nullable
as String?,remarks: freezed == remarks ? _self.remarks : remarks // ignore: cast_nullable_to_non_nullable
as String?,splitPayments: freezed == splitPayments ? _self.splitPayments : splitPayments // ignore: cast_nullable_to_non_nullable
as List<SplitPayment>?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentCreateRequest].
extension PaymentCreateRequestPatterns on PaymentCreateRequest {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentCreateRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentCreateRequest() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentCreateRequest value)  $default,){
final _that = this;
switch (_that) {
case _PaymentCreateRequest():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentCreateRequest value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentCreateRequest() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'invoice_id')  String? invoiceId, @JsonKey(name: 'booking_id')  String? bookingId, @JsonKey(name: 'payment_mode')  String paymentMode, @JsonKey(name: 'amount', fromJson: _parseDouble)  double amount, @JsonKey(name: 'upi_id')  String? upiId, @JsonKey(name: 'bank_name')  String? bankName, @JsonKey(name: 'card_last4')  String? cardLast4, @JsonKey(name: 'remarks')  String? remarks, @JsonKey(name: 'split_payments')  List<SplitPayment>? splitPayments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentCreateRequest() when $default != null:
return $default(_that.invoiceId,_that.bookingId,_that.paymentMode,_that.amount,_that.upiId,_that.bankName,_that.cardLast4,_that.remarks,_that.splitPayments);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'invoice_id')  String? invoiceId, @JsonKey(name: 'booking_id')  String? bookingId, @JsonKey(name: 'payment_mode')  String paymentMode, @JsonKey(name: 'amount', fromJson: _parseDouble)  double amount, @JsonKey(name: 'upi_id')  String? upiId, @JsonKey(name: 'bank_name')  String? bankName, @JsonKey(name: 'card_last4')  String? cardLast4, @JsonKey(name: 'remarks')  String? remarks, @JsonKey(name: 'split_payments')  List<SplitPayment>? splitPayments)  $default,) {final _that = this;
switch (_that) {
case _PaymentCreateRequest():
return $default(_that.invoiceId,_that.bookingId,_that.paymentMode,_that.amount,_that.upiId,_that.bankName,_that.cardLast4,_that.remarks,_that.splitPayments);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'invoice_id')  String? invoiceId, @JsonKey(name: 'booking_id')  String? bookingId, @JsonKey(name: 'payment_mode')  String paymentMode, @JsonKey(name: 'amount', fromJson: _parseDouble)  double amount, @JsonKey(name: 'upi_id')  String? upiId, @JsonKey(name: 'bank_name')  String? bankName, @JsonKey(name: 'card_last4')  String? cardLast4, @JsonKey(name: 'remarks')  String? remarks, @JsonKey(name: 'split_payments')  List<SplitPayment>? splitPayments)?  $default,) {final _that = this;
switch (_that) {
case _PaymentCreateRequest() when $default != null:
return $default(_that.invoiceId,_that.bookingId,_that.paymentMode,_that.amount,_that.upiId,_that.bankName,_that.cardLast4,_that.remarks,_that.splitPayments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentCreateRequest implements PaymentCreateRequest {
  const _PaymentCreateRequest({@JsonKey(name: 'invoice_id') this.invoiceId, @JsonKey(name: 'booking_id') this.bookingId, @JsonKey(name: 'payment_mode') required this.paymentMode, @JsonKey(name: 'amount', fromJson: _parseDouble) required this.amount, @JsonKey(name: 'upi_id') this.upiId, @JsonKey(name: 'bank_name') this.bankName, @JsonKey(name: 'card_last4') this.cardLast4, @JsonKey(name: 'remarks') this.remarks, @JsonKey(name: 'split_payments') final  List<SplitPayment>? splitPayments}): _splitPayments = splitPayments;
  factory _PaymentCreateRequest.fromJson(Map<String, dynamic> json) => _$PaymentCreateRequestFromJson(json);

@override@JsonKey(name: 'invoice_id') final  String? invoiceId;
@override@JsonKey(name: 'booking_id') final  String? bookingId;
@override@JsonKey(name: 'payment_mode') final  String paymentMode;
@override@JsonKey(name: 'amount', fromJson: _parseDouble) final  double amount;
@override@JsonKey(name: 'upi_id') final  String? upiId;
@override@JsonKey(name: 'bank_name') final  String? bankName;
@override@JsonKey(name: 'card_last4') final  String? cardLast4;
@override@JsonKey(name: 'remarks') final  String? remarks;
 final  List<SplitPayment>? _splitPayments;
@override@JsonKey(name: 'split_payments') List<SplitPayment>? get splitPayments {
  final value = _splitPayments;
  if (value == null) return null;
  if (_splitPayments is EqualUnmodifiableListView) return _splitPayments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of PaymentCreateRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentCreateRequestCopyWith<_PaymentCreateRequest> get copyWith => __$PaymentCreateRequestCopyWithImpl<_PaymentCreateRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentCreateRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentCreateRequest&&(identical(other.invoiceId, invoiceId) || other.invoiceId == invoiceId)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.paymentMode, paymentMode) || other.paymentMode == paymentMode)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.upiId, upiId) || other.upiId == upiId)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.cardLast4, cardLast4) || other.cardLast4 == cardLast4)&&(identical(other.remarks, remarks) || other.remarks == remarks)&&const DeepCollectionEquality().equals(other._splitPayments, _splitPayments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,invoiceId,bookingId,paymentMode,amount,upiId,bankName,cardLast4,remarks,const DeepCollectionEquality().hash(_splitPayments));

@override
String toString() {
  return 'PaymentCreateRequest(invoiceId: $invoiceId, bookingId: $bookingId, paymentMode: $paymentMode, amount: $amount, upiId: $upiId, bankName: $bankName, cardLast4: $cardLast4, remarks: $remarks, splitPayments: $splitPayments)';
}


}

/// @nodoc
abstract mixin class _$PaymentCreateRequestCopyWith<$Res> implements $PaymentCreateRequestCopyWith<$Res> {
  factory _$PaymentCreateRequestCopyWith(_PaymentCreateRequest value, $Res Function(_PaymentCreateRequest) _then) = __$PaymentCreateRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'invoice_id') String? invoiceId,@JsonKey(name: 'booking_id') String? bookingId,@JsonKey(name: 'payment_mode') String paymentMode,@JsonKey(name: 'amount', fromJson: _parseDouble) double amount,@JsonKey(name: 'upi_id') String? upiId,@JsonKey(name: 'bank_name') String? bankName,@JsonKey(name: 'card_last4') String? cardLast4,@JsonKey(name: 'remarks') String? remarks,@JsonKey(name: 'split_payments') List<SplitPayment>? splitPayments
});




}
/// @nodoc
class __$PaymentCreateRequestCopyWithImpl<$Res>
    implements _$PaymentCreateRequestCopyWith<$Res> {
  __$PaymentCreateRequestCopyWithImpl(this._self, this._then);

  final _PaymentCreateRequest _self;
  final $Res Function(_PaymentCreateRequest) _then;

/// Create a copy of PaymentCreateRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? invoiceId = freezed,Object? bookingId = freezed,Object? paymentMode = null,Object? amount = null,Object? upiId = freezed,Object? bankName = freezed,Object? cardLast4 = freezed,Object? remarks = freezed,Object? splitPayments = freezed,}) {
  return _then(_PaymentCreateRequest(
invoiceId: freezed == invoiceId ? _self.invoiceId : invoiceId // ignore: cast_nullable_to_non_nullable
as String?,bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String?,paymentMode: null == paymentMode ? _self.paymentMode : paymentMode // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,upiId: freezed == upiId ? _self.upiId : upiId // ignore: cast_nullable_to_non_nullable
as String?,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,cardLast4: freezed == cardLast4 ? _self.cardLast4 : cardLast4 // ignore: cast_nullable_to_non_nullable
as String?,remarks: freezed == remarks ? _self.remarks : remarks // ignore: cast_nullable_to_non_nullable
as String?,splitPayments: freezed == splitPayments ? _self._splitPayments : splitPayments // ignore: cast_nullable_to_non_nullable
as List<SplitPayment>?,
  ));
}


}

// dart format on
