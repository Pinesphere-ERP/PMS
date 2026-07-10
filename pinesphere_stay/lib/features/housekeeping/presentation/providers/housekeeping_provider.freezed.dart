// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'housekeeping_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HousekeepingState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HousekeepingState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HousekeepingState()';
}


}

/// @nodoc
class $HousekeepingStateCopyWith<$Res>  {
$HousekeepingStateCopyWith(HousekeepingState _, $Res Function(HousekeepingState) __);
}


/// Adds pattern-matching-related methods to [HousekeepingState].
extension HousekeepingStatePatterns on HousekeepingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _Success value)?  success,TResult Function( _Error value)?  error,TResult Function( _LoadedTasks value)?  loadedTasks,TResult Function( _LoadedTickets value)?  loadedMaintenanceTickets,TResult Function( _LoadedDashboard value)?  loadedDashboard,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Success() when success != null:
return success(_that);case _Error() when error != null:
return error(_that);case _LoadedTasks() when loadedTasks != null:
return loadedTasks(_that);case _LoadedTickets() when loadedMaintenanceTickets != null:
return loadedMaintenanceTickets(_that);case _LoadedDashboard() when loadedDashboard != null:
return loadedDashboard(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _Success value)  success,required TResult Function( _Error value)  error,required TResult Function( _LoadedTasks value)  loadedTasks,required TResult Function( _LoadedTickets value)  loadedMaintenanceTickets,required TResult Function( _LoadedDashboard value)  loadedDashboard,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _Success():
return success(_that);case _Error():
return error(_that);case _LoadedTasks():
return loadedTasks(_that);case _LoadedTickets():
return loadedMaintenanceTickets(_that);case _LoadedDashboard():
return loadedDashboard(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _Success value)?  success,TResult? Function( _Error value)?  error,TResult? Function( _LoadedTasks value)?  loadedTasks,TResult? Function( _LoadedTickets value)?  loadedMaintenanceTickets,TResult? Function( _LoadedDashboard value)?  loadedDashboard,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Success() when success != null:
return success(_that);case _Error() when error != null:
return error(_that);case _LoadedTasks() when loadedTasks != null:
return loadedTasks(_that);case _LoadedTickets() when loadedMaintenanceTickets != null:
return loadedMaintenanceTickets(_that);case _LoadedDashboard() when loadedDashboard != null:
return loadedDashboard(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( String message)?  success,TResult Function( String message)?  error,TResult Function( List<Map<String, dynamic>> tasks)?  loadedTasks,TResult Function( List<Map<String, dynamic>> tickets)?  loadedMaintenanceTickets,TResult Function( Map<String, dynamic> dashboard)?  loadedDashboard,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Success() when success != null:
return success(_that.message);case _Error() when error != null:
return error(_that.message);case _LoadedTasks() when loadedTasks != null:
return loadedTasks(_that.tasks);case _LoadedTickets() when loadedMaintenanceTickets != null:
return loadedMaintenanceTickets(_that.tickets);case _LoadedDashboard() when loadedDashboard != null:
return loadedDashboard(_that.dashboard);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( String message)  success,required TResult Function( String message)  error,required TResult Function( List<Map<String, dynamic>> tasks)  loadedTasks,required TResult Function( List<Map<String, dynamic>> tickets)  loadedMaintenanceTickets,required TResult Function( Map<String, dynamic> dashboard)  loadedDashboard,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Success():
return success(_that.message);case _Error():
return error(_that.message);case _LoadedTasks():
return loadedTasks(_that.tasks);case _LoadedTickets():
return loadedMaintenanceTickets(_that.tickets);case _LoadedDashboard():
return loadedDashboard(_that.dashboard);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( String message)?  success,TResult? Function( String message)?  error,TResult? Function( List<Map<String, dynamic>> tasks)?  loadedTasks,TResult? Function( List<Map<String, dynamic>> tickets)?  loadedMaintenanceTickets,TResult? Function( Map<String, dynamic> dashboard)?  loadedDashboard,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Success() when success != null:
return success(_that.message);case _Error() when error != null:
return error(_that.message);case _LoadedTasks() when loadedTasks != null:
return loadedTasks(_that.tasks);case _LoadedTickets() when loadedMaintenanceTickets != null:
return loadedMaintenanceTickets(_that.tickets);case _LoadedDashboard() when loadedDashboard != null:
return loadedDashboard(_that.dashboard);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements HousekeepingState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HousekeepingState.initial()';
}


}




/// @nodoc


class _Loading implements HousekeepingState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HousekeepingState.loading()';
}


}




/// @nodoc


class _Success implements HousekeepingState {
  const _Success(this.message);
  

 final  String message;

/// Create a copy of HousekeepingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SuccessCopyWith<_Success> get copyWith => __$SuccessCopyWithImpl<_Success>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Success&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'HousekeepingState.success(message: $message)';
}


}

