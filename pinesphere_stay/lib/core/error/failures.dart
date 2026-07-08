import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
sealed class Failure with _$Failure {
  const factory Failure.network(String message) = _NetworkFailure;
  const factory Failure.server(String message, {int? statusCode}) = _ServerFailure;
  const factory Failure.cache(String message) = _CacheFailure;
  const factory Failure.auth(String message) = _AuthFailure;
  const factory Failure.unknown(String message, {Object? error, StackTrace? stackTrace}) = _UnknownFailure;
}
