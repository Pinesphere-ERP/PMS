// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checkin_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CheckInState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckInState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CheckInState()';
}


}

/// @nodoc
class $CheckInStateCopyWith<$Res>  {
$CheckInStateCopyWith(CheckInState _, $Res Function(CheckInState) __);
}


/// Adds pattern-matching-related methods to [CheckInState].
extension CheckInStatePatterns on CheckInState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _Success value)?  success,TResult Function( _Error value)?  error,TResult Function( _LoadedCheckIns value)?  loadedCheckIns,TResult Function( _LoadedRooms value)?  loadedRooms,TResult Function( _LoadedBookings value)?  loadedBookings,TResult Function( _LoadedGuests value)?  loadedGuests,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Success() when success != null:
return success(_that);case _Error() when error != null:
return error(_that);case _LoadedCheckIns() when loadedCheckIns != null:
return loadedCheckIns(_that);case _LoadedRooms() when loadedRooms != null:
return loadedRooms(_that);case _LoadedBookings() when loadedBookings != null:
return loadedBookings(_that);case _LoadedGuests() when loadedGuests != null:
return loadedGuests(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _Success value)  success,required TResult Function( _Error value)  error,required TResult Function( _LoadedCheckIns value)  loadedCheckIns,required TResult Function( _LoadedRooms value)  loadedRooms,required TResult Function( _LoadedBookings value)  loadedBookings,required TResult Function( _LoadedGuests value)  loadedGuests,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _Success():
return success(_that);case _Error():
return error(_that);case _LoadedCheckIns():
return loadedCheckIns(_that);case _LoadedRooms():
return loadedRooms(_that);case _LoadedBookings():
return loadedBookings(_that);case _LoadedGuests():
return loadedGuests(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _Success value)?  success,TResult? Function( _Error value)?  error,TResult? Function( _LoadedCheckIns value)?  loadedCheckIns,TResult? Function( _LoadedRooms value)?  loadedRooms,TResult? Function( _LoadedBookings value)?  loadedBookings,TResult? Function( _LoadedGuests value)?  loadedGuests,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Success() when success != null:
return success(_that);case _Error() when error != null:
return error(_that);case _LoadedCheckIns() when loadedCheckIns != null:
return loadedCheckIns(_that);case _LoadedRooms() when loadedRooms != null:
return loadedRooms(_that);case _LoadedBookings() when loadedBookings != null:
return loadedBookings(_that);case _LoadedGuests() when loadedGuests != null:
return loadedGuests(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( String message,  String? checkinId)?  success,TResult Function( String message)?  error,TResult Function( List<Map<String, dynamic>> checkins)?  loadedCheckIns,TResult Function( List<Map<String, dynamic>> rooms)?  loadedRooms,TResult Function( List<Map<String, dynamic>> bookings)?  loadedBookings,TResult Function( List<Map<String, dynamic>> guests)?  loadedGuests,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Success() when success != null:
return success(_that.message,_that.checkinId);case _Error() when error != null:
return error(_that.message);case _LoadedCheckIns() when loadedCheckIns != null:
return loadedCheckIns(_that.checkins);case _LoadedRooms() when loadedRooms != null:
return loadedRooms(_that.rooms);case _LoadedBookings() when loadedBookings != null:
return loadedBookings(_that.bookings);case _LoadedGuests() when loadedGuests != null:
return loadedGuests(_that.guests);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( String message,  String? checkinId)  success,required TResult Function( String message)  error,required TResult Function( List<Map<String, dynamic>> checkins)  loadedCheckIns,required TResult Function( List<Map<String, dynamic>> rooms)  loadedRooms,required TResult Function( List<Map<String, dynamic>> bookings)  loadedBookings,required TResult Function( List<Map<String, dynamic>> guests)  loadedGuests,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Success():
return success(_that.message,_that.checkinId);case _Error():
return error(_that.message);case _LoadedCheckIns():
return loadedCheckIns(_that.checkins);case _LoadedRooms():
return loadedRooms(_that.rooms);case _LoadedBookings():
return loadedBookings(_that.bookings);case _LoadedGuests():
return loadedGuests(_that.guests);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( String message,  String? checkinId)?  success,TResult? Function( String message)?  error,TResult? Function( List<Map<String, dynamic>> checkins)?  loadedCheckIns,TResult? Function( List<Map<String, dynamic>> rooms)?  loadedRooms,TResult? Function( List<Map<String, dynamic>> bookings)?  loadedBookings,TResult? Function( List<Map<String, dynamic>> guests)?  loadedGuests,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Success() when success != null:
return success(_that.message,_that.checkinId);case _Error() when error != null:
return error(_that.message);case _LoadedCheckIns() when loadedCheckIns != null:
return loadedCheckIns(_that.checkins);case _LoadedRooms() when loadedRooms != null:
return loadedRooms(_that.rooms);case _LoadedBookings() when loadedBookings != null:
return loadedBookings(_that.bookings);case _LoadedGuests() when loadedGuests != null:
return loadedGuests(_that.guests);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements CheckInState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CheckInState.initial()';
}


}




