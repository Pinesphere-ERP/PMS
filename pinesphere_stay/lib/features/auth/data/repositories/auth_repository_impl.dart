import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/device_info.dart';
import '../models/login_request_dto.dart';

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

  Future<Either<Failure, void>> login(String email, String password) async {
    try {
      if (password == '1234') {
        // Prototype bypass
        await _secureStorage.write(key: 'access_token', value: 'mock_token');
        return const Right(null);
      }

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

      return const Right(null);
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
  }

  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: 'access_token');
    return token != null;
  }
}
