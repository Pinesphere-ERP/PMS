// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checkout_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CheckOutState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckOutState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CheckOutState()';
}


}

/// @nodoc
class $CheckOutStateCopyWith<$Res>  {
$CheckOutStateCopyWith(CheckOutState _, $Res Function(CheckOutState) __);
}


/// Adds pattern-matching-related methods to [CheckOutState].
extension CheckOutStatePatterns on CheckOutState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _Success value)?  success,TResult Function( _Error value)?  error,TResult Function( _LoadedPending value)?  loadedPendingCheckouts,TResult Function( _LoadedBilling value)?  loadedBilling,TResult Function( _LoadedTodays value)?  loadedTodaysCheckouts,TResult Function( _LoadedDetail value)?  loadedDetail,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Success() when success != null:
return success(_that);case _Error() when error != null:
return error(_that);case _LoadedPending() when loadedPendingCheckouts != null:
return loadedPendingCheckouts(_that);case _LoadedBilling() when loadedBilling != null:
return loadedBilling(_that);case _LoadedTodays() when loadedTodaysCheckouts != null:
return loadedTodaysCheckouts(_that);case _LoadedDetail() when loadedDetail != null:
return loadedDetail(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _Success value)  success,required TResult Function( _Error value)  error,required TResult Function( _LoadedPending value)  loadedPendingCheckouts,required TResult Function( _LoadedBilling value)  loadedBilling,required TResult Function( _LoadedTodays value)  loadedTodaysCheckouts,required TResult Function( _LoadedDetail value)  loadedDetail,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _Success():
return success(_that);case _Error():
return error(_that);case _LoadedPending():
return loadedPendingCheckouts(_that);case _LoadedBilling():
return loadedBilling(_that);case _LoadedTodays():
return loadedTodaysCheckouts(_that);case _LoadedDetail():
return loadedDetail(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _Success value)?  success,TResult? Function( _Error value)?  error,TResult? Function( _LoadedPending value)?  loadedPendingCheckouts,TResult? Function( _LoadedBilling value)?  loadedBilling,TResult? Function( _LoadedTodays value)?  loadedTodaysCheckouts,TResult? Function( _LoadedDetail value)?  loadedDetail,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Success() when success != null:
return success(_that);case _Error() when error != null:
return error(_that);case _LoadedPending() when loadedPendingCheckouts != null:
return loadedPendingCheckouts(_that);case _LoadedBilling() when loadedBilling != null:
return loadedBilling(_that);case _LoadedTodays() when loadedTodaysCheckouts != null:
return loadedTodaysCheckouts(_that);case _LoadedDetail() when loadedDetail != null:
return loadedDetail(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( String message,  String? checkoutId)?  success,TResult Function( String message)?  error,TResult Function( List<Map<String, dynamic>> checkouts)?  loadedPendingCheckouts,TResult Function( Map<String, dynamic> billing)?  loadedBilling,TResult Function( List<Map<String, dynamic>> checkouts)?  loadedTodaysCheckouts,TResult Function( Map<String, dynamic> detail)?  loadedDetail,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Success() when success != null:
return success(_that.message,_that.checkoutId);case _Error() when error != null:
return error(_that.message);case _LoadedPending() when loadedPendingCheckouts != null:
return loadedPendingCheckouts(_that.checkouts);case _LoadedBilling() when loadedBilling != null:
return loadedBilling(_that.billing);case _LoadedTodays() when loadedTodaysCheckouts != null:
return loadedTodaysCheckouts(_that.checkouts);case _LoadedDetail() when loadedDetail != null:
return loadedDetail(_that.detail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( String message,  String? checkoutId)  success,required TResult Function( String message)  error,required TResult Function( List<Map<String, dynamic>> checkouts)  loadedPendingCheckouts,required TResult Function( Map<String, dynamic> billing)  loadedBilling,required TResult Function( List<Map<String, dynamic>> checkouts)  loadedTodaysCheckouts,required TResult Function( Map<String, dynamic> detail)  loadedDetail,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Success():
return success(_that.message,_that.checkoutId);case _Error():
return error(_that.message);case _LoadedPending():
return loadedPendingCheckouts(_that.checkouts);case _LoadedBilling():
return loadedBilling(_that.billing);case _LoadedTodays():
return loadedTodaysCheckouts(_that.checkouts);case _LoadedDetail():
return loadedDetail(_that.detail);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( String message,  String? checkoutId)?  success,TResult? Function( String message)?  error,TResult? Function( List<Map<String, dynamic>> checkouts)?  loadedPendingCheckouts,TResult? Function( Map<String, dynamic> billing)?  loadedBilling,TResult? Function( List<Map<String, dynamic>> checkouts)?  loadedTodaysCheckouts,TResult? Function( Map<String, dynamic> detail)?  loadedDetail,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Success() when success != null:
return success(_that.message,_that.checkoutId);case _Error() when error != null:
return error(_that.message);case _LoadedPending() when loadedPendingCheckouts != null:
return loadedPendingCheckouts(_that.checkouts);case _LoadedBilling() when loadedBilling != null:
return loadedBilling(_that.billing);case _LoadedTodays() when loadedTodaysCheckouts != null:
return loadedTodaysCheckouts(_that.checkouts);case _LoadedDetail() when loadedDetail != null:
return loadedDetail(_that.detail);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements CheckOutState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CheckOutState.initial()';
}


}




