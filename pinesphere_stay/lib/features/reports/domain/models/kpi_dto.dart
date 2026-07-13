import 'package:freezed_annotation/freezed_annotation.dart';

part 'kpi_dto.freezed.dart';
part 'kpi_dto.g.dart';

@freezed
abstract class KpiSnapshotDto with _$KpiSnapshotDto {
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

  const KpiSnapshotDto._();

  factory KpiSnapshotDto.fromJson(Map<String, dynamic> json) =>
      _$KpiSnapshotDtoFromJson(json);
}

@freezed
abstract class MonthlyPLRowDto with _$MonthlyPLRowDto {
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

  const MonthlyPLRowDto._();

  factory MonthlyPLRowDto.fromJson(Map<String, dynamic> json) =>
      _$MonthlyPLRowDtoFromJson(json);
}

@freezed
abstract class PLReportDto with _$PLReportDto {
  const factory PLReportDto({
    required String propertyId,
    required String periodStart,
    required String periodEnd,
    required List<MonthlyPLRowDto> monthlyBreakdown,
    required double summaryTotalRevenue,
    required double summaryTotalExpenses,
    required double summaryNetProfit,
  }) = _PLReportDto;

  const PLReportDto._();

  factory PLReportDto.fromJson(Map<String, dynamic> json) =>
      _$PLReportDtoFromJson(json);
}

@freezed
abstract class GSTReturnDto with _$GSTReturnDto {
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

  const GSTReturnDto._();

  factory GSTReturnDto.fromJson(Map<String, dynamic> json) =>
      _$GSTReturnDtoFromJson(json);
}

@freezed
abstract class ReportTemplateDto with _$ReportTemplateDto {
  const factory ReportTemplateDto({
    required String templateId,
    String? propertyId,
    required String reportName,
    required String reportType,
    Map<String, dynamic>? configurationJson,
  }) = _ReportTemplateDto;

  const ReportTemplateDto._();

  factory ReportTemplateDto.fromJson(Map<String, dynamic> json) =>
      _$ReportTemplateDtoFromJson(json);
}

@freezed
abstract class ScheduledReportDto with _$ScheduledReportDto {
  const factory ScheduledReportDto({
    required String scheduleId,
    required String templateId,
    required String recipientRole,
    required String deliveryChannel,
    required String frequency,
    required bool isActive,
  }) = _ScheduledReportDto;

  const ScheduledReportDto._();

  factory ScheduledReportDto.fromJson(Map<String, dynamic> json) =>
      _$ScheduledReportDtoFromJson(json);
}
