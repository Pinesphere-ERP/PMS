// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kpi_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KpiSnapshotDto {

@JsonKey(name: 'snapshot_id') String get snapshotId;@JsonKey(name: 'property_id') String get propertyId;@JsonKey(name: 'snapshot_date') String get snapshotDate;@JsonKey(name: 'occupied_rooms') int get occupiedRooms;@JsonKey(name: 'vacant_rooms') int get vacantRooms;@JsonKey(name: 'revenue_room_rent') double get revenueRoomRent;@JsonKey(name: 'revenue_addons') double get revenueAddons;@JsonKey(name: 'expenses_amount') double get expensesAmount;@JsonKey(name: 'outstanding_payments') double get outstandingPayments;@JsonKey(name: 'gst_collected') double get gstCollected;
/// Create a copy of KpiSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KpiSnapshotDtoCopyWith<KpiSnapshotDto> get copyWith => _$KpiSnapshotDtoCopyWithImpl<KpiSnapshotDto>(this as KpiSnapshotDto, _$identity);

  /// Serializes this KpiSnapshotDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KpiSnapshotDto&&(identical(other.snapshotId, snapshotId) || other.snapshotId == snapshotId)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.snapshotDate, snapshotDate) || other.snapshotDate == snapshotDate)&&(identical(other.occupiedRooms, occupiedRooms) || other.occupiedRooms == occupiedRooms)&&(identical(other.vacantRooms, vacantRooms) || other.vacantRooms == vacantRooms)&&(identical(other.revenueRoomRent, revenueRoomRent) || other.revenueRoomRent == revenueRoomRent)&&(identical(other.revenueAddons, revenueAddons) || other.revenueAddons == revenueAddons)&&(identical(other.expensesAmount, expensesAmount) || other.expensesAmount == expensesAmount)&&(identical(other.outstandingPayments, outstandingPayments) || other.outstandingPayments == outstandingPayments)&&(identical(other.gstCollected, gstCollected) || other.gstCollected == gstCollected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,snapshotId,propertyId,snapshotDate,occupiedRooms,vacantRooms,revenueRoomRent,revenueAddons,expensesAmount,outstandingPayments,gstCollected);

@override
String toString() {
  return 'KpiSnapshotDto(snapshotId: $snapshotId, propertyId: $propertyId, snapshotDate: $snapshotDate, occupiedRooms: $occupiedRooms, vacantRooms: $vacantRooms, revenueRoomRent: $revenueRoomRent, revenueAddons: $revenueAddons, expensesAmount: $expensesAmount, outstandingPayments: $outstandingPayments, gstCollected: $gstCollected)';
}


}

