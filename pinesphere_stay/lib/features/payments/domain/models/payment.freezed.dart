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

 String get paymentId; String? get invoiceId; String? get bookingId; String get transactionId; String? get referenceNumber; String get paymentMode; double get amount; String? get upiId; String? get bankName; String? get cardLast4; String? get collectedBy; String? get remarks; String get status; bool get synced; DateTime get createdAt; DateTime? get updatedAt;
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
 String paymentId, String? invoiceId, String? bookingId, String transactionId, String? referenceNumber, String paymentMode, double amount, String? upiId, String? bankName, String? cardLast4, String? collectedBy, String? remarks, String status, bool synced, DateTime createdAt, DateTime? updatedAt
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String paymentId,  String? invoiceId,  String? bookingId,  String transactionId,  String? referenceNumber,  String paymentMode,  double amount,  String? upiId,  String? bankName,  String? cardLast4,  String? collectedBy,  String? remarks,  String status,  bool synced,  DateTime createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String paymentId,  String? invoiceId,  String? bookingId,  String transactionId,  String? referenceNumber,  String paymentMode,  double amount,  String? upiId,  String? bankName,  String? cardLast4,  String? collectedBy,  String? remarks,  String status,  bool synced,  DateTime createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String paymentId,  String? invoiceId,  String? bookingId,  String transactionId,  String? referenceNumber,  String paymentMode,  double amount,  String? upiId,  String? bankName,  String? cardLast4,  String? collectedBy,  String? remarks,  String status,  bool synced,  DateTime createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
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
  const _Payment({required this.paymentId, this.invoiceId, this.bookingId, required this.transactionId, this.referenceNumber, required this.paymentMode, required this.amount, this.upiId, this.bankName, this.cardLast4, this.collectedBy, this.remarks, required this.status, this.synced = false, required this.createdAt, this.updatedAt});
  factory _Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);

@override final  String paymentId;
@override final  String? invoiceId;
@override final  String? bookingId;
@override final  String transactionId;
@override final  String? referenceNumber;
@override final  String paymentMode;
@override final  double amount;
@override final  String? upiId;
@override final  String? bankName;
@override final  String? cardLast4;
@override final  String? collectedBy;
@override final  String? remarks;
@override final  String status;
@override@JsonKey() final  bool synced;
@override final  DateTime createdAt;
@override final  DateTime? updatedAt;

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
 String paymentId, String? invoiceId, String? bookingId, String transactionId, String? referenceNumber, String paymentMode, double amount, String? upiId, String? bankName, String? cardLast4, String? collectedBy, String? remarks, String status, bool synced, DateTime createdAt, DateTime? updatedAt
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

 String get mode; double get amount;
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
 String mode, double amount
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String mode,  double amount)?  $default,{required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String mode,  double amount)  $default,) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String mode,  double amount)?  $default,) {final _that = this;
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
  const _SplitPayment({required this.mode, required this.amount});
  factory _SplitPayment.fromJson(Map<String, dynamic> json) => _$SplitPaymentFromJson(json);

@override final  String mode;
@override final  double amount;

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
 String mode, double amount
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

 String? get invoiceId; String? get bookingId; String get paymentMode; double get amount; String? get upiId; String? get bankName; String? get cardLast4; String? get remarks; List<SplitPayment>? get splitPayments;
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
 String? invoiceId, String? bookingId, String paymentMode, double amount, String? upiId, String? bankName, String? cardLast4, String? remarks, List<SplitPayment>? splitPayments
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? invoiceId,  String? bookingId,  String paymentMode,  double amount,  String? upiId,  String? bankName,  String? cardLast4,  String? remarks,  List<SplitPayment>? splitPayments)?  $default,{required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? invoiceId,  String? bookingId,  String paymentMode,  double amount,  String? upiId,  String? bankName,  String? cardLast4,  String? remarks,  List<SplitPayment>? splitPayments)  $default,) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? invoiceId,  String? bookingId,  String paymentMode,  double amount,  String? upiId,  String? bankName,  String? cardLast4,  String? remarks,  List<SplitPayment>? splitPayments)?  $default,) {final _that = this;
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
  const _PaymentCreateRequest({this.invoiceId, this.bookingId, required this.paymentMode, required this.amount, this.upiId, this.bankName, this.cardLast4, this.remarks, final  List<SplitPayment>? splitPayments}): _splitPayments = splitPayments;
  factory _PaymentCreateRequest.fromJson(Map<String, dynamic> json) => _$PaymentCreateRequestFromJson(json);

@override final  String? invoiceId;
@override final  String? bookingId;
@override final  String paymentMode;
@override final  double amount;
@override final  String? upiId;
@override final  String? bankName;
@override final  String? cardLast4;
@override final  String? remarks;
 final  List<SplitPayment>? _splitPayments;
@override List<SplitPayment>? get splitPayments {
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
 String? invoiceId, String? bookingId, String paymentMode, double amount, String? upiId, String? bankName, String? cardLast4, String? remarks, List<SplitPayment>? splitPayments
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
