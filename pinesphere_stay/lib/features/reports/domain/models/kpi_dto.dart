import 'package:freezed_annotation/freezed_annotation.dart';

part 'kpi_dto.freezed.dart';
part 'kpi_dto.g.dart';

@freezed
class KpiSnapshotDto with _$KpiSnapshotDto {
  const factory KpiSnapshotDto({
    required String snapshotId,
    required String propertyId,
    required String snapshotDate,
    required int occupiedRooms,
    required int vacantRooms,
    required double revenueRoomRent,
    required double revenueAddons,
    required double expensesAmount,
    required double outstandingPayments,
    required double gstCollected,
  }) = _KpiSnapshotDto;

  factory KpiSnapshotDto.fromJson(Map<String, dynamic> json) =>
      _$KpiSnapshotDtoFromJson(json);
}

@freezed
class MonthlyPLRowDto with _$MonthlyPLRowDto {
  const factory MonthlyPLRowDto({
    required String month,
    required double totalRoomRent,
    required double totalAddons,
    required double totalRevenue,
    required double totalExpenses,
    required double netProfit,
    required double gstCollected,
    required double outstanding,
  }) = _MonthlyPLRowDto;

  factory MonthlyPLRowDto.fromJson(Map<String, dynamic> json) =>
      _$MonthlyPLRowDtoFromJson(json);
}

@freezed
class PLReportDto with _$PLReportDto {
  const factory PLReportDto({
    required String propertyId,
    required String periodStart,
    required String periodEnd,
    required List<MonthlyPLRowDto> monthlyBreakdown,
    required double summaryTotalRevenue,
    required double summaryTotalExpenses,
    required double summaryNetProfit,
  }) = _PLReportDto;

  factory PLReportDto.fromJson(Map<String, dynamic> json) =>
      _$PLReportDtoFromJson(json);
}

@freezed
class GSTReturnDto with _$GSTReturnDto {
  const factory GSTReturnDto({
    required String propertyId,
    required String periodStart,
    required String periodEnd,
    required double totalTaxableRevenue,
    required double totalGstCollected,
    required double cgst,
    required double sgst,
    required double igst,
    required List<Map<String, dynamic>> monthlyGst,
  }) = _GSTReturnDto;

  factory GSTReturnDto.fromJson(Map<String, dynamic> json) =>
      _$GSTReturnDtoFromJson(json);
}

@freezed
class ReportTemplateDto with _$ReportTemplateDto {
  const factory ReportTemplateDto({
    required String templateId,
    String? propertyId,
    required String reportName,
    required String reportType,
    Map<String, dynamic>? configurationJson,
  }) = _ReportTemplateDto;

  factory ReportTemplateDto.fromJson(Map<String, dynamic> json) =>
      _$ReportTemplateDtoFromJson(json);
}

@freezed
class ScheduledReportDto with _$ScheduledReportDto {
  const factory ScheduledReportDto({
    required String scheduleId,
    required String templateId,
    required String recipientRole,
    required String deliveryChannel,
    required String frequency,
    required bool isActive,
  }) = _ScheduledReportDto;

  factory ScheduledReportDto.fromJson(Map<String, dynamic> json) =>
      _$ScheduledReportDtoFromJson(json);
}