/// @nodoc
abstract mixin class $KpiSnapshotDtoCopyWith<$Res>  {
  factory $KpiSnapshotDtoCopyWith(KpiSnapshotDto value, $Res Function(KpiSnapshotDto) _then) = _$KpiSnapshotDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'snapshot_id') String snapshotId,@JsonKey(name: 'property_id') String propertyId,@JsonKey(name: 'snapshot_date') String snapshotDate,@JsonKey(name: 'occupied_rooms') int occupiedRooms,@JsonKey(name: 'vacant_rooms') int vacantRooms,@JsonKey(name: 'revenue_room_rent') double revenueRoomRent,@JsonKey(name: 'revenue_addons') double revenueAddons,@JsonKey(name: 'expenses_amount') double expensesAmount,@JsonKey(name: 'outstanding_payments') double outstandingPayments,@JsonKey(name: 'gst_collected') double gstCollected
});




}
/// @nodoc
class _$KpiSnapshotDtoCopyWithImpl<$Res>
    implements $KpiSnapshotDtoCopyWith<$Res> {
  _$KpiSnapshotDtoCopyWithImpl(this._self, this._then);

  final KpiSnapshotDto _self;
  final $Res Function(KpiSnapshotDto) _then;

/// Create a copy of KpiSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? snapshotId = null,Object? propertyId = null,Object? snapshotDate = null,Object? occupiedRooms = null,Object? vacantRooms = null,Object? revenueRoomRent = null,Object? revenueAddons = null,Object? expensesAmount = null,Object? outstandingPayments = null,Object? gstCollected = null,}) {
  return _then(_self.copyWith(
snapshotId: null == snapshotId ? _self.snapshotId : snapshotId // ignore: cast_nullable_to_non_nullable
as String,propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,snapshotDate: null == snapshotDate ? _self.snapshotDate : snapshotDate // ignore: cast_nullable_to_non_nullable
as String,occupiedRooms: null == occupiedRooms ? _self.occupiedRooms : occupiedRooms // ignore: cast_nullable_to_non_nullable
as int,vacantRooms: null == vacantRooms ? _self.vacantRooms : vacantRooms // ignore: cast_nullable_to_non_nullable
as int,revenueRoomRent: null == revenueRoomRent ? _self.revenueRoomRent : revenueRoomRent // ignore: cast_nullable_to_non_nullable
as double,revenueAddons: null == revenueAddons ? _self.revenueAddons : revenueAddons // ignore: cast_nullable_to_non_nullable
as double,expensesAmount: null == expensesAmount ? _self.expensesAmount : expensesAmount // ignore: cast_nullable_to_non_nullable
as double,outstandingPayments: null == outstandingPayments ? _self.outstandingPayments : outstandingPayments // ignore: cast_nullable_to_non_nullable
as double,gstCollected: null == gstCollected ? _self.gstCollected : gstCollected // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [KpiSnapshotDto].
extension KpiSnapshotDtoPatterns on KpiSnapshotDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KpiSnapshotDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KpiSnapshotDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KpiSnapshotDto value)  $default,){
final _that = this;
switch (_that) {
case _KpiSnapshotDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KpiSnapshotDto value)?  $default,){
final _that = this;
switch (_that) {
case _KpiSnapshotDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'snapshot_id')  String snapshotId, @JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'snapshot_date')  String snapshotDate, @JsonKey(name: 'occupied_rooms')  int occupiedRooms, @JsonKey(name: 'vacant_rooms')  int vacantRooms, @JsonKey(name: 'revenue_room_rent')  double revenueRoomRent, @JsonKey(name: 'revenue_addons')  double revenueAddons, @JsonKey(name: 'expenses_amount')  double expensesAmount, @JsonKey(name: 'outstanding_payments')  double outstandingPayments, @JsonKey(name: 'gst_collected')  double gstCollected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KpiSnapshotDto() when $default != null:
return $default(_that.snapshotId,_that.propertyId,_that.snapshotDate,_that.occupiedRooms,_that.vacantRooms,_that.revenueRoomRent,_that.revenueAddons,_that.expensesAmount,_that.outstandingPayments,_that.gstCollected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'snapshot_id')  String snapshotId, @JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'snapshot_date')  String snapshotDate, @JsonKey(name: 'occupied_rooms')  int occupiedRooms, @JsonKey(name: 'vacant_rooms')  int vacantRooms, @JsonKey(name: 'revenue_room_rent')  double revenueRoomRent, @JsonKey(name: 'revenue_addons')  double revenueAddons, @JsonKey(name: 'expenses_amount')  double expensesAmount, @JsonKey(name: 'outstanding_payments')  double outstandingPayments, @JsonKey(name: 'gst_collected')  double gstCollected)  $default,) {final _that = this;
switch (_that) {
case _KpiSnapshotDto():
return $default(_that.snapshotId,_that.propertyId,_that.snapshotDate,_that.occupiedRooms,_that.vacantRooms,_that.revenueRoomRent,_that.revenueAddons,_that.expensesAmount,_that.outstandingPayments,_that.gstCollected);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'snapshot_id')  String snapshotId, @JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'snapshot_date')  String snapshotDate, @JsonKey(name: 'occupied_rooms')  int occupiedRooms, @JsonKey(name: 'vacant_rooms')  int vacantRooms, @JsonKey(name: 'revenue_room_rent')  double revenueRoomRent, @JsonKey(name: 'revenue_addons')  double revenueAddons, @JsonKey(name: 'expenses_amount')  double expensesAmount, @JsonKey(name: 'outstanding_payments')  double outstandingPayments, @JsonKey(name: 'gst_collected')  double gstCollected)?  $default,) {final _that = this;
switch (_that) {
case _KpiSnapshotDto() when $default != null:
return $default(_that.snapshotId,_that.propertyId,_that.snapshotDate,_that.occupiedRooms,_that.vacantRooms,_that.revenueRoomRent,_that.revenueAddons,_that.expensesAmount,_that.outstandingPayments,_that.gstCollected);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KpiSnapshotDto extends KpiSnapshotDto {
  const _KpiSnapshotDto({@JsonKey(name: 'snapshot_id') required this.snapshotId, @JsonKey(name: 'property_id') required this.propertyId, @JsonKey(name: 'snapshot_date') required this.snapshotDate, @JsonKey(name: 'occupied_rooms') required this.occupiedRooms, @JsonKey(name: 'vacant_rooms') required this.vacantRooms, @JsonKey(name: 'revenue_room_rent') required this.revenueRoomRent, @JsonKey(name: 'revenue_addons') required this.revenueAddons, @JsonKey(name: 'expenses_amount') required this.expensesAmount, @JsonKey(name: 'outstanding_payments') required this.outstandingPayments, @JsonKey(name: 'gst_collected') required this.gstCollected}): super._();
  factory _KpiSnapshotDto.fromJson(Map<String, dynamic> json) => _$KpiSnapshotDtoFromJson(json);

@override@JsonKey(name: 'snapshot_id') final  String snapshotId;
@override@JsonKey(name: 'property_id') final  String propertyId;
@override@JsonKey(name: 'snapshot_date') final  String snapshotDate;
@override@JsonKey(name: 'occupied_rooms') final  int occupiedRooms;
@override@JsonKey(name: 'vacant_rooms') final  int vacantRooms;
@override@JsonKey(name: 'revenue_room_rent') final  double revenueRoomRent;
@override@JsonKey(name: 'revenue_addons') final  double revenueAddons;
@override@JsonKey(name: 'expenses_amount') final  double expensesAmount;
@override@JsonKey(name: 'outstanding_payments') final  double outstandingPayments;
@override@JsonKey(name: 'gst_collected') final  double gstCollected;

/// Create a copy of KpiSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KpiSnapshotDtoCopyWith<_KpiSnapshotDto> get copyWith => __$KpiSnapshotDtoCopyWithImpl<_KpiSnapshotDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KpiSnapshotDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KpiSnapshotDto&&(identical(other.snapshotId, snapshotId) || other.snapshotId == snapshotId)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.snapshotDate, snapshotDate) || other.snapshotDate == snapshotDate)&&(identical(other.occupiedRooms, occupiedRooms) || other.occupiedRooms == occupiedRooms)&&(identical(other.vacantRooms, vacantRooms) || other.vacantRooms == vacantRooms)&&(identical(other.revenueRoomRent, revenueRoomRent) || other.revenueRoomRent == revenueRoomRent)&&(identical(other.revenueAddons, revenueAddons) || other.revenueAddons == revenueAddons)&&(identical(other.expensesAmount, expensesAmount) || other.expensesAmount == expensesAmount)&&(identical(other.outstandingPayments, outstandingPayments) || other.outstandingPayments == outstandingPayments)&&(identical(other.gstCollected, gstCollected) || other.gstCollected == gstCollected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,snapshotId,propertyId,snapshotDate,occupiedRooms,vacantRooms,revenueRoomRent,revenueAddons,expensesAmount,outstandingPayments,gstCollected);

@override
String toString() {
  return 'KpiSnapshotDto(snapshotId: $snapshotId, propertyId: $propertyId, snapshotDate: $snapshotDate, occupiedRooms: $occupiedRooms, vacantRooms: $vacantRooms, revenueRoomRent: $revenueRoomRent, revenueAddons: $revenueAddons, expensesAmount: $expensesAmount, outstandingPayments: $outstandingPayments, gstCollected: $gstCollected)';
}


}

/// @nodoc
abstract mixin class _$KpiSnapshotDtoCopyWith<$Res> implements $KpiSnapshotDtoCopyWith<$Res> {
  factory _$KpiSnapshotDtoCopyWith(_KpiSnapshotDto value, $Res Function(_KpiSnapshotDto) _then) = __$KpiSnapshotDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'snapshot_id') String snapshotId,@JsonKey(name: 'property_id') String propertyId,@JsonKey(name: 'snapshot_date') String snapshotDate,@JsonKey(name: 'occupied_rooms') int occupiedRooms,@JsonKey(name: 'vacant_rooms') int vacantRooms,@JsonKey(name: 'revenue_room_rent') double revenueRoomRent,@JsonKey(name: 'revenue_addons') double revenueAddons,@JsonKey(name: 'expenses_amount') double expensesAmount,@JsonKey(name: 'outstanding_payments') double outstandingPayments,@JsonKey(name: 'gst_collected') double gstCollected
});




}
/// @nodoc
class __$KpiSnapshotDtoCopyWithImpl<$Res>
    implements _$KpiSnapshotDtoCopyWith<$Res> {
  __$KpiSnapshotDtoCopyWithImpl(this._self, this._then);

  final _KpiSnapshotDto _self;
  final $Res Function(_KpiSnapshotDto) _then;

/// Create a copy of KpiSnapshotDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? snapshotId = null,Object? propertyId = null,Object? snapshotDate = null,Object? occupiedRooms = null,Object? vacantRooms = null,Object? revenueRoomRent = null,Object? revenueAddons = null,Object? expensesAmount = null,Object? outstandingPayments = null,Object? gstCollected = null,}) {
  return _then(_KpiSnapshotDto(
snapshotId: null == snapshotId ? _self.snapshotId : snapshotId // ignore: cast_nullable_to_non_nullable
as String,propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,snapshotDate: null == snapshotDate ? _self.snapshotDate : snapshotDate // ignore: cast_nullable_to_non_nullable
as String,occupiedRooms: null == occupiedRooms ? _self.occupiedRooms : occupiedRooms // ignore: cast_nullable_to_non_nullable
as int,vacantRooms: null == vacantRooms ? _self.vacantRooms : vacantRooms // ignore: cast_nullable_to_non_nullable
as int,revenueRoomRent: null == revenueRoomRent ? _self.revenueRoomRent : revenueRoomRent // ignore: cast_nullable_to_non_nullable
as double,revenueAddons: null == revenueAddons ? _self.revenueAddons : revenueAddons // ignore: cast_nullable_to_non_nullable
as double,expensesAmount: null == expensesAmount ? _self.expensesAmount : expensesAmount // ignore: cast_nullable_to_non_nullable
as double,outstandingPayments: null == outstandingPayments ? _self.outstandingPayments : outstandingPayments // ignore: cast_nullable_to_non_nullable
as double,gstCollected: null == gstCollected ? _self.gstCollected : gstCollected // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$MonthlyPLRowDto {

 String get month;@JsonKey(name: 'total_room_rent') double get totalRoomRent;@JsonKey(name: 'total_addons') double get totalAddons;@JsonKey(name: 'total_revenue') double get totalRevenue;@JsonKey(name: 'total_expenses') double get totalExpenses;@JsonKey(name: 'net_profit') double get netProfit;@JsonKey(name: 'gst_collected') double get gstCollected; double get outstanding;
/// Create a copy of MonthlyPLRowDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthlyPLRowDtoCopyWith<MonthlyPLRowDto> get copyWith => _$MonthlyPLRowDtoCopyWithImpl<MonthlyPLRowDto>(this as MonthlyPLRowDto, _$identity);

  /// Serializes this MonthlyPLRowDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthlyPLRowDto&&(identical(other.month, month) || other.month == month)&&(identical(other.totalRoomRent, totalRoomRent) || other.totalRoomRent == totalRoomRent)&&(identical(other.totalAddons, totalAddons) || other.totalAddons == totalAddons)&&(identical(other.totalRevenue, totalRevenue) || other.totalRevenue == totalRevenue)&&(identical(other.totalExpenses, totalExpenses) || other.totalExpenses == totalExpenses)&&(identical(other.netProfit, netProfit) || other.netProfit == netProfit)&&(identical(other.gstCollected, gstCollected) || other.gstCollected == gstCollected)&&(identical(other.outstanding, outstanding) || other.outstanding == outstanding));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,totalRoomRent,totalAddons,totalRevenue,totalExpenses,netProfit,gstCollected,outstanding);

@override
String toString() {
  return 'MonthlyPLRowDto(month: $month, totalRoomRent: $totalRoomRent, totalAddons: $totalAddons, totalRevenue: $totalRevenue, totalExpenses: $totalExpenses, netProfit: $netProfit, gstCollected: $gstCollected, outstanding: $outstanding)';
}


}

/// @nodoc
abstract mixin class $MonthlyPLRowDtoCopyWith<$Res>  {
  factory $MonthlyPLRowDtoCopyWith(MonthlyPLRowDto value, $Res Function(MonthlyPLRowDto) _then) = _$MonthlyPLRowDtoCopyWithImpl;
@useResult
$Res call({
 String month,@JsonKey(name: 'total_room_rent') double totalRoomRent,@JsonKey(name: 'total_addons') double totalAddons,@JsonKey(name: 'total_revenue') double totalRevenue,@JsonKey(name: 'total_expenses') double totalExpenses,@JsonKey(name: 'net_profit') double netProfit,@JsonKey(name: 'gst_collected') double gstCollected, double outstanding
});




}
/// @nodoc
class _$MonthlyPLRowDtoCopyWithImpl<$Res>
    implements $MonthlyPLRowDtoCopyWith<$Res> {
  _$MonthlyPLRowDtoCopyWithImpl(this._self, this._then);

  final MonthlyPLRowDto _self;
  final $Res Function(MonthlyPLRowDto) _then;

/// Create a copy of MonthlyPLRowDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? totalRoomRent = null,Object? totalAddons = null,Object? totalRevenue = null,Object? totalExpenses = null,Object? netProfit = null,Object? gstCollected = null,Object? outstanding = null,}) {
  return _then(_self.copyWith(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,totalRoomRent: null == totalRoomRent ? _self.totalRoomRent : totalRoomRent // ignore: cast_nullable_to_non_nullable
as double,totalAddons: null == totalAddons ? _self.totalAddons : totalAddons // ignore: cast_nullable_to_non_nullable
as double,totalRevenue: null == totalRevenue ? _self.totalRevenue : totalRevenue // ignore: cast_nullable_to_non_nullable
as double,totalExpenses: null == totalExpenses ? _self.totalExpenses : totalExpenses // ignore: cast_nullable_to_non_nullable
as double,netProfit: null == netProfit ? _self.netProfit : netProfit // ignore: cast_nullable_to_non_nullable
as double,gstCollected: null == gstCollected ? _self.gstCollected : gstCollected // ignore: cast_nullable_to_non_nullable
as double,outstanding: null == outstanding ? _self.outstanding : outstanding // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthlyPLRowDto].
extension MonthlyPLRowDtoPatterns on MonthlyPLRowDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthlyPLRowDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthlyPLRowDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthlyPLRowDto value)  $default,){
final _that = this;
switch (_that) {
case _MonthlyPLRowDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthlyPLRowDto value)?  $default,){
final _that = this;
switch (_that) {
case _MonthlyPLRowDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String month, @JsonKey(name: 'total_room_rent')  double totalRoomRent, @JsonKey(name: 'total_addons')  double totalAddons, @JsonKey(name: 'total_revenue')  double totalRevenue, @JsonKey(name: 'total_expenses')  double totalExpenses, @JsonKey(name: 'net_profit')  double netProfit, @JsonKey(name: 'gst_collected')  double gstCollected,  double outstanding)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthlyPLRowDto() when $default != null:
return $default(_that.month,_that.totalRoomRent,_that.totalAddons,_that.totalRevenue,_that.totalExpenses,_that.netProfit,_that.gstCollected,_that.outstanding);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String month, @JsonKey(name: 'total_room_rent')  double totalRoomRent, @JsonKey(name: 'total_addons')  double totalAddons, @JsonKey(name: 'total_revenue')  double totalRevenue, @JsonKey(name: 'total_expenses')  double totalExpenses, @JsonKey(name: 'net_profit')  double netProfit, @JsonKey(name: 'gst_collected')  double gstCollected,  double outstanding)  $default,) {final _that = this;
switch (_that) {
case _MonthlyPLRowDto():
return $default(_that.month,_that.totalRoomRent,_that.totalAddons,_that.totalRevenue,_that.totalExpenses,_that.netProfit,_that.gstCollected,_that.outstanding);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String month, @JsonKey(name: 'total_room_rent')  double totalRoomRent, @JsonKey(name: 'total_addons')  double totalAddons, @JsonKey(name: 'total_revenue')  double totalRevenue, @JsonKey(name: 'total_expenses')  double totalExpenses, @JsonKey(name: 'net_profit')  double netProfit, @JsonKey(name: 'gst_collected')  double gstCollected,  double outstanding)?  $default,) {final _that = this;
switch (_that) {
case _MonthlyPLRowDto() when $default != null:
return $default(_that.month,_that.totalRoomRent,_that.totalAddons,_that.totalRevenue,_that.totalExpenses,_that.netProfit,_that.gstCollected,_that.outstanding);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MonthlyPLRowDto extends MonthlyPLRowDto {
  const _MonthlyPLRowDto({required this.month, @JsonKey(name: 'total_room_rent') required this.totalRoomRent, @JsonKey(name: 'total_addons') required this.totalAddons, @JsonKey(name: 'total_revenue') required this.totalRevenue, @JsonKey(name: 'total_expenses') required this.totalExpenses, @JsonKey(name: 'net_profit') required this.netProfit, @JsonKey(name: 'gst_collected') required this.gstCollected, required this.outstanding}): super._();
  factory _MonthlyPLRowDto.fromJson(Map<String, dynamic> json) => _$MonthlyPLRowDtoFromJson(json);

@override final  String month;
@override@JsonKey(name: 'total_room_rent') final  double totalRoomRent;
@override@JsonKey(name: 'total_addons') final  double totalAddons;
@override@JsonKey(name: 'total_revenue') final  double totalRevenue;
@override@JsonKey(name: 'total_expenses') final  double totalExpenses;
@override@JsonKey(name: 'net_profit') final  double netProfit;
@override@JsonKey(name: 'gst_collected') final  double gstCollected;
@override final  double outstanding;

/// Create a copy of MonthlyPLRowDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthlyPLRowDtoCopyWith<_MonthlyPLRowDto> get copyWith => __$MonthlyPLRowDtoCopyWithImpl<_MonthlyPLRowDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MonthlyPLRowDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthlyPLRowDto&&(identical(other.month, month) || other.month == month)&&(identical(other.totalRoomRent, totalRoomRent) || other.totalRoomRent == totalRoomRent)&&(identical(other.totalAddons, totalAddons) || other.totalAddons == totalAddons)&&(identical(other.totalRevenue, totalRevenue) || other.totalRevenue == totalRevenue)&&(identical(other.totalExpenses, totalExpenses) || other.totalExpenses == totalExpenses)&&(identical(other.netProfit, netProfit) || other.netProfit == netProfit)&&(identical(other.gstCollected, gstCollected) || other.gstCollected == gstCollected)&&(identical(other.outstanding, outstanding) || other.outstanding == outstanding));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,totalRoomRent,totalAddons,totalRevenue,totalExpenses,netProfit,gstCollected,outstanding);

@override
String toString() {
  return 'MonthlyPLRowDto(month: $month, totalRoomRent: $totalRoomRent, totalAddons: $totalAddons, totalRevenue: $totalRevenue, totalExpenses: $totalExpenses, netProfit: $netProfit, gstCollected: $gstCollected, outstanding: $outstanding)';
}


}

/// @nodoc
abstract mixin class _$MonthlyPLRowDtoCopyWith<$Res> implements $MonthlyPLRowDtoCopyWith<$Res> {
  factory _$MonthlyPLRowDtoCopyWith(_MonthlyPLRowDto value, $Res Function(_MonthlyPLRowDto) _then) = __$MonthlyPLRowDtoCopyWithImpl;
@override @useResult
$Res call({
 String month,@JsonKey(name: 'total_room_rent') double totalRoomRent,@JsonKey(name: 'total_addons') double totalAddons,@JsonKey(name: 'total_revenue') double totalRevenue,@JsonKey(name: 'total_expenses') double totalExpenses,@JsonKey(name: 'net_profit') double netProfit,@JsonKey(name: 'gst_collected') double gstCollected, double outstanding
});




}
/// @nodoc
class __$MonthlyPLRowDtoCopyWithImpl<$Res>
    implements _$MonthlyPLRowDtoCopyWith<$Res> {
  __$MonthlyPLRowDtoCopyWithImpl(this._self, this._then);

  final _MonthlyPLRowDto _self;
  final $Res Function(_MonthlyPLRowDto) _then;

/// Create a copy of MonthlyPLRowDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? totalRoomRent = null,Object? totalAddons = null,Object? totalRevenue = null,Object? totalExpenses = null,Object? netProfit = null,Object? gstCollected = null,Object? outstanding = null,}) {
  return _then(_MonthlyPLRowDto(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,totalRoomRent: null == totalRoomRent ? _self.totalRoomRent : totalRoomRent // ignore: cast_nullable_to_non_nullable
as double,totalAddons: null == totalAddons ? _self.totalAddons : totalAddons // ignore: cast_nullable_to_non_nullable
as double,totalRevenue: null == totalRevenue ? _self.totalRevenue : totalRevenue // ignore: cast_nullable_to_non_nullable
as double,totalExpenses: null == totalExpenses ? _self.totalExpenses : totalExpenses // ignore: cast_nullable_to_non_nullable
as double,netProfit: null == netProfit ? _self.netProfit : netProfit // ignore: cast_nullable_to_non_nullable
as double,gstCollected: null == gstCollected ? _self.gstCollected : gstCollected // ignore: cast_nullable_to_non_nullable
as double,outstanding: null == outstanding ? _self.outstanding : outstanding // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$PLReportDto {

@JsonKey(name: 'property_id') String get propertyId;@JsonKey(name: 'period_start') String get periodStart;@JsonKey(name: 'period_end') String get periodEnd;@JsonKey(name: 'monthly_breakdown') List<MonthlyPLRowDto> get monthlyBreakdown;@JsonKey(name: 'summary_total_revenue') double get summaryTotalRevenue;@JsonKey(name: 'summary_total_expenses') double get summaryTotalExpenses;@JsonKey(name: 'summary_net_profit') double get summaryNetProfit;
/// Create a copy of PLReportDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PLReportDtoCopyWith<PLReportDto> get copyWith => _$PLReportDtoCopyWithImpl<PLReportDto>(this as PLReportDto, _$identity);

  /// Serializes this PLReportDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PLReportDto&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&const DeepCollectionEquality().equals(other.monthlyBreakdown, monthlyBreakdown)&&(identical(other.summaryTotalRevenue, summaryTotalRevenue) || other.summaryTotalRevenue == summaryTotalRevenue)&&(identical(other.summaryTotalExpenses, summaryTotalExpenses) || other.summaryTotalExpenses == summaryTotalExpenses)&&(identical(other.summaryNetProfit, summaryNetProfit) || other.summaryNetProfit == summaryNetProfit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,propertyId,periodStart,periodEnd,const DeepCollectionEquality().hash(monthlyBreakdown),summaryTotalRevenue,summaryTotalExpenses,summaryNetProfit);

@override
String toString() {
  return 'PLReportDto(propertyId: $propertyId, periodStart: $periodStart, periodEnd: $periodEnd, monthlyBreakdown: $monthlyBreakdown, summaryTotalRevenue: $summaryTotalRevenue, summaryTotalExpenses: $summaryTotalExpenses, summaryNetProfit: $summaryNetProfit)';
}


}

/// @nodoc
abstract mixin class $PLReportDtoCopyWith<$Res>  {
  factory $PLReportDtoCopyWith(PLReportDto value, $Res Function(PLReportDto) _then) = _$PLReportDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'property_id') String propertyId,@JsonKey(name: 'period_start') String periodStart,@JsonKey(name: 'period_end') String periodEnd,@JsonKey(name: 'monthly_breakdown') List<MonthlyPLRowDto> monthlyBreakdown,@JsonKey(name: 'summary_total_revenue') double summaryTotalRevenue,@JsonKey(name: 'summary_total_expenses') double summaryTotalExpenses,@JsonKey(name: 'summary_net_profit') double summaryNetProfit
});




}
/// @nodoc
class _$PLReportDtoCopyWithImpl<$Res>
    implements $PLReportDtoCopyWith<$Res> {
  _$PLReportDtoCopyWithImpl(this._self, this._then);

  final PLReportDto _self;
  final $Res Function(PLReportDto) _then;

/// Create a copy of PLReportDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? propertyId = null,Object? periodStart = null,Object? periodEnd = null,Object? monthlyBreakdown = null,Object? summaryTotalRevenue = null,Object? summaryTotalExpenses = null,Object? summaryNetProfit = null,}) {
  return _then(_self.copyWith(
propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as String,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as String,monthlyBreakdown: null == monthlyBreakdown ? _self.monthlyBreakdown : monthlyBreakdown // ignore: cast_nullable_to_non_nullable
as List<MonthlyPLRowDto>,summaryTotalRevenue: null == summaryTotalRevenue ? _self.summaryTotalRevenue : summaryTotalRevenue // ignore: cast_nullable_to_non_nullable
as double,summaryTotalExpenses: null == summaryTotalExpenses ? _self.summaryTotalExpenses : summaryTotalExpenses // ignore: cast_nullable_to_non_nullable
as double,summaryNetProfit: null == summaryNetProfit ? _self.summaryNetProfit : summaryNetProfit // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PLReportDto].
extension PLReportDtoPatterns on PLReportDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PLReportDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PLReportDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PLReportDto value)  $default,){
final _that = this;
switch (_that) {
case _PLReportDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PLReportDto value)?  $default,){
final _that = this;
switch (_that) {
case _PLReportDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'period_start')  String periodStart, @JsonKey(name: 'period_end')  String periodEnd, @JsonKey(name: 'monthly_breakdown')  List<MonthlyPLRowDto> monthlyBreakdown, @JsonKey(name: 'summary_total_revenue')  double summaryTotalRevenue, @JsonKey(name: 'summary_total_expenses')  double summaryTotalExpenses, @JsonKey(name: 'summary_net_profit')  double summaryNetProfit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PLReportDto() when $default != null:
return $default(_that.propertyId,_that.periodStart,_that.periodEnd,_that.monthlyBreakdown,_that.summaryTotalRevenue,_that.summaryTotalExpenses,_that.summaryNetProfit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'period_start')  String periodStart, @JsonKey(name: 'period_end')  String periodEnd, @JsonKey(name: 'monthly_breakdown')  List<MonthlyPLRowDto> monthlyBreakdown, @JsonKey(name: 'summary_total_revenue')  double summaryTotalRevenue, @JsonKey(name: 'summary_total_expenses')  double summaryTotalExpenses, @JsonKey(name: 'summary_net_profit')  double summaryNetProfit)  $default,) {final _that = this;
switch (_that) {
case _PLReportDto():
return $default(_that.propertyId,_that.periodStart,_that.periodEnd,_that.monthlyBreakdown,_that.summaryTotalRevenue,_that.summaryTotalExpenses,_that.summaryNetProfit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'period_start')  String periodStart, @JsonKey(name: 'period_end')  String periodEnd, @JsonKey(name: 'monthly_breakdown')  List<MonthlyPLRowDto> monthlyBreakdown, @JsonKey(name: 'summary_total_revenue')  double summaryTotalRevenue, @JsonKey(name: 'summary_total_expenses')  double summaryTotalExpenses, @JsonKey(name: 'summary_net_profit')  double summaryNetProfit)?  $default,) {final _that = this;
switch (_that) {
case _PLReportDto() when $default != null:
return $default(_that.propertyId,_that.periodStart,_that.periodEnd,_that.monthlyBreakdown,_that.summaryTotalRevenue,_that.summaryTotalExpenses,_that.summaryNetProfit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PLReportDto extends PLReportDto {
  const _PLReportDto({@JsonKey(name: 'property_id') required this.propertyId, @JsonKey(name: 'period_start') required this.periodStart, @JsonKey(name: 'period_end') required this.periodEnd, @JsonKey(name: 'monthly_breakdown') required final  List<MonthlyPLRowDto> monthlyBreakdown, @JsonKey(name: 'summary_total_revenue') required this.summaryTotalRevenue, @JsonKey(name: 'summary_total_expenses') required this.summaryTotalExpenses, @JsonKey(name: 'summary_net_profit') required this.summaryNetProfit}): _monthlyBreakdown = monthlyBreakdown,super._();
  factory _PLReportDto.fromJson(Map<String, dynamic> json) => _$PLReportDtoFromJson(json);

@override@JsonKey(name: 'property_id') final  String propertyId;
@override@JsonKey(name: 'period_start') final  String periodStart;
@override@JsonKey(name: 'period_end') final  String periodEnd;
 final  List<MonthlyPLRowDto> _monthlyBreakdown;
@override@JsonKey(name: 'monthly_breakdown') List<MonthlyPLRowDto> get monthlyBreakdown {
  if (_monthlyBreakdown is EqualUnmodifiableListView) return _monthlyBreakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_monthlyBreakdown);
}

@override@JsonKey(name: 'summary_total_revenue') final  double summaryTotalRevenue;
@override@JsonKey(name: 'summary_total_expenses') final  double summaryTotalExpenses;
@override@JsonKey(name: 'summary_net_profit') final  double summaryNetProfit;

/// Create a copy of PLReportDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PLReportDtoCopyWith<_PLReportDto> get copyWith => __$PLReportDtoCopyWithImpl<_PLReportDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PLReportDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PLReportDto&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&const DeepCollectionEquality().equals(other._monthlyBreakdown, _monthlyBreakdown)&&(identical(other.summaryTotalRevenue, summaryTotalRevenue) || other.summaryTotalRevenue == summaryTotalRevenue)&&(identical(other.summaryTotalExpenses, summaryTotalExpenses) || other.summaryTotalExpenses == summaryTotalExpenses)&&(identical(other.summaryNetProfit, summaryNetProfit) || other.summaryNetProfit == summaryNetProfit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,propertyId,periodStart,periodEnd,const DeepCollectionEquality().hash(_monthlyBreakdown),summaryTotalRevenue,summaryTotalExpenses,summaryNetProfit);

@override
String toString() {
  return 'PLReportDto(propertyId: $propertyId, periodStart: $periodStart, periodEnd: $periodEnd, monthlyBreakdown: $monthlyBreakdown, summaryTotalRevenue: $summaryTotalRevenue, summaryTotalExpenses: $summaryTotalExpenses, summaryNetProfit: $summaryNetProfit)';
}


}

/// @nodoc
abstract mixin class _$PLReportDtoCopyWith<$Res> implements $PLReportDtoCopyWith<$Res> {
  factory _$PLReportDtoCopyWith(_PLReportDto value, $Res Function(_PLReportDto) _then) = __$PLReportDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'property_id') String propertyId,@JsonKey(name: 'period_start') String periodStart,@JsonKey(name: 'period_end') String periodEnd,@JsonKey(name: 'monthly_breakdown') List<MonthlyPLRowDto> monthlyBreakdown,@JsonKey(name: 'summary_total_revenue') double summaryTotalRevenue,@JsonKey(name: 'summary_total_expenses') double summaryTotalExpenses,@JsonKey(name: 'summary_net_profit') double summaryNetProfit
});




}
/// @nodoc
class __$PLReportDtoCopyWithImpl<$Res>
    implements _$PLReportDtoCopyWith<$Res> {
  __$PLReportDtoCopyWithImpl(this._self, this._then);

  final _PLReportDto _self;
  final $Res Function(_PLReportDto) _then;

/// Create a copy of PLReportDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? propertyId = null,Object? periodStart = null,Object? periodEnd = null,Object? monthlyBreakdown = null,Object? summaryTotalRevenue = null,Object? summaryTotalExpenses = null,Object? summaryNetProfit = null,}) {
  return _then(_PLReportDto(
propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as String,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as String,monthlyBreakdown: null == monthlyBreakdown ? _self._monthlyBreakdown : monthlyBreakdown // ignore: cast_nullable_to_non_nullable
as List<MonthlyPLRowDto>,summaryTotalRevenue: null == summaryTotalRevenue ? _self.summaryTotalRevenue : summaryTotalRevenue // ignore: cast_nullable_to_non_nullable
as double,summaryTotalExpenses: null == summaryTotalExpenses ? _self.summaryTotalExpenses : summaryTotalExpenses // ignore: cast_nullable_to_non_nullable
as double,summaryNetProfit: null == summaryNetProfit ? _self.summaryNetProfit : summaryNetProfit // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$GSTReturnDto {

@JsonKey(name: 'property_id') String get propertyId;@JsonKey(name: 'period_start') String get periodStart;@JsonKey(name: 'period_end') String get periodEnd;@JsonKey(name: 'total_taxable_revenue') double get totalTaxableRevenue;@JsonKey(name: 'total_gst_collected') double get totalGstCollected; double get cgst; double get sgst; double get igst;@JsonKey(name: 'monthly_gst') List<Map<String, dynamic>> get monthlyGst;
/// Create a copy of GSTReturnDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GSTReturnDtoCopyWith<GSTReturnDto> get copyWith => _$GSTReturnDtoCopyWithImpl<GSTReturnDto>(this as GSTReturnDto, _$identity);

  /// Serializes this GSTReturnDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GSTReturnDto&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&(identical(other.totalTaxableRevenue, totalTaxableRevenue) || other.totalTaxableRevenue == totalTaxableRevenue)&&(identical(other.totalGstCollected, totalGstCollected) || other.totalGstCollected == totalGstCollected)&&(identical(other.cgst, cgst) || other.cgst == cgst)&&(identical(other.sgst, sgst) || other.sgst == sgst)&&(identical(other.igst, igst) || other.igst == igst)&&const DeepCollectionEquality().equals(other.monthlyGst, monthlyGst));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,propertyId,periodStart,periodEnd,totalTaxableRevenue,totalGstCollected,cgst,sgst,igst,const DeepCollectionEquality().hash(monthlyGst));

@override
String toString() {
  return 'GSTReturnDto(propertyId: $propertyId, periodStart: $periodStart, periodEnd: $periodEnd, totalTaxableRevenue: $totalTaxableRevenue, totalGstCollected: $totalGstCollected, cgst: $cgst, sgst: $sgst, igst: $igst, monthlyGst: $monthlyGst)';
}


}

/// @nodoc
abstract mixin class $GSTReturnDtoCopyWith<$Res>  {
  factory $GSTReturnDtoCopyWith(GSTReturnDto value, $Res Function(GSTReturnDto) _then) = _$GSTReturnDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'property_id') String propertyId,@JsonKey(name: 'period_start') String periodStart,@JsonKey(name: 'period_end') String periodEnd,@JsonKey(name: 'total_taxable_revenue') double totalTaxableRevenue,@JsonKey(name: 'total_gst_collected') double totalGstCollected, double cgst, double sgst, double igst,@JsonKey(name: 'monthly_gst') List<Map<String, dynamic>> monthlyGst
});




}
/// @nodoc
class _$GSTReturnDtoCopyWithImpl<$Res>
    implements $GSTReturnDtoCopyWith<$Res> {
  _$GSTReturnDtoCopyWithImpl(this._self, this._then);

  final GSTReturnDto _self;
  final $Res Function(GSTReturnDto) _then;

/// Create a copy of GSTReturnDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? propertyId = null,Object? periodStart = null,Object? periodEnd = null,Object? totalTaxableRevenue = null,Object? totalGstCollected = null,Object? cgst = null,Object? sgst = null,Object? igst = null,Object? monthlyGst = null,}) {
  return _then(_self.copyWith(
propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as String,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as String,totalTaxableRevenue: null == totalTaxableRevenue ? _self.totalTaxableRevenue : totalTaxableRevenue // ignore: cast_nullable_to_non_nullable
as double,totalGstCollected: null == totalGstCollected ? _self.totalGstCollected : totalGstCollected // ignore: cast_nullable_to_non_nullable
as double,cgst: null == cgst ? _self.cgst : cgst // ignore: cast_nullable_to_non_nullable
as double,sgst: null == sgst ? _self.sgst : sgst // ignore: cast_nullable_to_non_nullable
as double,igst: null == igst ? _self.igst : igst // ignore: cast_nullable_to_non_nullable
as double,monthlyGst: null == monthlyGst ? _self.monthlyGst : monthlyGst // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}

}


/// Adds pattern-matching-related methods to [GSTReturnDto].
extension GSTReturnDtoPatterns on GSTReturnDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GSTReturnDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GSTReturnDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GSTReturnDto value)  $default,){
final _that = this;
switch (_that) {
case _GSTReturnDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GSTReturnDto value)?  $default,){
final _that = this;
switch (_that) {
case _GSTReturnDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'period_start')  String periodStart, @JsonKey(name: 'period_end')  String periodEnd, @JsonKey(name: 'total_taxable_revenue')  double totalTaxableRevenue, @JsonKey(name: 'total_gst_collected')  double totalGstCollected,  double cgst,  double sgst,  double igst, @JsonKey(name: 'monthly_gst')  List<Map<String, dynamic>> monthlyGst)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GSTReturnDto() when $default != null:
return $default(_that.propertyId,_that.periodStart,_that.periodEnd,_that.totalTaxableRevenue,_that.totalGstCollected,_that.cgst,_that.sgst,_that.igst,_that.monthlyGst);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'period_start')  String periodStart, @JsonKey(name: 'period_end')  String periodEnd, @JsonKey(name: 'total_taxable_revenue')  double totalTaxableRevenue, @JsonKey(name: 'total_gst_collected')  double totalGstCollected,  double cgst,  double sgst,  double igst, @JsonKey(name: 'monthly_gst')  List<Map<String, dynamic>> monthlyGst)  $default,) {final _that = this;
switch (_that) {
case _GSTReturnDto():
return $default(_that.propertyId,_that.periodStart,_that.periodEnd,_that.totalTaxableRevenue,_that.totalGstCollected,_that.cgst,_that.sgst,_that.igst,_that.monthlyGst);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'property_id')  String propertyId, @JsonKey(name: 'period_start')  String periodStart, @JsonKey(name: 'period_end')  String periodEnd, @JsonKey(name: 'total_taxable_revenue')  double totalTaxableRevenue, @JsonKey(name: 'total_gst_collected')  double totalGstCollected,  double cgst,  double sgst,  double igst, @JsonKey(name: 'monthly_gst')  List<Map<String, dynamic>> monthlyGst)?  $default,) {final _that = this;
switch (_that) {
case _GSTReturnDto() when $default != null:
return $default(_that.propertyId,_that.periodStart,_that.periodEnd,_that.totalTaxableRevenue,_that.totalGstCollected,_that.cgst,_that.sgst,_that.igst,_that.monthlyGst);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GSTReturnDto extends GSTReturnDto {
  const _GSTReturnDto({@JsonKey(name: 'property_id') required this.propertyId, @JsonKey(name: 'period_start') required this.periodStart, @JsonKey(name: 'period_end') required this.periodEnd, @JsonKey(name: 'total_taxable_revenue') required this.totalTaxableRevenue, @JsonKey(name: 'total_gst_collected') required this.totalGstCollected, required this.cgst, required this.sgst, required this.igst, @JsonKey(name: 'monthly_gst') required final  List<Map<String, dynamic>> monthlyGst}): _monthlyGst = monthlyGst,super._();
  factory _GSTReturnDto.fromJson(Map<String, dynamic> json) => _$GSTReturnDtoFromJson(json);

@override@JsonKey(name: 'property_id') final  String propertyId;
@override@JsonKey(name: 'period_start') final  String periodStart;
@override@JsonKey(name: 'period_end') final  String periodEnd;
@override@JsonKey(name: 'total_taxable_revenue') final  double totalTaxableRevenue;
@override@JsonKey(name: 'total_gst_collected') final  double totalGstCollected;
@override final  double cgst;
@override final  double sgst;
@override final  double igst;
 final  List<Map<String, dynamic>> _monthlyGst;
@override@JsonKey(name: 'monthly_gst') List<Map<String, dynamic>> get monthlyGst {
  if (_monthlyGst is EqualUnmodifiableListView) return _monthlyGst;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_monthlyGst);
}


/// Create a copy of GSTReturnDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GSTReturnDtoCopyWith<_GSTReturnDto> get copyWith => __$GSTReturnDtoCopyWithImpl<_GSTReturnDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GSTReturnDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GSTReturnDto&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&(identical(other.totalTaxableRevenue, totalTaxableRevenue) || other.totalTaxableRevenue == totalTaxableRevenue)&&(identical(other.totalGstCollected, totalGstCollected) || other.totalGstCollected == totalGstCollected)&&(identical(other.cgst, cgst) || other.cgst == cgst)&&(identical(other.sgst, sgst) || other.sgst == sgst)&&(identical(other.igst, igst) || other.igst == igst)&&const DeepCollectionEquality().equals(other._monthlyGst, _monthlyGst));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,propertyId,periodStart,periodEnd,totalTaxableRevenue,totalGstCollected,cgst,sgst,igst,const DeepCollectionEquality().hash(_monthlyGst));

@override
String toString() {
  return 'GSTReturnDto(propertyId: $propertyId, periodStart: $periodStart, periodEnd: $periodEnd, totalTaxableRevenue: $totalTaxableRevenue, totalGstCollected: $totalGstCollected, cgst: $cgst, sgst: $sgst, igst: $igst, monthlyGst: $monthlyGst)';
}


}

/// @nodoc
abstract mixin class _$GSTReturnDtoCopyWith<$Res> implements $GSTReturnDtoCopyWith<$Res> {
  factory _$GSTReturnDtoCopyWith(_GSTReturnDto value, $Res Function(_GSTReturnDto) _then) = __$GSTReturnDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'property_id') String propertyId,@JsonKey(name: 'period_start') String periodStart,@JsonKey(name: 'period_end') String periodEnd,@JsonKey(name: 'total_taxable_revenue') double totalTaxableRevenue,@JsonKey(name: 'total_gst_collected') double totalGstCollected, double cgst, double sgst, double igst,@JsonKey(name: 'monthly_gst') List<Map<String, dynamic>> monthlyGst
});




}
/// @nodoc
class __$GSTReturnDtoCopyWithImpl<$Res>
    implements _$GSTReturnDtoCopyWith<$Res> {
  __$GSTReturnDtoCopyWithImpl(this._self, this._then);

  final _GSTReturnDto _self;
  final $Res Function(_GSTReturnDto) _then;

/// Create a copy of GSTReturnDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? propertyId = null,Object? periodStart = null,Object? periodEnd = null,Object? totalTaxableRevenue = null,Object? totalGstCollected = null,Object? cgst = null,Object? sgst = null,Object? igst = null,Object? monthlyGst = null,}) {
  return _then(_GSTReturnDto(
propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as String,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as String,totalTaxableRevenue: null == totalTaxableRevenue ? _self.totalTaxableRevenue : totalTaxableRevenue // ignore: cast_nullable_to_non_nullable
as double,totalGstCollected: null == totalGstCollected ? _self.totalGstCollected : totalGstCollected // ignore: cast_nullable_to_non_nullable
as double,cgst: null == cgst ? _self.cgst : cgst // ignore: cast_nullable_to_non_nullable
as double,sgst: null == sgst ? _self.sgst : sgst // ignore: cast_nullable_to_non_nullable
as double,igst: null == igst ? _self.igst : igst // ignore: cast_nullable_to_non_nullable
as double,monthlyGst: null == monthlyGst ? _self._monthlyGst : monthlyGst // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}


/// @nodoc
mixin _$ReportTemplateDto {

@JsonKey(name: 'template_id') String get templateId;@JsonKey(name: 'property_id') String? get propertyId;@JsonKey(name: 'report_name') String get reportName;@JsonKey(name: 'report_type') String get reportType;@JsonKey(name: 'configuration_json') Map<String, dynamic>? get configurationJson;
/// Create a copy of ReportTemplateDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportTemplateDtoCopyWith<ReportTemplateDto> get copyWith => _$ReportTemplateDtoCopyWithImpl<ReportTemplateDto>(this as ReportTemplateDto, _$identity);

  /// Serializes this ReportTemplateDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportTemplateDto&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.reportName, reportName) || other.reportName == reportName)&&(identical(other.reportType, reportType) || other.reportType == reportType)&&const DeepCollectionEquality().equals(other.configurationJson, configurationJson));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,templateId,propertyId,reportName,reportType,const DeepCollectionEquality().hash(configurationJson));

@override
String toString() {
  return 'ReportTemplateDto(templateId: $templateId, propertyId: $propertyId, reportName: $reportName, reportType: $reportType, configurationJson: $configurationJson)';
}


}

/// @nodoc
abstract mixin class $ReportTemplateDtoCopyWith<$Res>  {
  factory $ReportTemplateDtoCopyWith(ReportTemplateDto value, $Res Function(ReportTemplateDto) _then) = _$ReportTemplateDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'template_id') String templateId,@JsonKey(name: 'property_id') String? propertyId,@JsonKey(name: 'report_name') String reportName,@JsonKey(name: 'report_type') String reportType,@JsonKey(name: 'configuration_json') Map<String, dynamic>? configurationJson
});




}
/// @nodoc
class _$ReportTemplateDtoCopyWithImpl<$Res>
    implements $ReportTemplateDtoCopyWith<$Res> {
  _$ReportTemplateDtoCopyWithImpl(this._self, this._then);

  final ReportTemplateDto _self;
  final $Res Function(ReportTemplateDto) _then;

/// Create a copy of ReportTemplateDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? templateId = null,Object? propertyId = freezed,Object? reportName = null,Object? reportType = null,Object? configurationJson = freezed,}) {
  return _then(_self.copyWith(
templateId: null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String,propertyId: freezed == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String?,reportName: null == reportName ? _self.reportName : reportName // ignore: cast_nullable_to_non_nullable
as String,reportType: null == reportType ? _self.reportType : reportType // ignore: cast_nullable_to_non_nullable
as String,configurationJson: freezed == configurationJson ? _self.configurationJson : configurationJson // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReportTemplateDto].
extension ReportTemplateDtoPatterns on ReportTemplateDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReportTemplateDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReportTemplateDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReportTemplateDto value)  $default,){
final _that = this;
switch (_that) {
case _ReportTemplateDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReportTemplateDto value)?  $default,){
final _that = this;
switch (_that) {
case _ReportTemplateDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'template_id')  String templateId, @JsonKey(name: 'property_id')  String? propertyId, @JsonKey(name: 'report_name')  String reportName, @JsonKey(name: 'report_type')  String reportType, @JsonKey(name: 'configuration_json')  Map<String, dynamic>? configurationJson)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReportTemplateDto() when $default != null:
return $default(_that.templateId,_that.propertyId,_that.reportName,_that.reportType,_that.configurationJson);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'template_id')  String templateId, @JsonKey(name: 'property_id')  String? propertyId, @JsonKey(name: 'report_name')  String reportName, @JsonKey(name: 'report_type')  String reportType, @JsonKey(name: 'configuration_json')  Map<String, dynamic>? configurationJson)  $default,) {final _that = this;
switch (_that) {
case _ReportTemplateDto():
return $default(_that.templateId,_that.propertyId,_that.reportName,_that.reportType,_that.configurationJson);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'template_id')  String templateId, @JsonKey(name: 'property_id')  String? propertyId, @JsonKey(name: 'report_name')  String reportName, @JsonKey(name: 'report_type')  String reportType, @JsonKey(name: 'configuration_json')  Map<String, dynamic>? configurationJson)?  $default,) {final _that = this;
switch (_that) {
case _ReportTemplateDto() when $default != null:
return $default(_that.templateId,_that.propertyId,_that.reportName,_that.reportType,_that.configurationJson);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReportTemplateDto extends ReportTemplateDto {
  const _ReportTemplateDto({@JsonKey(name: 'template_id') required this.templateId, @JsonKey(name: 'property_id') this.propertyId, @JsonKey(name: 'report_name') required this.reportName, @JsonKey(name: 'report_type') required this.reportType, @JsonKey(name: 'configuration_json') final  Map<String, dynamic>? configurationJson}): _configurationJson = configurationJson,super._();
  factory _ReportTemplateDto.fromJson(Map<String, dynamic> json) => _$ReportTemplateDtoFromJson(json);

@override@JsonKey(name: 'template_id') final  String templateId;
@override@JsonKey(name: 'property_id') final  String? propertyId;
@override@JsonKey(name: 'report_name') final  String reportName;
@override@JsonKey(name: 'report_type') final  String reportType;
 final  Map<String, dynamic>? _configurationJson;
@override@JsonKey(name: 'configuration_json') Map<String, dynamic>? get configurationJson {
  final value = _configurationJson;
  if (value == null) return null;
  if (_configurationJson is EqualUnmodifiableMapView) return _configurationJson;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of ReportTemplateDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportTemplateDtoCopyWith<_ReportTemplateDto> get copyWith => __$ReportTemplateDtoCopyWithImpl<_ReportTemplateDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReportTemplateDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReportTemplateDto&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.reportName, reportName) || other.reportName == reportName)&&(identical(other.reportType, reportType) || other.reportType == reportType)&&const DeepCollectionEquality().equals(other._configurationJson, _configurationJson));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,templateId,propertyId,reportName,reportType,const DeepCollectionEquality().hash(_configurationJson));

