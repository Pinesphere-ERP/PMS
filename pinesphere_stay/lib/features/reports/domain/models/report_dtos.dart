import 'package:freezed_annotation/freezed_annotation.dart';

part 'report_dtos.freezed.dart';
part 'report_dtos.g.dart';

@freezed
abstract class DailyReportDto with _$DailyReportDto {
  const factory DailyReportDto({
    @JsonKey(name: 'report_date') required String reportDate,
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'total_checkins') required int totalCheckins,
    @JsonKey(name: 'total_checkouts') required int totalCheckouts,
    @JsonKey(name: 'occupied_rooms') required int occupiedRooms,
    @JsonKey(name: 'vacant_rooms') required int vacantRooms,
    @JsonKey(name: 'new_bookings') required int newBookings,
    @JsonKey(name: 'cancelled_bookings') required int cancelledBookings,
    @JsonKey(name: 'revenue_collected') required double revenueCollected,
    @JsonKey(name: 'pending_payments') required double pendingPayments,
    @JsonKey(name: 'housekeeping_completed') required int housekeepingCompleted,
    @JsonKey(name: 'housekeeping_pending') required int housekeepingPending,
    @JsonKey(name: 'total_rooms') required int totalRooms,
    @JsonKey(name: 'occupancy_pct') required double occupancyPct,
  }) = _DailyReportDto;

  const DailyReportDto._();

  factory DailyReportDto.fromJson(Map<String, dynamic> json) =>
      _$DailyReportDtoFromJson(json);
}

@freezed
abstract class MonthlyReportDto with _$MonthlyReportDto {
  const factory MonthlyReportDto({
    @JsonKey(name: 'property_id') required String propertyId,
    required int month,
    required int year,
    @JsonKey(name: 'total_bookings') required int totalBookings,
    @JsonKey(name: 'occupancy_pct') required double occupancyPct,
    @JsonKey(name: 'total_revenue') required double totalRevenue,
    @JsonKey(name: 'total_collected') required double totalCollected,
    @JsonKey(name: 'total_outstanding') required double totalOutstanding,
    @JsonKey(name: 'total_expenses') required double totalExpenses,
    @JsonKey(name: 'cancelled_bookings') required int cancelledBookings,
    @JsonKey(name: 'prev_month_revenue') required double prevMonthRevenue,
    @JsonKey(name: 'revenue_growth_pct') required double revenueGrowthPct,
    @JsonKey(name: 'daily_revenue_trend') required List<Map<String, dynamic>> dailyRevenueTrend,
  }) = _MonthlyReportDto;

  const MonthlyReportDto._();

  factory MonthlyReportDto.fromJson(Map<String, dynamic> json) =>
      _$MonthlyReportDtoFromJson(json);
}

@freezed
abstract class OccupancyReportDto with _$OccupancyReportDto {
  const factory OccupancyReportDto({
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'start_date') required String startDate,
    @JsonKey(name: 'end_date') required String endDate,
    @JsonKey(name: 'total_rooms') required int totalRooms,
    @JsonKey(name: 'avg_occupancy_pct') required double avgOccupancyPct,
    @JsonKey(name: 'occupied_room_nights') required int occupiedRoomNights,
    @JsonKey(name: 'available_room_nights') required int availableRoomNights,
    @JsonKey(name: 'reserved_rooms_today') required int reservedRoomsToday,
    @JsonKey(name: 'daily_occupancy') required List<Map<String, dynamic>> dailyOccupancy,
    @JsonKey(name: 'by_room_type') required List<Map<String, dynamic>> byRoomType,
  }) = _OccupancyReportDto;

  const OccupancyReportDto._();

  factory OccupancyReportDto.fromJson(Map<String, dynamic> json) =>
      _$OccupancyReportDtoFromJson(json);
}

