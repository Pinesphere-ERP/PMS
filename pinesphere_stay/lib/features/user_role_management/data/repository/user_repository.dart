import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/error_formatter.dart';
import '../../../../core/permissions/user_role.dart';
import '../../../../core/utils/device_info.dart';
import '../../../../main.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/domain/models/accessible_property_model.dart';
import '../../domain/entities.dart';
import '../../domain/permission_set.dart';

part 'user_repository.g.dart';

@riverpod
UserRepository userRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return UserRepository(dio, secureStorage);
}

class UserRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final _uuid = const Uuid();

  UserRepository(this._dio, this._secureStorage);

  // Helper to hash password/PIN
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  Future<Either<Failure, UserModel>> loginOnline({
    required String email,
    required String password,
    required String pin,
  }) async {
    try {
      final deviceInfo = DeviceInfoService(_secureStorage);

      final deviceUid = await deviceInfo.getDeviceFingerprint();
      
      String platformStr = 'Unknown';
      String osVersionStr = 'Unknown';
      try {
        if (!kIsWeb) {
          platformStr = Platform.operatingSystem;
          osVersionStr = Platform.operatingSystemVersion;
        } else {
          platformStr = 'Web';
        }
      } catch (_) {}

      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'device_uid': deviceUid,
        'telemetry': {
          'device_type': 'mobile',
          'platform': platformStr,
          'os_version': osVersionStr,
          'app_version': '1.0.0', // from package_info ideally
        }
      });

      final accessToken = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;

      await _secureStorage.write(key: 'access_token', value: accessToken);
      await _secureStorage.write(key: 'refresh_token', value: refreshToken);

      // Perform offline bootstrap immediately to download hashes and permissions matrix
      final bootstrapRes = await _dio.post(
        '/auth/offline-bootstrap',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      final data = bootstrapRes.data;
      final userId = data['user_id'] as String;
      final name = data['name'] as String;
      final userEmail = (data['email'] as String?) ?? email;
      final roleCode = data['role_code'] as String;
      final role = UserRole.fromString(roleCode);
      final propertyId = data['property_id'] as String?;
      final onboardingStatus = data['onboarding_status'] as String?;
      final subscriptionStatus = data['subscription_status'] as String?;
      final trialEndsAt = data['trial_ends_at'] as String?;

      // Parse accessible properties list
      final rawProperties = data['accessible_properties'] as List<dynamic>? ?? [];
      final accessibleProperties = rawProperties
          .map((e) => AccessiblePropertyModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Cache credentials and PIN locally
      final pinHashLocal = _hashPin(pin);
      await _secureStorage.write(key: 'offline_pin_hash', value: pinHashLocal);
      await _secureStorage.write(key: 'cached_user_id', value: userId);

      final userModel = UserModel(
        id: userId,
        name: name,
        email: userEmail,
        role: role,
        roleCode: roleCode,
        mobileNumber: data['mobile_number'] as String?,
        propertyId: propertyId,
        onboardingStatus: onboardingStatus,
        subscriptionStatus: subscriptionStatus,
        trialEndsAt: trialEndsAt,
        accessibleProperties: accessibleProperties,
        isEmailVerified: true, // If they can log in, email is considered verified
      );
      await _secureStorage.write(key: 'cached_user', value: jsonEncode(userModel.toJson()));
      if (propertyId != null) {
        await _secureStorage.write(key: 'tenant_id', value: propertyId);
      }
      // Store accessible properties count for router
      await _secureStorage.write(
        key: 'accessible_property_count',
        value: accessibleProperties.length.toString(),
      );

      // Save user to ObjectBox
      final userDao = databaseService.userDao;
      var existingUser = userDao.getByServerId(userId);
      
      existingUser ??= userDao.getByEmail(userEmail);
      
      final userEntity = UserEntity(
        id: existingUser?.id ?? 0,
        serverId: userId,
        propertyId: propertyId,
        roleId: roleCode,
        name: name,
        email: userEmail,
        pinHash: pinHashLocal,
        isPrimaryOwner: role == UserRole.owner,
        status: 'ACTIVE',
      );
      userDao.put(userEntity);

      // Save permissions snapshot to ObjectBox
      final permissions = data['permissions'] as List<dynamic>;
      final rpDao = databaseService.rolePermDao;
      final permDao = databaseService.permDao;

      // Clear previous permissions mapping for this role
      final existingRPs = rpDao.getByRoleId(roleCode);
      for (final rp in existingRPs) {
        rpDao.remove(rp.id);
      }

      for (final permData in permissions) {
        final code = permData['permission_code'] as String;
        final accessLevel = permData['access_level'] as String;

        // Ensure PermissionEntity exists
        var permEntity = permDao.getByPermissionCode(code);
        if (permEntity == null) {
          permEntity = PermissionEntity(
            serverId: _uuid.v4(),
            permissionCode: code,
            moduleName: 'general',
          );
          permDao.put(permEntity);
        }

        final rpEntity = RolePermissionEntity(
          serverId: _uuid.v4(),
          roleId: roleCode,
          permissionId: code, // using permission code as identifier for simplicity locally
          accessLevel: accessLevel,
        );
        rpDao.put(rpEntity);
      }

      return Right(userModel);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
        return Left(Failure.auth(e.response?.data['detail'] ?? 'Invalid credentials'));
      }
      return Left(Failure.auth(formatError(e)));
    } catch (e, stack) {
      return Left(Failure.unknown(e.toString(), error: e, stackTrace: stack));
    }
  }

  Future<Either<Failure, UserModel>> loginOffline(String pin) async {
    try {
      final cachedUserId = await _secureStorage.read(key: 'cached_user_id');
      final cachedUserJson = await _secureStorage.read(key: 'cached_user');
      final offlinePinHash = await _secureStorage.read(key: 'offline_pin_hash');

      if (cachedUserId == null || cachedUserJson == null || offlinePinHash == null) {
        return Left(Failure.auth("No cached credentials found. Please sign in online first."));
      }

      final hashedInput = _hashPin(pin);
      if (hashedInput != offlinePinHash) {
        return Left(Failure.auth("Incorrect PIN"));
      }

      final user = UserModel.fromJson(jsonDecode(cachedUserJson));
      return Right(user);
    } catch (e, stack) {
      return Left(Failure.unknown(e.toString(), error: e, stackTrace: stack));
    }
  }

  Future<PermissionSet> getCachedPermissions() async {
    final cachedUserJson = await _secureStorage.read(key: 'cached_user');
    if (cachedUserJson == null) {
      return PermissionSet({});
    }

    final user = UserModel.fromJson(jsonDecode(cachedUserJson));
    final rpDao = databaseService.rolePermDao;
    final list = rpDao.getByRoleId(user.role.name);

    final mapped = list.map((rp) => {
      'permission_code': rp.permissionId,
      'access_level': rp.accessLevel,
    }).toList();

    return PermissionSet.fromList(mapped);
  }

  Future<UserModel?> getCachedUser() async {
    final cachedUserJson = await _secureStorage.read(key: 'cached_user');
    if (cachedUserJson == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(cachedUserJson));
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'cached_user_id');
    await _secureStorage.delete(key: 'cached_user');
    await _secureStorage.delete(key: 'offline_pin_hash');
  }
}
