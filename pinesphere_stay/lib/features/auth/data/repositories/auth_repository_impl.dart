import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/device_info.dart';
import '../../../../core/permissions/user_role.dart';
import 'dart:convert';
import '../../domain/models/user_model.dart';
import '../models/login_request_dto.dart';
import '../../../../main.dart';
import '../../../../features/bookings/domain/models/booking_entity.dart';
import '../../../../features/rooms/domain/models/room_entity.dart';
import '../../../../features/guests/domain/models/guest_entity.dart';
import '../../../../features/checkin/domain/models/checkin_entity.dart';
import '../../../../features/checkout/domain/models/checkout_entity.dart';
import '../../../../features/sync/domain/models/sync_queue_entity.dart';

part 'auth_repository_impl.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepository(dio, secureStorage);
}

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  AuthRepository(this._dio, this._secureStorage);

  Future<Either<Failure, UserModel>> login(String email, String password) async {
    try {


      final deviceInfo = DeviceInfoService(_secureStorage);
      final fingerprint = await deviceInfo.getDeviceFingerprint();
      final deviceName = await deviceInfo.getDeviceName();

      final request = LoginRequestDto(
        email: email,
        password: password,
        deviceId: fingerprint,
        deviceName: deviceName,
        deviceFingerprint: fingerprint,
      );

      final response = await _dio.post('/auth/login', data: request.toJson());
      final tokenResponse = TokenResponseDto.fromJson(response.data);

      await _secureStorage.write(key: 'access_token', value: tokenResponse.accessToken);
      await _secureStorage.write(key: 'refresh_token', value: tokenResponse.refreshToken);
      
      final List<dynamic>? rawProperties = response.data['properties'];
      if (rawProperties != null) {
        await _secureStorage.write(key: 'accessible_properties', value: jsonEncode(rawProperties));
      }

      // Decode JWT to get user_id and tenant_id
      final parts = tokenResponse.accessToken.split('.');
      if (parts.length != 3) {
        throw Exception('invalid token');
      }
      
      String output = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (output.length % 4) {
        case 0: break;
        case 2: output += '=='; break;
        case 3: output += '='; break;
        default: throw Exception('Illegal base64url string!"');
      }
      final payloadStr = utf8.decode(base64Url.decode(output));
      final payload = jsonDecode(payloadStr);

      final userId = payload['sub']?.toString() ?? 'unknown_id';
      final propertyId = payload['tenant_id']?.toString();

      final user = UserModel(
        id: userId,
        name: email.split('@')[0], // Placeholder until /me is added
        email: email,
        role: UserRole.owner, // Placeholder
        propertyId: propertyId,
      );
      
      await _secureStorage.write(key: 'cached_user', value: jsonEncode(user.toJson()));
      await _secureStorage.write(key: 'device_uid', value: fingerprint);
      if (propertyId != null) {
        await _secureStorage.write(key: 'tenant_id', value: propertyId);
      }

      // Wipe local database on successful login to prevent conflicts
      // We will pull the fresh state from the cloud immediately after.
      try {
        final store = objectBox.store;
        store.box<BookingEntity>().removeAll();
        store.box<RoomEntity>().removeAll();
        store.box<GuestEntity>().removeAll();
        store.box<CheckInEntity>().removeAll();
        store.box<CheckOutEntity>().removeAll();
        store.box<SyncQueueEntity>().removeAll();
        await _secureStorage.delete(key: 'last_sync_timestamp');
      } catch (e) {
        debugPrint("Failed to clear local db on login: $e");
      }

      return Right(user);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
        return Left(Failure.auth(e.response?.data['detail'] ?? 'Invalid credentials'));
      }
      return Left(Failure.server('Server error occurred', statusCode: e.response?.statusCode));
    } catch (e, stack) {
      return Left(Failure.unknown(e.toString(), error: e, stackTrace: stack));
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'tenant_id');
    await _secureStorage.delete(key: 'cached_user');
  }

  Future<UserModel?> getCachedUser() async {
    final token = await _secureStorage.read(key: 'access_token');
    if (token == null) return null;

    final userJsonStr = await _secureStorage.read(key: 'cached_user');
    if (userJsonStr == null) return null;

    try {
      final json = jsonDecode(userJsonStr);
      return UserModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }
}
