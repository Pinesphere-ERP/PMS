import 'package:freezed_annotation/freezed_annotation.dart';

part 'kpi_dto.freezed.dart';
part 'kpi_dto.g.dart';

@freezed
abstract class KpiSnapshotDto with _$KpiSnapshotDto {
  const factory KpiSnapshotDto({
    @JsonKey(name: 'snapshot_id') required String snapshotId,
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'snapshot_date') required String snapshotDate,
    @JsonKey(name: 'occupied_rooms') required int occupiedRooms,
    @JsonKey(name: 'vacant_rooms') required int vacantRooms,
    @JsonKey(name: 'revenue_room_rent') required double revenueRoomRent,
    @JsonKey(name: 'revenue_addons') required double revenueAddons,
    @JsonKey(name: 'expenses_amount') required double expensesAmount,
    @JsonKey(name: 'outstanding_payments') required double outstandingPayments,
    @JsonKey(name: 'gst_collected') required double gstCollected,
  }) = _KpiSnapshotDto;

  const KpiSnapshotDto._();

  factory KpiSnapshotDto.fromJson(Map<String, dynamic> json) =>
      _$KpiSnapshotDtoFromJson(json);
}

@freezed
abstract class MonthlyPLRowDto with _$MonthlyPLRowDto {
  const factory MonthlyPLRowDto({
    required String month,
    @JsonKey(name: 'total_room_rent') required double totalRoomRent,
    @JsonKey(name: 'total_addons') required double totalAddons,
    @JsonKey(name: 'total_revenue') required double totalRevenue,
    @JsonKey(name: 'total_expenses') required double totalExpenses,
    @JsonKey(name: 'net_profit') required double netProfit,
    @JsonKey(name: 'gst_collected') required double gstCollected,
    required double outstanding,
  }) = _MonthlyPLRowDto;

  const MonthlyPLRowDto._();

  factory MonthlyPLRowDto.fromJson(Map<String, dynamic> json) =>
      _$MonthlyPLRowDtoFromJson(json);
}

@freezed
abstract class PLReportDto with _$PLReportDto {
  const factory PLReportDto({
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'period_start') required String periodStart,
    @JsonKey(name: 'period_end') required String periodEnd,
    @JsonKey(name: 'monthly_breakdown') required List<MonthlyPLRowDto> monthlyBreakdown,
    @JsonKey(name: 'summary_total_revenue') required double summaryTotalRevenue,
    @JsonKey(name: 'summary_total_expenses') required double summaryTotalExpenses,
    @JsonKey(name: 'summary_net_profit') required double summaryNetProfit,
  }) = _PLReportDto;

  const PLReportDto._();

  factory PLReportDto.fromJson(Map<String, dynamic> json) =>
      _$PLReportDtoFromJson(json);
}

@freezed
abstract class GSTReturnDto with _$GSTReturnDto {
  const factory GSTReturnDto({
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'period_start') required String periodStart,
    @JsonKey(name: 'period_end') required String periodEnd,
    @JsonKey(name: 'total_taxable_revenue') required double totalTaxableRevenue,
    @JsonKey(name: 'total_gst_collected') required double totalGstCollected,
    required double cgst,
    required double sgst,
    required double igst,
    @JsonKey(name: 'monthly_gst') required List<Map<String, dynamic>> monthlyGst,
  }) = _GSTReturnDto;

  const GSTReturnDto._();

  factory GSTReturnDto.fromJson(Map<String, dynamic> json) =>
      _$GSTReturnDtoFromJson(json);
}

@freezed
abstract class ReportTemplateDto with _$ReportTemplateDto {
  const factory ReportTemplateDto({
    @JsonKey(name: 'template_id') required String templateId,
    @JsonKey(name: 'property_id') String? propertyId,
    @JsonKey(name: 'report_name') required String reportName,
    @JsonKey(name: 'report_type') required String reportType,
    @JsonKey(name: 'configuration_json') Map<String, dynamic>? configurationJson,
  }) = _ReportTemplateDto;

  const ReportTemplateDto._();

  factory ReportTemplateDto.fromJson(Map<String, dynamic> json) =>
      _$ReportTemplateDtoFromJson(json);
}

@freezed
abstract class ScheduledReportDto with _$ScheduledReportDto {
  const factory ScheduledReportDto({
    @JsonKey(name: 'schedule_id') required String scheduleId,
    @JsonKey(name: 'template_id') required String templateId,
    @JsonKey(name: 'recipient_role') required String recipientRole,
    @JsonKey(name: 'delivery_channel') required String deliveryChannel,
    required String frequency,
    @JsonKey(name: 'is_active') required bool isActive,
  }) = _ScheduledReportDto;

  const ScheduledReportDto._();

  factory ScheduledReportDto.fromJson(Map<String, dynamic> json) =>
      _$ScheduledReportDtoFromJson(json);
}