@freezed
abstract class RevenueReportDto with _$RevenueReportDto {
  const factory RevenueReportDto({
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'start_date') required String startDate,
    @JsonKey(name: 'end_date') required String endDate,
    @JsonKey(name: 'total_revenue') required double totalRevenue,
    @JsonKey(name: 'by_room_type') required List<Map<String, dynamic>> byRoomType,
    @JsonKey(name: 'by_booking_source') required List<Map<String, dynamic>> byBookingSource,
    @JsonKey(name: 'by_payment_method') required List<Map<String, dynamic>> byPaymentMethod,
    @JsonKey(name: 'taxes_collected') required double taxesCollected,
    @JsonKey(name: 'discounts_given') required double discountsGiven,
    @JsonKey(name: 'daily_revenue_trend') required List<Map<String, dynamic>> dailyRevenueTrend,
  }) = _RevenueReportDto;

  const RevenueReportDto._();

  factory RevenueReportDto.fromJson(Map<String, dynamic> json) =>
      _$RevenueReportDtoFromJson(json);
}

@freezed
abstract class CollectionReportDto with _$CollectionReportDto {
  const factory CollectionReportDto({
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'start_date') required String startDate,
    @JsonKey(name: 'end_date') required String endDate,
    @JsonKey(name: 'total_collections') required double totalCollections,
    @JsonKey(name: 'cash_collections') required double cashCollections,
    @JsonKey(name: 'card_collections') required double cardCollections,
    @JsonKey(name: 'upi_collections') required double upiCollections,
    @JsonKey(name: 'bank_transfer_collections') required double bankTransferCollections,
    @JsonKey(name: 'other_collections') required double otherCollections,
    @JsonKey(name: 'by_method') required List<Map<String, dynamic>> byMethod,
    @JsonKey(name: 'daily_collections') required List<Map<String, dynamic>> dailyCollections,
  }) = _CollectionReportDto;

  const CollectionReportDto._();

  factory CollectionReportDto.fromJson(Map<String, dynamic> json) =>
      _$CollectionReportDtoFromJson(json);
}

@freezed
abstract class OutstandingReportDto with _$OutstandingReportDto {
  const factory OutstandingReportDto({
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'start_date') required String startDate,
    @JsonKey(name: 'end_date') required String endDate,
    @JsonKey(name: 'total_outstanding') required double totalOutstanding,
    @JsonKey(name: 'pending_invoices_count') required int pendingInvoicesCount,
    @JsonKey(name: 'overdue_count') required int overdueCount,
    @JsonKey(name: 'customer_wise') required List<Map<String, dynamic>> customerWise,
    required Map<String, double> ageing,
  }) = _OutstandingReportDto;

  const OutstandingReportDto._();

  factory OutstandingReportDto.fromJson(Map<String, dynamic> json) =>
      _$OutstandingReportDtoFromJson(json);
}

@freezed
abstract class ExpenseDto with _$ExpenseDto {
  const factory ExpenseDto({
    @JsonKey(name: 'expense_id') required String expenseId,
    @JsonKey(name: 'property_id') required String propertyId,
    required String category,
    required String description,
    required double amount,
    @JsonKey(name: 'expense_date') required String expenseDate,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _ExpenseDto;

  const ExpenseDto._();

  factory ExpenseDto.fromJson(Map<String, dynamic> json) =>
      _$ExpenseDtoFromJson(json);
}

@freezed
abstract class ExpensesReportDto with _$ExpensesReportDto {
  const factory ExpensesReportDto({
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'start_date') required String startDate,
    @JsonKey(name: 'end_date') required String endDate,
    @JsonKey(name: 'total_expenses') required double totalExpenses,
    @JsonKey(name: 'by_category') required List<Map<String, dynamic>> byCategory,
    @JsonKey(name: 'monthly_trend') required List<Map<String, dynamic>> monthlyTrend,
    @JsonKey(name: 'recent_expenses') required List<ExpenseDto> recentExpenses,
  }) = _ExpensesReportDto;

  const ExpensesReportDto._();

  factory ExpensesReportDto.fromJson(Map<String, dynamic> json) =>
      _$ExpensesReportDtoFromJson(json);
}

@freezed
abstract class BestCustomerRowDto with _$BestCustomerRowDto {
  const factory BestCustomerRowDto({
    @JsonKey(name: 'guest_id') required String guestId,
    @JsonKey(name: 'guest_name') required String guestName,
    @JsonKey(name: 'total_bookings') required int totalBookings,
    @JsonKey(name: 'total_nights') required int totalNights,
    @JsonKey(name: 'total_revenue') required double totalRevenue,
    @JsonKey(name: 'avg_booking_value') required double avgBookingValue,
    @JsonKey(name: 'last_stay_date') String? lastStayDate,
  }) = _BestCustomerRowDto;

