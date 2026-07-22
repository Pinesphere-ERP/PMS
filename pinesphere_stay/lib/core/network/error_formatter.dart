import 'package:dio/dio.dart';

String formatError(dynamic error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. Please check your internet connection.';
    } else if (error.type == DioExceptionType.badResponse) {
      if (error.response?.data != null) {
        final data = error.response!.data;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('detail')) {
            final detail = data['detail'];
            if (detail is List && detail.isNotEmpty && detail[0] is Map) {
              return detail[0]['msg']?.toString() ?? detail.toString();
            }
            return detail.toString();
          } else if (data.containsKey('message')) {
            return data['message'].toString();
          } else if (data.containsKey('error')) {
            return data['error'].toString();
          }
        }
        return data.toString();
      }
      return 'Server error: ${error.response?.statusCode}';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    } else {
      return 'Network error: ${error.message}';
    }
  }
  return error.toString();
}