/// @nodoc


class _Loading implements CheckOutState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CheckOutState.loading()';
}


}




/// @nodoc


class _Success implements CheckOutState {
  const _Success(this.message, {this.checkoutId});
  

 final  String message;
 final  String? checkoutId;

/// Create a copy of CheckOutState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SuccessCopyWith<_Success> get copyWith => __$SuccessCopyWithImpl<_Success>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Success&&(identical(other.message, message) || other.message == message)&&(identical(other.checkoutId, checkoutId) || other.checkoutId == checkoutId));
}


@override
int get hashCode => Object.hash(runtimeType,message,checkoutId);

@override
String toString() {
  return 'CheckOutState.success(message: $message, checkoutId: $checkoutId)';
}


}

/// @nodoc
abstract mixin class _$SuccessCopyWith<$Res> implements $CheckOutStateCopyWith<$Res> {
  factory _$SuccessCopyWith(_Success value, $Res Function(_Success) _then) = __$SuccessCopyWithImpl;
@useResult
$Res call({
 String message, String? checkoutId
});




}
/// @nodoc
class __$SuccessCopyWithImpl<$Res>
    implements _$SuccessCopyWith<$Res> {
  __$SuccessCopyWithImpl(this._self, this._then);

  final _Success _self;
  final $Res Function(_Success) _then;

/// Create a copy of CheckOutState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? checkoutId = freezed,}) {
  return _then(_Success(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,checkoutId: freezed == checkoutId ? _self.checkoutId : checkoutId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _Error implements CheckOutState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of CheckOutState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'CheckOutState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $CheckOutStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of CheckOutState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _LoadedPending implements CheckOutState {
  const _LoadedPending(final  List<Map<String, dynamic>> checkouts): _checkouts = checkouts;
  

 final  List<Map<String, dynamic>> _checkouts;
 List<Map<String, dynamic>> get checkouts {
  if (_checkouts is EqualUnmodifiableListView) return _checkouts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_checkouts);
}


/// Create a copy of CheckOutState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedPendingCopyWith<_LoadedPending> get copyWith => __$LoadedPendingCopyWithImpl<_LoadedPending>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadedPending&&const DeepCollectionEquality().equals(other._checkouts, _checkouts));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_checkouts));

@override
String toString() {
  return 'CheckOutState.loadedPendingCheckouts(checkouts: $checkouts)';
}


}

/// @nodoc
abstract mixin class _$LoadedPendingCopyWith<$Res> implements $CheckOutStateCopyWith<$Res> {
  factory _$LoadedPendingCopyWith(_LoadedPending value, $Res Function(_LoadedPending) _then) = __$LoadedPendingCopyWithImpl;
@useResult
$Res call({
 List<Map<String, dynamic>> checkouts
});




}
/// @nodoc
class __$LoadedPendingCopyWithImpl<$Res>
    implements _$LoadedPendingCopyWith<$Res> {
  __$LoadedPendingCopyWithImpl(this._self, this._then);

  final _LoadedPending _self;
  final $Res Function(_LoadedPending) _then;

/// Create a copy of CheckOutState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? checkouts = null,}) {
  return _then(_LoadedPending(
null == checkouts ? _self._checkouts : checkouts // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

/// @nodoc


class _LoadedBilling implements CheckOutState {
  const _LoadedBilling(final  Map<String, dynamic> billing): _billing = billing;
  

 final  Map<String, dynamic> _billing;
 Map<String, dynamic> get billing {
  if (_billing is EqualUnmodifiableMapView) return _billing;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_billing);
}


/// Create a copy of CheckOutState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedBillingCopyWith<_LoadedBilling> get copyWith => __$LoadedBillingCopyWithImpl<_LoadedBilling>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadedBilling&&const DeepCollectionEquality().equals(other._billing, _billing));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_billing));

@override
String toString() {
  return 'CheckOutState.loadedBilling(billing: $billing)';
}


}

/// @nodoc
abstract mixin class _$LoadedBillingCopyWith<$Res> implements $CheckOutStateCopyWith<$Res> {
  factory _$LoadedBillingCopyWith(_LoadedBilling value, $Res Function(_LoadedBilling) _then) = __$LoadedBillingCopyWithImpl;
@useResult
$Res call({
 Map<String, dynamic> billing
});




}
/// @nodoc
class __$LoadedBillingCopyWithImpl<$Res>
    implements _$LoadedBillingCopyWith<$Res> {
  __$LoadedBillingCopyWithImpl(this._self, this._then);

  final _LoadedBilling _self;
  final $Res Function(_LoadedBilling) _then;

/// Create a copy of CheckOutState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? billing = null,}) {
  return _then(_LoadedBilling(
null == billing ? _self._billing : billing // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

/// @nodoc


class _LoadedTodays implements CheckOutState {
  const _LoadedTodays(final  List<Map<String, dynamic>> checkouts): _checkouts = checkouts;
  

 final  List<Map<String, dynamic>> _checkouts;
 List<Map<String, dynamic>> get checkouts {
  if (_checkouts is EqualUnmodifiableListView) return _checkouts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_checkouts);
}


/// Create a copy of CheckOutState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedTodaysCopyWith<_LoadedTodays> get copyWith => __$LoadedTodaysCopyWithImpl<_LoadedTodays>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadedTodays&&const DeepCollectionEquality().equals(other._checkouts, _checkouts));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_checkouts));

@override
String toString() {
  return 'CheckOutState.loadedTodaysCheckouts(checkouts: $checkouts)';
}


}

/// @nodoc
abstract mixin class _$LoadedTodaysCopyWith<$Res> implements $CheckOutStateCopyWith<$Res> {
  factory _$LoadedTodaysCopyWith(_LoadedTodays value, $Res Function(_LoadedTodays) _then) = __$LoadedTodaysCopyWithImpl;
@useResult
$Res call({
 List<Map<String, dynamic>> checkouts
});




}
/// @nodoc
class __$LoadedTodaysCopyWithImpl<$Res>
    implements _$LoadedTodaysCopyWith<$Res> {
  __$LoadedTodaysCopyWithImpl(this._self, this._then);

  final _LoadedTodays _self;
  final $Res Function(_LoadedTodays) _then;

/// Create a copy of CheckOutState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? checkouts = null,}) {
  return _then(_LoadedTodays(
null == checkouts ? _self._checkouts : checkouts // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

/// @nodoc


class _LoadedDetail implements CheckOutState {
  const _LoadedDetail(final  Map<String, dynamic> detail): _detail = detail;
  

 final  Map<String, dynamic> _detail;
 Map<String, dynamic> get detail {
  if (_detail is EqualUnmodifiableMapView) return _detail;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_detail);
}


/// Create a copy of CheckOutState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedDetailCopyWith<_LoadedDetail> get copyWith => __$LoadedDetailCopyWithImpl<_LoadedDetail>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadedDetail&&const DeepCollectionEquality().equals(other._detail, _detail));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_detail));

@override
String toString() {
  return 'CheckOutState.loadedDetail(detail: $detail)';
}


}

/// @nodoc
abstract mixin class _$LoadedDetailCopyWith<$Res> implements $CheckOutStateCopyWith<$Res> {
  factory _$LoadedDetailCopyWith(_LoadedDetail value, $Res Function(_LoadedDetail) _then) = __$LoadedDetailCopyWithImpl;
@useResult
$Res call({
 Map<String, dynamic> detail
});




}
/// @nodoc
class __$LoadedDetailCopyWithImpl<$Res>
    implements _$LoadedDetailCopyWith<$Res> {
  __$LoadedDetailCopyWithImpl(this._self, this._then);

  final _LoadedDetail _self;
  final $Res Function(_LoadedDetail) _then;

/// Create a copy of CheckOutState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = null,}) {
  return _then(_LoadedDetail(
null == detail ? _self._detail : detail // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