/// @nodoc


class _Loading implements CheckInState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CheckInState.loading()';
}


}




/// @nodoc


class _Success implements CheckInState {
  const _Success(this.message, {this.checkinId});
  

 final  String message;
 final  String? checkinId;

/// Create a copy of CheckInState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SuccessCopyWith<_Success> get copyWith => __$SuccessCopyWithImpl<_Success>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Success&&(identical(other.message, message) || other.message == message)&&(identical(other.checkinId, checkinId) || other.checkinId == checkinId));
}


@override
int get hashCode => Object.hash(runtimeType,message,checkinId);

@override
String toString() {
  return 'CheckInState.success(message: $message, checkinId: $checkinId)';
}


}

/// @nodoc
abstract mixin class _$SuccessCopyWith<$Res> implements $CheckInStateCopyWith<$Res> {
  factory _$SuccessCopyWith(_Success value, $Res Function(_Success) _then) = __$SuccessCopyWithImpl;
@useResult
$Res call({
 String message, String? checkinId
});




}
/// @nodoc
class __$SuccessCopyWithImpl<$Res>
    implements _$SuccessCopyWith<$Res> {
  __$SuccessCopyWithImpl(this._self, this._then);

  final _Success _self;
  final $Res Function(_Success) _then;

/// Create a copy of CheckInState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? checkinId = freezed,}) {
  return _then(_Success(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,checkinId: freezed == checkinId ? _self.checkinId : checkinId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _Error implements CheckInState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of CheckInState
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
  return 'CheckInState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $CheckInStateCopyWith<$Res> {
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

/// Create a copy of CheckInState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _LoadedCheckIns implements CheckInState {
  const _LoadedCheckIns(final  List<Map<String, dynamic>> checkins): _checkins = checkins;
  

 final  List<Map<String, dynamic>> _checkins;
 List<Map<String, dynamic>> get checkins {
  if (_checkins is EqualUnmodifiableListView) return _checkins;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_checkins);
}


/// Create a copy of CheckInState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCheckInsCopyWith<_LoadedCheckIns> get copyWith => __$LoadedCheckInsCopyWithImpl<_LoadedCheckIns>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadedCheckIns&&const DeepCollectionEquality().equals(other._checkins, _checkins));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_checkins));

@override
String toString() {
  return 'CheckInState.loadedCheckIns(checkins: $checkins)';
}


}

/// @nodoc
abstract mixin class _$LoadedCheckInsCopyWith<$Res> implements $CheckInStateCopyWith<$Res> {
  factory _$LoadedCheckInsCopyWith(_LoadedCheckIns value, $Res Function(_LoadedCheckIns) _then) = __$LoadedCheckInsCopyWithImpl;
@useResult
$Res call({
 List<Map<String, dynamic>> checkins
});




}
/// @nodoc
class __$LoadedCheckInsCopyWithImpl<$Res>
    implements _$LoadedCheckInsCopyWith<$Res> {
  __$LoadedCheckInsCopyWithImpl(this._self, this._then);

  final _LoadedCheckIns _self;
  final $Res Function(_LoadedCheckIns) _then;

/// Create a copy of CheckInState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? checkins = null,}) {
  return _then(_LoadedCheckIns(
null == checkins ? _self._checkins : checkins // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

/// @nodoc


class _LoadedRooms implements CheckInState {
  const _LoadedRooms(final  List<Map<String, dynamic>> rooms): _rooms = rooms;
  

 final  List<Map<String, dynamic>> _rooms;
 List<Map<String, dynamic>> get rooms {
  if (_rooms is EqualUnmodifiableListView) return _rooms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rooms);
}


/// Create a copy of CheckInState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedRoomsCopyWith<_LoadedRooms> get copyWith => __$LoadedRoomsCopyWithImpl<_LoadedRooms>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadedRooms&&const DeepCollectionEquality().equals(other._rooms, _rooms));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rooms));

@override
String toString() {
  return 'CheckInState.loadedRooms(rooms: $rooms)';
}


}

/// @nodoc
abstract mixin class _$LoadedRoomsCopyWith<$Res> implements $CheckInStateCopyWith<$Res> {
  factory _$LoadedRoomsCopyWith(_LoadedRooms value, $Res Function(_LoadedRooms) _then) = __$LoadedRoomsCopyWithImpl;
@useResult
$Res call({
 List<Map<String, dynamic>> rooms
});




}
/// @nodoc
class __$LoadedRoomsCopyWithImpl<$Res>
    implements _$LoadedRoomsCopyWith<$Res> {
  __$LoadedRoomsCopyWithImpl(this._self, this._then);

  final _LoadedRooms _self;
  final $Res Function(_LoadedRooms) _then;

/// Create a copy of CheckInState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rooms = null,}) {
  return _then(_LoadedRooms(
null == rooms ? _self._rooms : rooms // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

/// @nodoc


class _LoadedBookings implements CheckInState {
  const _LoadedBookings(final  List<Map<String, dynamic>> bookings): _bookings = bookings;
  

 final  List<Map<String, dynamic>> _bookings;
 List<Map<String, dynamic>> get bookings {
  if (_bookings is EqualUnmodifiableListView) return _bookings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bookings);
}


/// Create a copy of CheckInState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedBookingsCopyWith<_LoadedBookings> get copyWith => __$LoadedBookingsCopyWithImpl<_LoadedBookings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadedBookings&&const DeepCollectionEquality().equals(other._bookings, _bookings));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_bookings));

@override
String toString() {
  return 'CheckInState.loadedBookings(bookings: $bookings)';
}


}

/// @nodoc
abstract mixin class _$LoadedBookingsCopyWith<$Res> implements $CheckInStateCopyWith<$Res> {
  factory _$LoadedBookingsCopyWith(_LoadedBookings value, $Res Function(_LoadedBookings) _then) = __$LoadedBookingsCopyWithImpl;
@useResult
$Res call({
 List<Map<String, dynamic>> bookings
});




}
/// @nodoc
class __$LoadedBookingsCopyWithImpl<$Res>
    implements _$LoadedBookingsCopyWith<$Res> {
  __$LoadedBookingsCopyWithImpl(this._self, this._then);

  final _LoadedBookings _self;
  final $Res Function(_LoadedBookings) _then;

/// Create a copy of CheckInState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? bookings = null,}) {
  return _then(_LoadedBookings(
null == bookings ? _self._bookings : bookings // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

/// @nodoc


class _LoadedGuests implements CheckInState {
  const _LoadedGuests(final  List<Map<String, dynamic>> guests): _guests = guests;
  

 final  List<Map<String, dynamic>> _guests;
 List<Map<String, dynamic>> get guests {
  if (_guests is EqualUnmodifiableListView) return _guests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_guests);
}


/// Create a copy of CheckInState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedGuestsCopyWith<_LoadedGuests> get copyWith => __$LoadedGuestsCopyWithImpl<_LoadedGuests>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadedGuests&&const DeepCollectionEquality().equals(other._guests, _guests));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_guests));

@override
String toString() {
  return 'CheckInState.loadedGuests(guests: $guests)';
}


}

/// @nodoc
abstract mixin class _$LoadedGuestsCopyWith<$Res> implements $CheckInStateCopyWith<$Res> {
  factory _$LoadedGuestsCopyWith(_LoadedGuests value, $Res Function(_LoadedGuests) _then) = __$LoadedGuestsCopyWithImpl;
@useResult
$Res call({
 List<Map<String, dynamic>> guests
});




}
/// @nodoc
class __$LoadedGuestsCopyWithImpl<$Res>
    implements _$LoadedGuestsCopyWith<$Res> {
  __$LoadedGuestsCopyWithImpl(this._self, this._then);

  final _LoadedGuests _self;
  final $Res Function(_LoadedGuests) _then;

/// Create a copy of CheckInState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? guests = null,}) {
  return _then(_LoadedGuests(
null == guests ? _self._guests : guests // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

// dart format on
