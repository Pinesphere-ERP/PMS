import 'dart:convert';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  final token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5OWU4MTI1NC05YjgwLTRmMmMtYjIzZC1jZWUzNzNhZWQxMDEiLCJ0ZW5hbnRfaWQiOiI1MTFlNWY4Yi1iYjFlLTRmNzYtYTgxNy02MTMzNjEzZjFkZDAiLCJqdGkiOiIxNWY4NThkNi1hM2QyLTRlOWQtODg0MC03NGU1ZjhhNDVkMWIiLCJkZXZpY2VfZnAiOiJwb3J0YWwiLCJleHAiOjE3ODQ2NTM3MDcsInR5cGUiOiJhY2Nlc3MifQ.HO5Zy5ZcuC3GfcLEyVTJEet35No_a-3LNA5hg7ZUfJQ';
  final propertyId = '511e5f8b-bb1e-4f76-a817-6133613f1dd0';

  final payload = {
    'property_id': '',
    'name': 'test',
    'property_type': 'HOTEL',
    'star_category': 3,
    'address': '',
    'city': '',
    'state': '',
    'country': '',
    'zip_code': '',
    'latitude': 0.0,
    'longitude': 0.0,
    'amenities': [],
    'images': [],
    'check_in_time': '',
    'check_out_time': '',
    'cancellation_policy': '',
    'house_rules': '',
    'current_step': 5,
    'is_completed': false,
    'status': 'payment_pending'
  };

  try {
    final response = await dio.post(
      'https://pinesphere-erp-pms.onrender.com/api/v1/properties/$propertyId/complete-onboarding',
      data: payload,
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'content-type': 'application/json'
      }),
    );
    print('SUCCESS: ${response.statusCode} - ${response.data}');
  } on DioException catch (e) {
    print('ERROR: ${e.response?.statusCode} - ${e.response?.data}');
  } catch (e) {
    print('UNKNOWN ERROR: $e');
  }
}