/// @nodoc
abstract mixin class _$SuccessCopyWith<$Res> implements $HousekeepingStateCopyWith<$Res> {
  factory _$SuccessCopyWith(_Success value, $Res Function(_Success) _then) = __$SuccessCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$SuccessCopyWithImpl<$Res>
    implements _$SuccessCopyWith<$Res> {
  __$SuccessCopyWithImpl(this._self, this._then);

  final _Success _self;
  final $Res Function(_Success) _then;

/// Create a copy of HousekeepingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Success(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _Error implements HousekeepingState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of HousekeepingState
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
  return 'HousekeepingState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $HousekeepingStateCopyWith<$Res> {
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

/// Create a copy of HousekeepingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _LoadedTasks implements HousekeepingState {
  const _LoadedTasks(final  List<Map<String, dynamic>> tasks): _tasks = tasks;
  

 final  List<Map<String, dynamic>> _tasks;
 List<Map<String, dynamic>> get tasks {
  if (_tasks is EqualUnmodifiableListView) return _tasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasks);
}


/// Create a copy of HousekeepingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedTasksCopyWith<_LoadedTasks> get copyWith => __$LoadedTasksCopyWithImpl<_LoadedTasks>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadedTasks&&const DeepCollectionEquality().equals(other._tasks, _tasks));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tasks));

@override
String toString() {
  return 'HousekeepingState.loadedTasks(tasks: $tasks)';
}


}

/// @nodoc
abstract mixin class _$LoadedTasksCopyWith<$Res> implements $HousekeepingStateCopyWith<$Res> {
  factory _$LoadedTasksCopyWith(_LoadedTasks value, $Res Function(_LoadedTasks) _then) = __$LoadedTasksCopyWithImpl;
@useResult
$Res call({
 List<Map<String, dynamic>> tasks
});




}
/// @nodoc
class __$LoadedTasksCopyWithImpl<$Res>
    implements _$LoadedTasksCopyWith<$Res> {
  __$LoadedTasksCopyWithImpl(this._self, this._then);

  final _LoadedTasks _self;
  final $Res Function(_LoadedTasks) _then;

/// Create a copy of HousekeepingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tasks = null,}) {
  return _then(_LoadedTasks(
null == tasks ? _self._tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

/// @nodoc


class _LoadedTickets implements HousekeepingState {
  const _LoadedTickets(final  List<Map<String, dynamic>> tickets): _tickets = tickets;
  

 final  List<Map<String, dynamic>> _tickets;
 List<Map<String, dynamic>> get tickets {
  if (_tickets is EqualUnmodifiableListView) return _tickets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tickets);
}


/// Create a copy of HousekeepingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedTicketsCopyWith<_LoadedTickets> get copyWith => __$LoadedTicketsCopyWithImpl<_LoadedTickets>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadedTickets&&const DeepCollectionEquality().equals(other._tickets, _tickets));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tickets));

@override
String toString() {
  return 'HousekeepingState.loadedMaintenanceTickets(tickets: $tickets)';
}


}

/// @nodoc
abstract mixin class _$LoadedTicketsCopyWith<$Res> implements $HousekeepingStateCopyWith<$Res> {
  factory _$LoadedTicketsCopyWith(_LoadedTickets value, $Res Function(_LoadedTickets) _then) = __$LoadedTicketsCopyWithImpl;
@useResult
$Res call({
 List<Map<String, dynamic>> tickets
});




}
/// @nodoc
class __$LoadedTicketsCopyWithImpl<$Res>
    implements _$LoadedTicketsCopyWith<$Res> {
  __$LoadedTicketsCopyWithImpl(this._self, this._then);

  final _LoadedTickets _self;
  final $Res Function(_LoadedTickets) _then;

/// Create a copy of HousekeepingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tickets = null,}) {
  return _then(_LoadedTickets(
null == tickets ? _self._tickets : tickets // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

/// @nodoc


class _LoadedDashboard implements HousekeepingState {
  const _LoadedDashboard(final  Map<String, dynamic> dashboard): _dashboard = dashboard;
  

 final  Map<String, dynamic> _dashboard;
 Map<String, dynamic> get dashboard {
  if (_dashboard is EqualUnmodifiableMapView) return _dashboard;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_dashboard);
}


/// Create a copy of HousekeepingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedDashboardCopyWith<_LoadedDashboard> get copyWith => __$LoadedDashboardCopyWithImpl<_LoadedDashboard>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadedDashboard&&const DeepCollectionEquality().equals(other._dashboard, _dashboard));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_dashboard));

@override
String toString() {
  return 'HousekeepingState.loadedDashboard(dashboard: $dashboard)';
}


}

/// @nodoc
abstract mixin class _$LoadedDashboardCopyWith<$Res> implements $HousekeepingStateCopyWith<$Res> {
  factory _$LoadedDashboardCopyWith(_LoadedDashboard value, $Res Function(_LoadedDashboard) _then) = __$LoadedDashboardCopyWithImpl;
@useResult
$Res call({
 Map<String, dynamic> dashboard
});




}
/// @nodoc
class __$LoadedDashboardCopyWithImpl<$Res>
    implements _$LoadedDashboardCopyWith<$Res> {
  __$LoadedDashboardCopyWithImpl(this._self, this._then);

  final _LoadedDashboard _self;
  final $Res Function(_LoadedDashboard) _then;

/// Create a copy of HousekeepingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? dashboard = null,}) {
  return _then(_LoadedDashboard(
null == dashboard ? _self._dashboard : dashboard // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
