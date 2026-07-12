// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kpi_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KpiSnapshotDto _$KpiSnapshotDtoFromJson(Map<String, dynamic> json) =>
    _KpiSnapshotDto(
      snapshotId: json['snapshotId'] as String,
      propertyId: json['propertyId'] as String,
      snapshotDate: json['snapshotDate'] as String,
      occupiedRooms: (json['occupiedRooms'] as num).toInt(),
      vacantRooms: (json['vacantRooms'] as num).toInt(),
      revenueRoomRent: (json['revenueRoomRent'] as num).toDouble(),
      revenueAddons: (json['revenueAddons'] as num).toDouble(),
      expensesAmount: (json['expensesAmount'] as num).toDouble(),
      outstandingPayments: (json['outstandingPayments'] as num).toDouble(),
      gstCollected: (json['gstCollected'] as num).toDouble(),
    );

Map<String, dynamic> _$KpiSnapshotDtoToJson(_KpiSnapshotDto instance) =>
    <String, dynamic>{
      'snapshotId': instance.snapshotId,
      'propertyId': instance.propertyId,
      'snapshotDate': instance.snapshotDate,
      'occupiedRooms': instance.occupiedRooms,
      'vacantRooms': instance.vacantRooms,
      'revenueRoomRent': instance.revenueRoomRent,
      'revenueAddons': instance.revenueAddons,
      'expensesAmount': instance.expensesAmount,
      'outstandingPayments': instance.outstandingPayments,
      'gstCollected': instance.gstCollected,
    };

_MonthlyPLRowDto _$MonthlyPLRowDtoFromJson(Map<String, dynamic> json) =>
    _MonthlyPLRowDto(
      month: json['month'] as String,
      totalRoomRent: (json['totalRoomRent'] as num).toDouble(),
      totalAddons: (json['totalAddons'] as num).toDouble(),
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalExpenses: (json['totalExpenses'] as num).toDouble(),
      netProfit: (json['netProfit'] as num).toDouble(),
      gstCollected: (json['gstCollected'] as num).toDouble(),
      outstanding: (json['outstanding'] as num).toDouble(),
    );

Map<String, dynamic> _$MonthlyPLRowDtoToJson(_MonthlyPLRowDto instance) =>
    <String, dynamic>{
      'month': instance.month,
      'totalRoomRent': instance.totalRoomRent,
      'totalAddons': instance.totalAddons,
      'totalRevenue': instance.totalRevenue,
      'totalExpenses': instance.totalExpenses,
      'netProfit': instance.netProfit,
      'gstCollected': instance.gstCollected,
      'outstanding': instance.outstanding,
    };

_PLReportDto _$PLReportDtoFromJson(Map<String, dynamic> json) => _PLReportDto(
  propertyId: json['propertyId'] as String,
  periodStart: json['periodStart'] as String,
  periodEnd: json['periodEnd'] as String,
  monthlyBreakdown: (json['monthlyBreakdown'] as List<dynamic>)
      .map((e) => MonthlyPLRowDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  summaryTotalRevenue: (json['summaryTotalRevenue'] as num).toDouble(),
  summaryTotalExpenses: (json['summaryTotalExpenses'] as num).toDouble(),
  summaryNetProfit: (json['summaryNetProfit'] as num).toDouble(),
);

Map<String, dynamic> _$PLReportDtoToJson(_PLReportDto instance) =>
    <String, dynamic>{
      'propertyId': instance.propertyId,
      'periodStart': instance.periodStart,
      'periodEnd': instance.periodEnd,
      'monthlyBreakdown': instance.monthlyBreakdown,
      'summaryTotalRevenue': instance.summaryTotalRevenue,
      'summaryTotalExpenses': instance.summaryTotalExpenses,
      'summaryNetProfit': instance.summaryNetProfit,
    };

_GSTReturnDto _$GSTReturnDtoFromJson(Map<String, dynamic> json) =>
    _GSTReturnDto(
      propertyId: json['propertyId'] as String,
      periodStart: json['periodStart'] as String,
      periodEnd: json['periodEnd'] as String,
      totalTaxableRevenue: (json['totalTaxableRevenue'] as num).toDouble(),
      totalGstCollected: (json['totalGstCollected'] as num).toDouble(),
      cgst: (json['cgst'] as num).toDouble(),
      sgst: (json['sgst'] as num).toDouble(),
      igst: (json['igst'] as num).toDouble(),
      monthlyGst: (json['monthlyGst'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$GSTReturnDtoToJson(_GSTReturnDto instance) =>
    <String, dynamic>{
      'propertyId': instance.propertyId,
      'periodStart': instance.periodStart,
      'periodEnd': instance.periodEnd,
      'totalTaxableRevenue': instance.totalTaxableRevenue,
      'totalGstCollected': instance.totalGstCollected,
      'cgst': instance.cgst,
      'sgst': instance.sgst,
      'igst': instance.igst,
      'monthlyGst': instance.monthlyGst,
    };

_ReportTemplateDto _$ReportTemplateDtoFromJson(Map<String, dynamic> json) =>
    _ReportTemplateDto(
      templateId: json['templateId'] as String,
      propertyId: json['propertyId'] as String?,
      reportName: json['reportName'] as String,
      reportType: json['reportType'] as String,
      configurationJson: json['configurationJson'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ReportTemplateDtoToJson(_ReportTemplateDto instance) =>
    <String, dynamic>{
      'templateId': instance.templateId,
      'propertyId': instance.propertyId,
      'reportName': instance.reportName,
      'reportType': instance.reportType,
      'configurationJson': instance.configurationJson,
    };

_ScheduledReportDto _$ScheduledReportDtoFromJson(Map<String, dynamic> json) =>
    _ScheduledReportDto(
      scheduleId: json['scheduleId'] as String,
      templateId: json['templateId'] as String,
      recipientRole: json['recipientRole'] as String,
      deliveryChannel: json['deliveryChannel'] as String,
      frequency: json['frequency'] as String,
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$ScheduledReportDtoToJson(_ScheduledReportDto instance) =>
    <String, dynamic>{
      'scheduleId': instance.scheduleId,
      'templateId': instance.templateId,
      'recipientRole': instance.recipientRole,
      'deliveryChannel': instance.deliveryChannel,
      'frequency': instance.frequency,
      'isActive': instance.isActive,
    };
