import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/manager/models/staff_model.dart';
import 'package:pinesphere_stay/features/manager/repository/manager_repository.dart';

final managerStaffProvider = FutureProvider.autoDispose<List<StaffMember>>((ref) async {
  final repository = ref.watch(managerRepositoryProvider);
  final data = await repository.getStaff();
  return data.map((e) => StaffMember.fromJson(e as Map<String, dynamic>)).toList();
});

final managerAttendanceProvider = FutureProvider.family.autoDispose<List<AttendanceRecord>, String?>((ref, date) async {
  final repository = ref.watch(managerRepositoryProvider);
  final data = await repository.getAttendance(date: date);
  return data.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList();
});

final managerPerformanceProvider = FutureProvider.autoDispose<List<PerformanceReview>>((ref) async {
  final repository = ref.watch(managerRepositoryProvider);
  final data = await repository.getPerformance();
  return data.map((e) => PerformanceReview.fromJson(e as Map<String, dynamic>)).toList();
});

final managerShiftsProvider = FutureProvider.family.autoDispose<List<ShiftSchedule>, String?>((ref, date) async {
  final repository = ref.watch(managerRepositoryProvider);
  final data = await repository.getShifts(date: date);
  return data.map((e) => ShiftSchedule.fromJson(e as Map<String, dynamic>)).toList();
});
