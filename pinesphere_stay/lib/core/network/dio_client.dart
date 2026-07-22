import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pinesphere_stay/core/sync/queue/sync_operation.dart';
import 'package:pinesphere_stay/main.dart';
import 'api_interceptor.dart';

part 'dio_client.g.dart';

@riverpod
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage();
}

@riverpod
Dio dioClient(Ref ref) {
  // Use dart-define for physical device IP, fallback to hosted backend
  const baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://127.0.0.1:8000/api/v1');

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 90),
      receiveTimeout: const Duration(seconds: 90),
      contentType: 'application/json',
    ),
  );

  final storage = ref.watch(secureStorageProvider);
  
  dio.interceptors.addAll([
    ApiInterceptor(storage, ref),
    OfflineOutboxInterceptor(),
    LogInterceptor(requestBody: true, responseBody: true),
  ]);

  return dio;
}

class OfflineOutboxInterceptor extends Interceptor {
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isNetworkError = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        err.error.toString().contains('SocketException');

    // If hosted backend (render) fails, automatically fallback to local server
    if (isNetworkError && err.requestOptions.baseUrl.contains('onrender.com')) {
      try {
        final localBaseUrl = defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:8000/api/v1'
            : 'http://localhost:8000/api/v1';

        final options = err.requestOptions;
        options.baseUrl = localBaseUrl;
        final fallbackDio = Dio();
        final response = await fallbackDio.fetch(options);
        return handler.resolve(response);
      } catch (_) {}
    }

    final method = err.requestOptions.method.toUpperCase();

    // If it's a mutating request, not an auth endpoint, and the network is down, queue it!
    final isAuth = err.requestOptions.path.contains('/auth/');
    if (isNetworkError && !isAuth && ['POST', 'PUT', 'PATCH', 'DELETE'].contains(method)) {
      try {
        final box = databaseService.store.box<SyncOperation>();
        
        // Extract entity info if provided in extra, otherwise fallback
        final extra = err.requestOptions.extra;
        final entityType = extra['entity_type'] ?? 'Unknown';
        final entityId = extra['entity_id'] ?? err.requestOptions.path;
        final operationType = method == 'DELETE' ? 'delete' : (method == 'POST' ? 'create' : 'update');
        
        final payload = err.requestOptions.data != null ? jsonEncode(err.requestOptions.data) : '{}';

        final syncOp = SyncOperation(
          entityType: entityType,
          entityId: entityId,
          operationType: operationType,
          payload: payload,
          createdAt: DateTime.now(),
        );

        box.put(syncOp);
        
        // Resolve with a mock success response so the app thinks it worked
        return handler.resolve(
          Response(
            requestOptions: err.requestOptions,
            statusCode: 202,
            data: {'message': 'Saved offline. Will sync later.', 'offline': true},
          ),
        );
      } catch (e) {
        // Fallback to error if DB fails
      }
    }

    return handler.next(err);
  }
}
