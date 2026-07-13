// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kpi_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KpiSnapshotDto _$KpiSnapshotDtoFromJson(Map<String, dynamic> json) =>
    _KpiSnapshotDto(
      snapshotId: json['snapshot_id'] as String,
      propertyId: json['property_id'] as String,
      snapshotDate: json['snapshot_date'] as String,
      occupiedRooms: (json['occupied_rooms'] as num).toInt(),
      vacantRooms: (json['vacant_rooms'] as num).toInt(),
      revenueRoomRent: (json['revenue_room_rent'] as num).toDouble(),
      revenueAddons: (json['revenue_addons'] as num).toDouble(),
      expensesAmount: (json['expenses_amount'] as num).toDouble(),
      outstandingPayments: (json['outstanding_payments'] as num).toDouble(),
      gstCollected: (json['gst_collected'] as num).toDouble(),
    );

Map<String, dynamic> _$KpiSnapshotDtoToJson(_KpiSnapshotDto instance) =>
    <String, dynamic>{
      'snapshot_id': instance.snapshotId,
      'property_id': instance.propertyId,
      'snapshot_date': instance.snapshotDate,
      'occupied_rooms': instance.occupiedRooms,
      'vacant_rooms': instance.vacantRooms,
      'revenue_room_rent': instance.revenueRoomRent,
      'revenue_addons': instance.revenueAddons,
      'expenses_amount': instance.expensesAmount,
      'outstanding_payments': instance.outstandingPayments,
      'gst_collected': instance.gstCollected,
    };

_MonthlyPLRowDto _$MonthlyPLRowDtoFromJson(Map<String, dynamic> json) =>
    _MonthlyPLRowDto(
      month: json['month'] as String,
      totalRoomRent: (json['total_room_rent'] as num).toDouble(),
      totalAddons: (json['total_addons'] as num).toDouble(),
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      totalExpenses: (json['total_expenses'] as num).toDouble(),
      netProfit: (json['net_profit'] as num).toDouble(),
      gstCollected: (json['gst_collected'] as num).toDouble(),
      outstanding: (json['outstanding'] as num).toDouble(),
    );

Map<String, dynamic> _$MonthlyPLRowDtoToJson(_MonthlyPLRowDto instance) =>
    <String, dynamic>{
      'month': instance.month,
      'total_room_rent': instance.totalRoomRent,
      'total_addons': instance.totalAddons,
      'total_revenue': instance.totalRevenue,
      'total_expenses': instance.totalExpenses,
      'net_profit': instance.netProfit,
      'gst_collected': instance.gstCollected,
      'outstanding': instance.outstanding,
    };

_PLReportDto _$PLReportDtoFromJson(Map<String, dynamic> json) => _PLReportDto(
  propertyId: json['property_id'] as String,
  periodStart: json['period_start'] as String,
  periodEnd: json['period_end'] as String,
  monthlyBreakdown: (json['monthly_breakdown'] as List<dynamic>)
      .map((e) => MonthlyPLRowDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  summaryTotalRevenue: (json['summary_total_revenue'] as num).toDouble(),
  summaryTotalExpenses: (json['summary_total_expenses'] as num).toDouble(),
  summaryNetProfit: (json['summary_net_profit'] as num).toDouble(),
);

Map<String, dynamic> _$PLReportDtoToJson(_PLReportDto instance) =>
    <String, dynamic>{
      'property_id': instance.propertyId,
      'period_start': instance.periodStart,
      'period_end': instance.periodEnd,
      'monthly_breakdown': instance.monthlyBreakdown
          .map((e) => e.toJson())
          .toList(),
      'summary_total_revenue': instance.summaryTotalRevenue,
      'summary_total_expenses': instance.summaryTotalExpenses,
      'summary_net_profit': instance.summaryNetProfit,
    };

_GSTReturnDto _$GSTReturnDtoFromJson(Map<String, dynamic> json) =>
    _GSTReturnDto(
      propertyId: json['property_id'] as String,
      periodStart: json['period_start'] as String,
      periodEnd: json['period_end'] as String,
      totalTaxableRevenue: (json['total_taxable_revenue'] as num).toDouble(),
      totalGstCollected: (json['total_gst_collected'] as num).toDouble(),
      cgst: (json['cgst'] as num).toDouble(),
      sgst: (json['sgst'] as num).toDouble(),
      igst: (json['igst'] as num).toDouble(),
      monthlyGst: (json['monthly_gst'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$GSTReturnDtoToJson(_GSTReturnDto instance) =>
    <String, dynamic>{
      'property_id': instance.propertyId,
      'period_start': instance.periodStart,
      'period_end': instance.periodEnd,
      'total_taxable_revenue': instance.totalTaxableRevenue,
      'total_gst_collected': instance.totalGstCollected,
      'cgst': instance.cgst,
      'sgst': instance.sgst,
      'igst': instance.igst,
      'monthly_gst': instance.monthlyGst,
    };

_ReportTemplateDto _$ReportTemplateDtoFromJson(Map<String, dynamic> json) =>
    _ReportTemplateDto(
      templateId: json['template_id'] as String,
      propertyId: json['property_id'] as String?,
      reportName: json['report_name'] as String,
      reportType: json['report_type'] as String,
      configurationJson: json['configuration_json'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ReportTemplateDtoToJson(_ReportTemplateDto instance) =>
    <String, dynamic>{
      'template_id': instance.templateId,
      'property_id': instance.propertyId,
      'report_name': instance.reportName,
      'report_type': instance.reportType,
      'configuration_json': instance.configurationJson,
    };

_ScheduledReportDto _$ScheduledReportDtoFromJson(Map<String, dynamic> json) =>
    _ScheduledReportDto(
      scheduleId: json['schedule_id'] as String,
      templateId: json['template_id'] as String,
      recipientRole: json['recipient_role'] as String,
      deliveryChannel: json['delivery_channel'] as String,
      frequency: json['frequency'] as String,
      isActive: json['is_active'] as bool,
    );

Map<String, dynamic> _$ScheduledReportDtoToJson(_ScheduledReportDto instance) =>
    <String, dynamic>{
      'schedule_id': instance.scheduleId,
      'template_id': instance.templateId,
      'recipient_role': instance.recipientRole,
      'delivery_channel': instance.deliveryChannel,
      'frequency': instance.frequency,
      'is_active': instance.isActive,
    };
