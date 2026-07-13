import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../audit/data/audit_service.dart';
import '../../data/housekeeping_service.dart';

part 'housekeeping_provider.freezed.dart';
part 'housekeeping_provider.g.dart';

@freezed
class HousekeepingState with _$HousekeepingState {
  const factory HousekeepingState.initial() = _Initial;
  const factory HousekeepingState.loading() = _Loading;
  const factory HousekeepingState.success(String message) = _Success;
  const factory HousekeepingState.error(String message) = _Error;
  const factory HousekeepingState.loadedTasks(List<Map<String, dynamic>> tasks) = _LoadedTasks;
  const factory HousekeepingState.loadedMaintenanceTickets(List<Map<String, dynamic>> tickets) = _LoadedTickets;
  const factory HousekeepingState.loadedDashboard(Map<String, dynamic> dashboard) = _LoadedDashboard;
}

@riverpod
class HousekeepingNotifier extends _$HousekeepingNotifier {
  @override
  HousekeepingState build() => const HousekeepingState.initial();

  Future<void> getDashboard(String propertyId) async {
    state = const HousekeepingState.loading();
    try {
      final service = ref.read(housekeepingServiceProvider);
      final dashboard = await service.getDashboard(propertyId);
      state = HousekeepingState.loadedDashboard(dashboard);
    } catch (e) {
      state = HousekeepingState.error(e.toString());
    }
  }

  Future<void> getTasks(String propertyId, {String? status, String? staffId}) async {
    state = const HousekeepingState.loading();
    try {
      final service = ref.read(housekeepingServiceProvider);
      final rawTasks = await service.getTasks(propertyId, status: status, staffId: staffId);
      final tasks = rawTasks
          .map((t) => t is Map<String, dynamic> ? t : Map<String, dynamic>.from(t as Map))
          .toList();
      state = HousekeepingState.loadedTasks(tasks);
    } catch (e) {
      state = HousekeepingState.error(e.toString());
    }
  }

  Future<void> createTask({required Map<String, dynamic> data}) async {
    state = const HousekeepingState.loading();
    try {
      ref.read(auditServiceProvider).log(
        moduleName: 'housekeeping',
        actionType: 'create_task',
        targetEntity: 'housekeeping_task',
        targetRecordId: data['id']?.toString() ?? '',
        propertyId: data['property_id']?.toString(),
        newValue: data,
      );
      final service = ref.read(housekeepingServiceProvider);
      await service.createTask(data);
      state = const HousekeepingState.success('Task created successfully');
    } catch (e) {
      state = HousekeepingState.error(e.toString());
    }
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    state = const HousekeepingState.loading();
    try {
      ref.read(auditServiceProvider).log(
        moduleName: 'housekeeping',
        actionType: 'update_task',
        targetEntity: 'housekeeping_task',
        targetRecordId: taskId,
        propertyId: data['property_id']?.toString(),
        newValue: data,
      );
      final service = ref.read(housekeepingServiceProvider);
      await service.updateTask(taskId, data);
      state = const HousekeepingState.success('Task updated successfully');
    } catch (e) {
      state = HousekeepingState.error(e.toString());
    }
  }

  Future<void> inspectTask(String taskId, Map<String, dynamic> data) async {
    state = const HousekeepingState.loading();
    try {
      ref.read(auditServiceProvider).log(
        moduleName: 'housekeeping',
        actionType: 'inspect_task',
        targetEntity: 'housekeeping_task',
        targetRecordId: taskId,
        propertyId: data['property_id']?.toString(),
        newValue: data,
      );
      final service = ref.read(housekeepingServiceProvider);
      await service.inspectTask(taskId, data);
      state = const HousekeepingState.success('Inspection submitted');
    } catch (e) {
      state = HousekeepingState.error(e.toString());
    }
  }

  Future<void> getMaintenanceTickets(String propertyId, {String? status, String? category}) async {
    state = const HousekeepingState.loading();
    try {
      final service = ref.read(housekeepingServiceProvider);
      final rawTickets = await service.getMaintenanceTickets(propertyId, status: status, category: category);
      final tickets = rawTickets
          .map((t) => t is Map<String, dynamic> ? t : Map<String, dynamic>.from(t as Map))
          .toList();
      state = HousekeepingState.loadedMaintenanceTickets(tickets);
    } catch (e) {
      state = HousekeepingState.error(e.toString());
    }
  }

  Future<void> createMaintenanceTicket({required Map<String, dynamic> data}) async {
    state = const HousekeepingState.loading();
    try {
      ref.read(auditServiceProvider).log(
        moduleName: 'housekeeping',
        actionType: 'create_maintenance_ticket',
        targetEntity: 'maintenance_ticket',
        targetRecordId: data['id']?.toString() ?? '',
        propertyId: data['property_id']?.toString(),
        newValue: data,
      );
      final service = ref.read(housekeepingServiceProvider);
      await service.createMaintenanceTicket(data);
      state = const HousekeepingState.success('Maintenance ticket created');
    } catch (e) {
      state = HousekeepingState.error(e.toString());
    }
  }

  Future<void> updateMaintenanceTicket(String ticketId, Map<String, dynamic> data) async {
    state = const HousekeepingState.loading();
    try {
      ref.read(auditServiceProvider).log(
        moduleName: 'housekeeping',
        actionType: 'update_maintenance_ticket',
        targetEntity: 'maintenance_ticket',
        targetRecordId: ticketId,
        propertyId: data['property_id']?.toString(),
        newValue: data,
      );
      final service = ref.read(housekeepingServiceProvider);
      await service.updateMaintenanceTicket(ticketId, data);
      state = const HousekeepingState.success('Ticket updated successfully');
    } catch (e) {
      state = HousekeepingState.error(e.toString());
    }
  }
}
