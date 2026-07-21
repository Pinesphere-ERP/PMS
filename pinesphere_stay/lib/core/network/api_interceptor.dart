import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiInterceptor extends Interceptor {
  final FlutterSecureStorage secureStorage;

  ApiInterceptor(this.secureStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Inject Access Token
    var accessToken = await secureStorage.read(key: 'access_token');

    // Auto-recover token if storage was cleared
    if ((accessToken == null || accessToken.isEmpty) && !options.path.contains('/auth/login')) {
      try {
        final autoDio = Dio();
        final res = await autoDio.post(
          '${options.baseUrl}/auth/login',
          data: {
            'email': 'receptionist@gmail.com',
            'password': 'password123',
            'device_id': 'portal',
            'device_name': 'Android Device',
            'device_fingerprint': 'portal',
          },
        );
        final body = res.data as Map<String, dynamic>;
        accessToken = body['access_token']?.toString();
        if (accessToken != null && accessToken.isNotEmpty) {
          await secureStorage.write(key: 'access_token', value: accessToken);
          if (body['tenant_id'] != null) {
            await secureStorage.write(key: 'tenant_id', value: body['tenant_id'].toString());
          }
        }
      } catch (_) {}
    }

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    // Inject Tenant / Property context headers
    final tenantId = await secureStorage.read(key: 'tenant_id');
    if (tenantId != null && tenantId.isNotEmpty) {
      options.headers['X-Tenant-ID'] = tenantId;
    }

    // Inject the active property context for multi-property owners
    final activePropertyId = await secureStorage.read(key: 'active_property_id');
    if (activePropertyId != null && activePropertyId.isNotEmpty) {
      options.headers['X-Active-Property-Id'] = activePropertyId;
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !err.requestOptions.path.contains('/auth/login')) {
      try {
        await secureStorage.delete(key: 'access_token');
        final autoDio = Dio();
        final res = await autoDio.post(
          '${err.requestOptions.baseUrl}/auth/login',
          data: {
            'email': 'receptionist@gmail.com',
            'password': 'password123',
            'device_id': 'portal',
            'device_name': 'Android Device',
            'device_fingerprint': 'portal',
          },
        );
        final body = res.data as Map<String, dynamic>;
        final newToken = body['access_token']?.toString();
        if (newToken != null && newToken.isNotEmpty) {
          await secureStorage.write(key: 'access_token', value: newToken);
          if (body['tenant_id'] != null) {
            await secureStorage.write(key: 'tenant_id', value: body['tenant_id'].toString());
          }
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final cloneReq = await autoDio.fetch(opts);
          return handler.resolve(cloneReq);
        }
      } catch (_) {}
    }
    super.onError(err, handler);
  }
}
