import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'api_interceptor.dart';

part 'dio_client.g.dart';

@riverpod
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage();
}

@riverpod
Dio dioClient(Ref ref) {
  // Use dart-define for physical device IP, fallback to emulator IP 10.0.2.2 or localhost
  const baseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://pms-bvko.onrender.com/api/v1');

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
    ApiInterceptor(storage),
    RetryInterceptor(dio: dio),
    LogInterceptor(requestBody: true, responseBody: true),
  ]);

  return dio;
}

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryInterval;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryInterval = const Duration(seconds: 2),
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    
    final errorString = err.error?.toString() ?? '';
    final messageString = err.message ?? '';
    
    // Check if we should retry: network timeouts, connection errors, socket resets, handshake exceptions
    final isNetworkError = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        errorString.contains('SocketException') ||
        errorString.contains('HandshakeException') ||
        errorString.contains('Connection reset') ||
        messageString.contains('SocketException') ||
        messageString.contains('HandshakeException') ||
        messageString.contains('Connection reset');

    final extra = Map<String, dynamic>.from(requestOptions.extra);
    final int currentRetry = (extra['retry_count'] as int?) ?? 0;

    if (isNetworkError && currentRetry < maxRetries) {
      extra['retry_count'] = currentRetry + 1;
      requestOptions.extra = extra;
      
      // Exponential backoff delay
      final delay = retryInterval * (currentRetry + 1);
      await Future.delayed(delay);

      try {
        final response = await dio.request(
          requestOptions.path,
          data: requestOptions.data,
          queryParameters: requestOptions.queryParameters,
          options: Options(
            method: requestOptions.method,
            headers: requestOptions.headers,
            contentType: requestOptions.contentType,
            responseType: requestOptions.responseType,
            extra: requestOptions.extra,
          ),
        );
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        return handler.next(retryErr);
      } catch (e) {
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
