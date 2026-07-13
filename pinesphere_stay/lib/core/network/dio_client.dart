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
    LogInterceptor(requestBody: true, responseBody: true),
  ]);

  return dio;
}
