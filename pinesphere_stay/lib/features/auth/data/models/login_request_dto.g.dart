// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequestDto _$LoginRequestDtoFromJson(Map<String, dynamic> json) =>
    LoginRequestDto(
      email: json['email'] as String,
      password: json['password'] as String,
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String,
      deviceFingerprint: json['device_uid'] as String,
    );

Map<String, dynamic> _$LoginRequestDtoToJson(LoginRequestDto instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'device_id': instance.deviceId,
      'device_name': instance.deviceName,
      'device_uid': instance.deviceFingerprint,
    };

TokenResponseDto _$TokenResponseDtoFromJson(Map<String, dynamic> json) =>
    TokenResponseDto(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,
    );

Map<String, dynamic> _$TokenResponseDtoToJson(TokenResponseDto instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'token_type': instance.tokenType,
    };