  const BestCustomerRowDto._();

  factory BestCustomerRowDto.fromJson(Map<String, dynamic> json) =>
      _$BestCustomerRowDtoFromJson(json);
}

@freezed
abstract class BestCustomersReportDto with _$BestCustomersReportDto {
  const factory BestCustomersReportDto({
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'start_date') required String startDate,
    @JsonKey(name: 'end_date') required String endDate,
    required List<BestCustomerRowDto> customers,
  }) = _BestCustomersReportDto;

  const BestCustomersReportDto._();

  factory BestCustomersReportDto.fromJson(Map<String, dynamic> json) =>
      _$BestCustomersReportDtoFromJson(json);
}

@freezed
abstract class RoomUtilizationRowDto with _$RoomUtilizationRowDto {
  const factory RoomUtilizationRowDto({
    @JsonKey(name: 'room_id') required String roomId,
    @JsonKey(name: 'room_number') required String roomNumber,
    @JsonKey(name: 'room_type') required String roomType,
    @JsonKey(name: 'total_bookings') required int totalBookings,
    @JsonKey(name: 'occupied_nights') required int occupiedNights,
    @JsonKey(name: 'idle_days') required int idleDays,
    @JsonKey(name: 'occupancy_pct') required double occupancyPct,
    required double revenue,
  }) = _RoomUtilizationRowDto;

  const RoomUtilizationRowDto._();

  factory RoomUtilizationRowDto.fromJson(Map<String, dynamic> json) =>
      _$RoomUtilizationRowDtoFromJson(json);
}

@freezed
abstract class RoomUtilizationReportDto with _$RoomUtilizationReportDto {
  const factory RoomUtilizationReportDto({
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'start_date') required String startDate,
    @JsonKey(name: 'end_date') required String endDate,
    required List<RoomUtilizationRowDto> rooms,
    @JsonKey(name: 'most_utilized') String? mostUtilized,
    @JsonKey(name: 'least_utilized') String? leastUtilized,
  }) = _RoomUtilizationReportDto;

  const RoomUtilizationReportDto._();

  factory RoomUtilizationReportDto.fromJson(Map<String, dynamic> json) =>
      _$RoomUtilizationReportDtoFromJson(json);
}

@freezed
abstract class StaffPerformanceRowDto with _$StaffPerformanceRowDto {
  const factory StaffPerformanceRowDto({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'staff_name') required String staffName,
    required String role,
    @JsonKey(name: 'tasks_completed') required int tasksCompleted,
    @JsonKey(name: 'tasks_pending') required int tasksPending,
    @JsonKey(name: 'housekeeping_tasks') required int housekeepingTasks,
    @JsonKey(name: 'bookings_handled') required int bookingsHandled,
    @JsonKey(name: 'avg_task_completion_hours') double? avgTaskCompletionHours,
  }) = _StaffPerformanceRowDto;

  const StaffPerformanceRowDto._();

  factory StaffPerformanceRowDto.fromJson(Map<String, dynamic> json) =>
      _$StaffPerformanceRowDtoFromJson(json);
}

@freezed
abstract class StaffPerformanceReportDto with _$StaffPerformanceReportDto {
  const factory StaffPerformanceReportDto({
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'start_date') required String startDate,
    @JsonKey(name: 'end_date') required String endDate,
    required List<StaffPerformanceRowDto> staff,
    @JsonKey(name: 'total_tasks_completed') required int totalTasksCompleted,
    @JsonKey(name: 'total_tasks_pending') required int totalTasksPending,
  }) = _StaffPerformanceReportDto;

  const StaffPerformanceReportDto._();

  factory StaffPerformanceReportDto.fromJson(Map<String, dynamic> json) =>
      _$StaffPerformanceReportDtoFromJson(json);
}
