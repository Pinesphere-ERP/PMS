import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/core/network/dio_client.dart';
import 'package:pinesphere_stay/features/manager/models/dashboard_model.dart';

final managerApiServiceProvider = Provider<ManagerApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ManagerApiService(dio);
});

class ManagerApiService {
  final Dio _dio;

  ManagerApiService(this._dio);

  // ── Dashboard ──
  Future<ManagerDashboardResponse> getDashboard(String propertyId) async {
    final response = await _dio.get('/manager/dashboard', queryParameters: {'property_id': propertyId});
    return ManagerDashboardResponse.fromJson(response.data);
  }

  // ── Staff ──
  Future<List<dynamic>> getStaff(String propertyId) async {
    final response = await _dio.get('/manager/staff', queryParameters: {'property_id': propertyId});
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getAttendance(String propertyId, {String? date, String? staffId}) async {
    final query = {'property_id': propertyId};
    if (date != null) query['attendance_date'] = date;
    if (staffId != null) query['staff_id'] = staffId;
    final response = await _dio.get('/manager/staff/attendance', queryParameters: query);
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getPerformance(String propertyId, {String? staffId}) async {
    final query = {'property_id': propertyId};
    if (staffId != null) query['staff_id'] = staffId;
    final response = await _dio.get('/manager/staff/performance', queryParameters: query);
    return response.data as List<dynamic>;
  }

  Future<dynamic> assignTask(Map<String, dynamic> payload) async {
    final response = await _dio.post('/manager/staff/assign-task', data: payload);
    return response.data;
  }

  Future<dynamic> createShift(Map<String, dynamic> payload) async {
    final response = await _dio.post('/manager/staff/shifts', data: payload);
    return response.data;
  }

  Future<List<dynamic>> getShifts(String propertyId, {String? date, String? staffId}) async {
    final query = {'property_id': propertyId};
    if (date != null) query['shift_date'] = date;
    if (staffId != null) query['staff_id'] = staffId;
    final response = await _dio.get('/manager/staff/shifts', queryParameters: query);
    return response.data as List<dynamic>;
  }

  // ── Bookings ──
  Future<List<dynamic>> getBookings(String propertyId, {String? status, String? fromDate, String? toDate, int skip = 0, int limit = 50}) async {
    final query = {'property_id': propertyId, 'skip': skip, 'limit': limit};
    if (status != null) query['booking_status'] = status;
    if (fromDate != null) query['from_date'] = fromDate;
    if (toDate != null) query['to_date'] = toDate;
    final response = await _dio.get('/manager/bookings', queryParameters: query);
    return response.data as List<dynamic>;
  }

  Future<dynamic> getBookingDetail(String bookingId) async {
    final response = await _dio.get('/manager/bookings/$bookingId');
    return response.data;
  }

  Future<dynamic> modifyBooking(String bookingId, Map<String, dynamic> payload) async {
    final response = await _dio.patch('/manager/bookings/$bookingId', data: payload);
    return response.data;
  }

  Future<dynamic> changeRoom(String bookingId, Map<String, dynamic> payload) async {
    final response = await _dio.post('/manager/bookings/$bookingId/change-room', data: payload);
    return response.data;
  }

  Future<dynamic> confirmBooking(String bookingId) async {
    final response = await _dio.post('/manager/bookings/$bookingId/confirm');
    return response.data;
  }

  // ── Check-ins ──
  Future<List<dynamic>> getCheckinFeed(String propertyId, {String? statusFilter}) async {
    final query = {'property_id': propertyId};
    if (statusFilter != null) query['status_filter'] = statusFilter;
    final response = await _dio.get('/manager/checkins', queryParameters: query);
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getCheckoutFeed(String propertyId) async {
    final response = await _dio.get('/manager/checkouts', queryParameters: {'property_id': propertyId});
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getRoomReadiness(String propertyId) async {
    final response = await _dio.get('/manager/rooms/readiness', queryParameters: {'property_id': propertyId});
    return response.data as List<dynamic>;
  }

  // ── Housekeeping ──
  Future<List<dynamic>> getHousekeepingProgress(String propertyId, {String? statusFilter}) async {
    final query = {'property_id': propertyId};
    if (statusFilter != null) query['status_filter'] = statusFilter;
    final response = await _dio.get('/manager/housekeeping', queryParameters: query);
    return response.data as List<dynamic>;
  }

  Future<dynamic> assignHousekeeping(Map<String, dynamic> payload) async {
    final response = await _dio.post('/manager/housekeeping/assign', data: payload);
    return response.data;
  }

  Future<dynamic> reassignHousekeeping(String taskId, Map<String, dynamic> payload) async {
    final response = await _dio.patch('/manager/housekeeping/$taskId/reassign', data: payload);
    return response.data;
  }

  Future<dynamic> inspectHousekeepingTask(String taskId, Map<String, dynamic> payload) async {
    final response = await _dio.post('/manager/housekeeping/$taskId/inspect', data: payload);
    return response.data;
  }

  Future<dynamic> closeHousekeepingTask(String taskId, Map<String, dynamic> payload) async {
    final response = await _dio.post('/manager/housekeeping/$taskId/close', data: payload);
    return response.data;
  }

  // ── Maintenance ──
  Future<List<dynamic>> getMaintenanceTickets(String propertyId, {String? statusFilter, int skip = 0, int limit = 50}) async {
    final query = {'property_id': propertyId, 'skip': skip, 'limit': limit};
    if (statusFilter != null) query['status_filter'] = statusFilter;
    final response = await _dio.get('/manager/maintenance', queryParameters: query);
    return response.data as List<dynamic>;
  }

  Future<dynamic> createMaintenanceIssue(Map<String, dynamic> payload) async {
    final response = await _dio.post('/manager/maintenance', data: payload);
    return response.data;
  }

  Future<dynamic> assignMaintenanceTechnician(String ticketId, Map<String, dynamic> payload) async {
    final response = await _dio.post('/manager/maintenance/$ticketId/assign', data: payload);
    return response.data;
  }

  Future<dynamic> updateMaintenanceTicket(String ticketId, Map<String, dynamic> payload) async {
    final response = await _dio.patch('/manager/maintenance/$ticketId', data: payload);
    return response.data;
  }

  Future<dynamic> closeMaintenanceIssue(String ticketId) async {
    final response = await _dio.post('/manager/maintenance/$ticketId/close');
    return response.data;
  }

  // ── Reports ──
  Future<dynamic> getOperationalReport(String propertyId, String fromDate, String toDate) async {
    final response = await _dio.get('/manager/reports/operational', queryParameters: {'property_id': propertyId, 'from_date': fromDate, 'to_date': toDate});
    return response.data;
  }

  Future<dynamic> getOccupancyReport(String propertyId, String fromDate, String toDate) async {
    final response = await _dio.get('/manager/reports/occupancy', queryParameters: {'property_id': propertyId, 'from_date': fromDate, 'to_date': toDate});
    return response.data;
  }

  Future<dynamic> getHousekeepingReport(String propertyId, String fromDate, String toDate) async {
    final response = await _dio.get('/manager/reports/housekeeping', queryParameters: {'property_id': propertyId, 'from_date': fromDate, 'to_date': toDate});
    return response.data;
  }

  Future<dynamic> getMaintenanceReport(String propertyId, String fromDate, String toDate) async {
    final response = await _dio.get('/manager/reports/maintenance', queryParameters: {'property_id': propertyId, 'from_date': fromDate, 'to_date': toDate});
    return response.data;
  }

  Future<dynamic> getStaffPerformanceReport(String propertyId, String fromDate, String toDate) async {
    final response = await _dio.get('/manager/reports/staff-performance', queryParameters: {'property_id': propertyId, 'from_date': fromDate, 'to_date': toDate});
    return response.data;
  }

  // ── Room Blocks ──
  Future<List<dynamic>> getRoomBlocks(String propertyId, {bool activeOnly = true}) async {
    final response = await _dio.get('/manager/room-blocks', queryParameters: {'property_id': propertyId, 'active_only': activeOnly});
    return response.data as List<dynamic>;
  }

  Future<dynamic> createRoomBlock(Map<String, dynamic> payload) async {
    final response = await _dio.post('/manager/room-blocks', data: payload);
    return response.data;
  }

  Future<dynamic> releaseRoomBlock(String blockId) async {
    final response = await _dio.delete('/manager/room-blocks/$blockId');
    return response.data;
  }

  // ── Manager Notes ──
  Future<List<dynamic>> getNotes(String propertyId, {String? noteType, bool? isResolved, int skip = 0, int limit = 50}) async {
    final query = {'property_id': propertyId, 'skip': skip, 'limit': limit};
    if (noteType != null) query['note_type'] = noteType;
    if (isResolved != null) query['is_resolved'] = isResolved;
    final response = await _dio.get('/manager/notes', queryParameters: query);
    return response.data as List<dynamic>;
  }

  Future<dynamic> createNote(Map<String, dynamic> payload) async {
    final response = await _dio.post('/manager/notes', data: payload);
    return response.data;
  }

  Future<dynamic> resolveNote(String noteId) async {
    final response = await _dio.post('/manager/notes/$noteId/resolve');
    return response.data;
  }

  Future<dynamic> deleteNote(String noteId) async {
    final response = await _dio.delete('/manager/notes/$noteId');
    return response.data;
  }

  // ── Checklists ──
  Future<List<dynamic>> getChecklists(String propertyId, {String? date, String? shift}) async {
    final query = {'property_id': propertyId};
    if (date != null) query['checklist_date'] = date;
    if (shift != null) query['shift'] = shift;
    final response = await _dio.get('/manager/checklists', queryParameters: query);
    return response.data as List<dynamic>;
  }

  Future<dynamic> startChecklist(Map<String, dynamic> payload) async {
    final response = await _dio.post('/manager/checklists', data: payload);
    return response.data;
  }

  Future<dynamic> updateChecklist(String checklistId, Map<String, dynamic> payload) async {
    final response = await _dio.patch('/manager/checklists/$checklistId', data: payload);
    return response.data;
  }

  Future<dynamic> signOffChecklist(String checklistId, Map<String, dynamic> payload) async {
    final response = await _dio.post('/manager/checklists/$checklistId/sign-off', data: payload);
    return response.data;
  }

  // ── Service Requests ──
  Future<List<dynamic>> getServiceRequests(String propertyId, {String? statusFilter, int skip = 0, int limit = 50}) async {
    final query = {'property_id': propertyId, 'skip': skip, 'limit': limit};
    if (statusFilter != null) query['status_filter'] = statusFilter;
    final response = await _dio.get('/manager/service-requests', queryParameters: query);
    return response.data as List<dynamic>;
  }

  Future<dynamic> assignServiceRequest(String requestId, Map<String, dynamic> payload) async {
    final response = await _dio.post('/manager/service-requests/$requestId/assign', data: payload);
    return response.data;
  }
}