@override
String toString() {
  return 'ReportTemplateDto(templateId: $templateId, propertyId: $propertyId, reportName: $reportName, reportType: $reportType, configurationJson: $configurationJson)';
}


}

/// @nodoc
abstract mixin class _$ReportTemplateDtoCopyWith<$Res> implements $ReportTemplateDtoCopyWith<$Res> {
  factory _$ReportTemplateDtoCopyWith(_ReportTemplateDto value, $Res Function(_ReportTemplateDto) _then) = __$ReportTemplateDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'template_id') String templateId,@JsonKey(name: 'property_id') String? propertyId,@JsonKey(name: 'report_name') String reportName,@JsonKey(name: 'report_type') String reportType,@JsonKey(name: 'configuration_json') Map<String, dynamic>? configurationJson
});




}
/// @nodoc
class __$ReportTemplateDtoCopyWithImpl<$Res>
    implements _$ReportTemplateDtoCopyWith<$Res> {
  __$ReportTemplateDtoCopyWithImpl(this._self, this._then);

  final _ReportTemplateDto _self;
  final $Res Function(_ReportTemplateDto) _then;

/// Create a copy of ReportTemplateDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? templateId = null,Object? propertyId = freezed,Object? reportName = null,Object? reportType = null,Object? configurationJson = freezed,}) {
  return _then(_ReportTemplateDto(
templateId: null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String,propertyId: freezed == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String?,reportName: null == reportName ? _self.reportName : reportName // ignore: cast_nullable_to_non_nullable
as String,reportType: null == reportType ? _self.reportType : reportType // ignore: cast_nullable_to_non_nullable
as String,configurationJson: freezed == configurationJson ? _self._configurationJson : configurationJson // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$ScheduledReportDto {

@JsonKey(name: 'schedule_id') String get scheduleId;@JsonKey(name: 'template_id') String get templateId;@JsonKey(name: 'recipient_role') String get recipientRole;@JsonKey(name: 'delivery_channel') String get deliveryChannel; String get frequency;@JsonKey(name: 'is_active') bool get isActive;
/// Create a copy of ScheduledReportDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduledReportDtoCopyWith<ScheduledReportDto> get copyWith => _$ScheduledReportDtoCopyWithImpl<ScheduledReportDto>(this as ScheduledReportDto, _$identity);

  /// Serializes this ScheduledReportDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduledReportDto&&(identical(other.scheduleId, scheduleId) || other.scheduleId == scheduleId)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.recipientRole, recipientRole) || other.recipientRole == recipientRole)&&(identical(other.deliveryChannel, deliveryChannel) || other.deliveryChannel == deliveryChannel)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,scheduleId,templateId,recipientRole,deliveryChannel,frequency,isActive);

@override
String toString() {
  return 'ScheduledReportDto(scheduleId: $scheduleId, templateId: $templateId, recipientRole: $recipientRole, deliveryChannel: $deliveryChannel, frequency: $frequency, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $ScheduledReportDtoCopyWith<$Res>  {
  factory $ScheduledReportDtoCopyWith(ScheduledReportDto value, $Res Function(ScheduledReportDto) _then) = _$ScheduledReportDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'schedule_id') String scheduleId,@JsonKey(name: 'template_id') String templateId,@JsonKey(name: 'recipient_role') String recipientRole,@JsonKey(name: 'delivery_channel') String deliveryChannel, String frequency,@JsonKey(name: 'is_active') bool isActive
});




}
/// @nodoc
class _$ScheduledReportDtoCopyWithImpl<$Res>
    implements $ScheduledReportDtoCopyWith<$Res> {
  _$ScheduledReportDtoCopyWithImpl(this._self, this._then);

  final ScheduledReportDto _self;
  final $Res Function(ScheduledReportDto) _then;

/// Create a copy of ScheduledReportDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? scheduleId = null,Object? templateId = null,Object? recipientRole = null,Object? deliveryChannel = null,Object? frequency = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
scheduleId: null == scheduleId ? _self.scheduleId : scheduleId // ignore: cast_nullable_to_non_nullable
as String,templateId: null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String,recipientRole: null == recipientRole ? _self.recipientRole : recipientRole // ignore: cast_nullable_to_non_nullable
as String,deliveryChannel: null == deliveryChannel ? _self.deliveryChannel : deliveryChannel // ignore: cast_nullable_to_non_nullable
as String,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ScheduledReportDto].
extension ScheduledReportDtoPatterns on ScheduledReportDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduledReportDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduledReportDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduledReportDto value)  $default,){
final _that = this;
switch (_that) {
case _ScheduledReportDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduledReportDto value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduledReportDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'schedule_id')  String scheduleId, @JsonKey(name: 'template_id')  String templateId, @JsonKey(name: 'recipient_role')  String recipientRole, @JsonKey(name: 'delivery_channel')  String deliveryChannel,  String frequency, @JsonKey(name: 'is_active')  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduledReportDto() when $default != null:
return $default(_that.scheduleId,_that.templateId,_that.recipientRole,_that.deliveryChannel,_that.frequency,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'schedule_id')  String scheduleId, @JsonKey(name: 'template_id')  String templateId, @JsonKey(name: 'recipient_role')  String recipientRole, @JsonKey(name: 'delivery_channel')  String deliveryChannel,  String frequency, @JsonKey(name: 'is_active')  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _ScheduledReportDto():
return $default(_that.scheduleId,_that.templateId,_that.recipientRole,_that.deliveryChannel,_that.frequency,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'schedule_id')  String scheduleId, @JsonKey(name: 'template_id')  String templateId, @JsonKey(name: 'recipient_role')  String recipientRole, @JsonKey(name: 'delivery_channel')  String deliveryChannel,  String frequency, @JsonKey(name: 'is_active')  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _ScheduledReportDto() when $default != null:
return $default(_that.scheduleId,_that.templateId,_that.recipientRole,_that.deliveryChannel,_that.frequency,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScheduledReportDto extends ScheduledReportDto {
  const _ScheduledReportDto({@JsonKey(name: 'schedule_id') required this.scheduleId, @JsonKey(name: 'template_id') required this.templateId, @JsonKey(name: 'recipient_role') required this.recipientRole, @JsonKey(name: 'delivery_channel') required this.deliveryChannel, required this.frequency, @JsonKey(name: 'is_active') required this.isActive}): super._();
  factory _ScheduledReportDto.fromJson(Map<String, dynamic> json) => _$ScheduledReportDtoFromJson(json);

@override@JsonKey(name: 'schedule_id') final  String scheduleId;
@override@JsonKey(name: 'template_id') final  String templateId;
@override@JsonKey(name: 'recipient_role') final  String recipientRole;
@override@JsonKey(name: 'delivery_channel') final  String deliveryChannel;
@override final  String frequency;
@override@JsonKey(name: 'is_active') final  bool isActive;

/// Create a copy of ScheduledReportDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduledReportDtoCopyWith<_ScheduledReportDto> get copyWith => __$ScheduledReportDtoCopyWithImpl<_ScheduledReportDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScheduledReportDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduledReportDto&&(identical(other.scheduleId, scheduleId) || other.scheduleId == scheduleId)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.recipientRole, recipientRole) || other.recipientRole == recipientRole)&&(identical(other.deliveryChannel, deliveryChannel) || other.deliveryChannel == deliveryChannel)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,scheduleId,templateId,recipientRole,deliveryChannel,frequency,isActive);

@override
String toString() {
  return 'ScheduledReportDto(scheduleId: $scheduleId, templateId: $templateId, recipientRole: $recipientRole, deliveryChannel: $deliveryChannel, frequency: $frequency, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$ScheduledReportDtoCopyWith<$Res> implements $ScheduledReportDtoCopyWith<$Res> {
  factory _$ScheduledReportDtoCopyWith(_ScheduledReportDto value, $Res Function(_ScheduledReportDto) _then) = __$ScheduledReportDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'schedule_id') String scheduleId,@JsonKey(name: 'template_id') String templateId,@JsonKey(name: 'recipient_role') String recipientRole,@JsonKey(name: 'delivery_channel') String deliveryChannel, String frequency,@JsonKey(name: 'is_active') bool isActive
});




}
/// @nodoc
class __$ScheduledReportDtoCopyWithImpl<$Res>
    implements _$ScheduledReportDtoCopyWith<$Res> {
  __$ScheduledReportDtoCopyWithImpl(this._self, this._then);

  final _ScheduledReportDto _self;
  final $Res Function(_ScheduledReportDto) _then;

/// Create a copy of ScheduledReportDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? scheduleId = null,Object? templateId = null,Object? recipientRole = null,Object? deliveryChannel = null,Object? frequency = null,Object? isActive = null,}) {
  return _then(_ScheduledReportDto(
scheduleId: null == scheduleId ? _self.scheduleId : scheduleId // ignore: cast_nullable_to_non_nullable
as String,templateId: null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String,recipientRole: null == recipientRole ? _self.recipientRole : recipientRole // ignore: cast_nullable_to_non_nullable
as String,deliveryChannel: null == deliveryChannel ? _self.deliveryChannel : deliveryChannel // ignore: cast_nullable_to_non_nullable
as String,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
