import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/session_context.dart';

class ApiInterceptor extends Interceptor {
  final FlutterSecureStorage secureStorage;
  final Ref ref;

  ApiInterceptor(this.secureStorage, this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Inject Access Token
    final accessToken = await secureStorage.read(key: 'access_token');
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    // Inject Tenant / Property context headers
    final tenantId = await secureStorage.read(key: 'tenant_id');
    if (tenantId != null) {
      options.headers['X-Tenant-ID'] = tenantId;
    }

    // Inject the active property context for multi-property owners
    final activePropertyId = await secureStorage.read(key: 'active_property_id');
    if (activePropertyId != null) {
      options.headers['X-Active-Property-Id'] = activePropertyId;
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await secureStorage.delete(key: 'access_token');
    } else if (err.response?.statusCode == 402) {
      ref.read(sessionContextProvider.notifier).forcePaymentPending();
    }
    super.onError(err, handler);
  }
}
