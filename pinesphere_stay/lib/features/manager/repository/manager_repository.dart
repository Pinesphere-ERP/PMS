import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/manager/models/dashboard_model.dart';
import 'package:pinesphere_stay/features/manager/services/manager_api_service.dart';
import 'package:pinesphere_stay/core/network/tenant_provider.dart';

final managerRepositoryProvider = Provider<ManagerRepository>((ref) {
  final apiService = ref.watch(managerApiServiceProvider);
  // Using the propertyId from tenant_provider if available, or pass explicitly
  final propertyId = ref.watch(tenantProvider);
  return ManagerRepository(apiService, propertyId ?? '');
});

class ManagerRepository {
  final ManagerApiService _apiService;
  final String _propertyId;

  ManagerRepository(this._apiService, this._propertyId);

  String get propertyId => _propertyId;

  // ── Dashboard ──
  Future<ManagerDashboardResponse> getDashboard() {
    return _apiService.getDashboard(_propertyId);
  }

  // ── Staff ──
  Future<List<dynamic>> getStaff() => _apiService.getStaff(_propertyId);
  Future<List<dynamic>> getAttendance({String? date, String? staffId}) => _apiService.getAttendance(_propertyId, date: date, staffId: staffId);
  Future<List<dynamic>> getPerformance({String? staffId}) => _apiService.getPerformance(_propertyId, staffId: staffId);
  Future<dynamic> assignTask(Map<String, dynamic> payload) => _apiService.assignTask({...payload, 'property_id': _propertyId});
  Future<dynamic> createShift(Map<String, dynamic> payload) => _apiService.createShift({...payload, 'property_id': _propertyId});
  Future<List<dynamic>> getShifts({String? date, String? staffId}) => _apiService.getShifts(_propertyId, date: date, staffId: staffId);

  // ── Bookings ──
  Future<List<dynamic>> getBookings({String? status, String? fromDate, String? toDate, int skip = 0, int limit = 50}) =>
      _apiService.getBookings(_propertyId, status: status, fromDate: fromDate, toDate: toDate, skip: skip, limit: limit);
  Future<dynamic> getBookingDetail(String bookingId) => _apiService.getBookingDetail(bookingId);
  Future<dynamic> modifyBooking(String bookingId, Map<String, dynamic> payload) => _apiService.modifyBooking(bookingId, payload);
  Future<dynamic> changeRoom(String bookingId, Map<String, dynamic> payload) => _apiService.changeRoom(bookingId, payload);
  Future<dynamic> confirmBooking(String bookingId) => _apiService.confirmBooking(bookingId);

  // ── Check-ins ──
  Future<List<dynamic>> getCheckinFeed({String? statusFilter}) => _apiService.getCheckinFeed(_propertyId, statusFilter: statusFilter);
  Future<List<dynamic>> getCheckoutFeed() => _apiService.getCheckoutFeed(_propertyId);
  Future<List<dynamic>> getRoomReadiness() => _apiService.getRoomReadiness(_propertyId);

  // ── Housekeeping ──
  Future<List<dynamic>> getHousekeepingProgress({String? statusFilter}) => _apiService.getHousekeepingProgress(_propertyId, statusFilter: statusFilter);
  Future<dynamic> assignHousekeeping(Map<String, dynamic> payload) => _apiService.assignHousekeeping({...payload, 'property_id': _propertyId});
  Future<dynamic> reassignHousekeeping(String taskId, Map<String, dynamic> payload) => _apiService.reassignHousekeeping(taskId, payload);
  Future<dynamic> inspectHousekeepingTask(String taskId, Map<String, dynamic> payload) => _apiService.inspectHousekeepingTask(taskId, payload);
  Future<dynamic> closeHousekeepingTask(String taskId, Map<String, dynamic> payload) => _apiService.closeHousekeepingTask(taskId, payload);

  // ── Maintenance ──
  Future<List<dynamic>> getMaintenanceTickets({String? statusFilter, int skip = 0, int limit = 50}) =>
      _apiService.getMaintenanceTickets(_propertyId, statusFilter: statusFilter, skip: skip, limit: limit);
  Future<dynamic> createMaintenanceIssue(Map<String, dynamic> payload) => _apiService.createMaintenanceIssue({...payload, 'property_id': _propertyId});
  Future<dynamic> assignMaintenanceTechnician(String ticketId, Map<String, dynamic> payload) => _apiService.assignMaintenanceTechnician(ticketId, payload);
  Future<dynamic> updateMaintenanceTicket(String ticketId, Map<String, dynamic> payload) => _apiService.updateMaintenanceTicket(ticketId, payload);
  Future<dynamic> closeMaintenanceIssue(String ticketId) => _apiService.closeMaintenanceIssue(ticketId);

  // ── Reports ──
  Future<dynamic> getOperationalReport(String fromDate, String toDate) => _apiService.getOperationalReport(_propertyId, fromDate, toDate);
  Future<dynamic> getOccupancyReport(String fromDate, String toDate) => _apiService.getOccupancyReport(_propertyId, fromDate, toDate);
  Future<dynamic> getHousekeepingReport(String fromDate, String toDate) => _apiService.getHousekeepingReport(_propertyId, fromDate, toDate);
  Future<dynamic> getMaintenanceReport(String fromDate, String toDate) => _apiService.getMaintenanceReport(_propertyId, fromDate, toDate);
  Future<dynamic> getStaffPerformanceReport(String fromDate, String toDate) => _apiService.getStaffPerformanceReport(_propertyId, fromDate, toDate);

  // ── Room Blocks ──
  Future<List<dynamic>> getRoomBlocks({bool activeOnly = true}) => _apiService.getRoomBlocks(_propertyId, activeOnly: activeOnly);
  Future<dynamic> createRoomBlock(Map<String, dynamic> payload) => _apiService.createRoomBlock({...payload, 'property_id': _propertyId});
  Future<dynamic> releaseRoomBlock(String blockId) => _apiService.releaseRoomBlock(blockId);

  // ── Manager Notes ──
  Future<List<dynamic>> getNotes({String? noteType, bool? isResolved, int skip = 0, int limit = 50}) =>
      _apiService.getNotes(_propertyId, noteType: noteType, isResolved: isResolved, skip: skip, limit: limit);
  Future<dynamic> createNote(Map<String, dynamic> payload) => _apiService.createNote({...payload, 'property_id': _propertyId});
  Future<dynamic> resolveNote(String noteId) => _apiService.resolveNote(noteId);
  Future<dynamic> deleteNote(String noteId) => _apiService.deleteNote(noteId);

  // ── Checklists ──
  Future<List<dynamic>> getChecklists({String? date, String? shift}) => _apiService.getChecklists(_propertyId, date: date, shift: shift);
  Future<dynamic> startChecklist(Map<String, dynamic> payload) => _apiService.startChecklist({...payload, 'property_id': _propertyId});
  Future<dynamic> updateChecklist(String checklistId, Map<String, dynamic> payload) => _apiService.updateChecklist(checklistId, payload);
  Future<dynamic> signOffChecklist(String checklistId, Map<String, dynamic> payload) => _apiService.signOffChecklist(checklistId, payload);

  // ── Service Requests ──
  Future<List<dynamic>> getServiceRequests({String? statusFilter, int skip = 0, int limit = 50}) =>
      _apiService.getServiceRequests(_propertyId, statusFilter: statusFilter, skip: skip, limit: limit);
  Future<dynamic> assignServiceRequest(String requestId, Map<String, dynamic> payload) => _apiService.assignServiceRequest(requestId, payload);
}
