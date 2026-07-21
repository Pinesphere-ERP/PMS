import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/core/network/dio_client.dart';
import 'package:pinesphere_stay/core/auth/session_context.dart';
import '../../domain/models/staff_member_model.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(
    ref.watch(dioClientProvider),
    ref.watch(sessionContextProvider).activePropertyId,
  );
});

class StaffRepository {
  final Dio _dio;
  final String? _activePropertyId;

  StaffRepository(this._dio, this._activePropertyId);

  Future<List<StaffMemberModel>> getStaffList() async {
    if (_activePropertyId == null) return [];
    try {
      final response = await _dio.get('/staff/property/$_activePropertyId');
      if (response.data is List) {
        return (response.data as List).map((e) => StaffMemberModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      // In offline mode, we might fetch from ObjectBox here
      return [];
    }
  }

  Future<bool> inviteStaff({
    required String mobileNumber,
    required String name,
    required String roleId,
  }) async {
    if (_activePropertyId == null) return false;
    try {
      final response = await _dio.post('/staff/invite', data: {
        'mobile_number': mobileNumber,
        'name': name,
        'role_id': roleId,
        'property_id': _activePropertyId,
      });
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateStaffStatus(String staffId, String status) async {
    try {
      final response = await _dio.patch('/staff/$staffId/status', data: {
        'status': status,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
