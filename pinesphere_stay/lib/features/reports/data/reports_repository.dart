import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../audit/data/audit_service.dart';
import '../domain/models/kpi_dto.dart';
import '../domain/models/report_dtos.dart';
import '../../../../core/network/dio_client.dart';

part 'reports_repository.g.dart';

@riverpod
ReportsRepository reportsRepository(Ref ref) {
  return ReportsRepository(
    ref.watch(dioClientProvider),
    ref.watch(auditServiceProvider),
  );
}

class ReportsRepository {
  final Dio _dio;
  final AuditService _audit;

  ReportsRepository(this._dio, this._audit);

  Future<PLReportDto> getPLReport({
    required String propertyId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _dio.get(
      '/reports/pl',
      queryParameters: {
        'property_id': propertyId,
        'start_date': startDate,
        'end_date': endDate,
      },
    );
    return PLReportDto.fromJson(response.data);
  }

  Future<GSTReturnDto> getGSTReturns({
    required String propertyId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _dio.get(
      '/reports/gst-returns',
      queryParameters: {
        'property_id': propertyId,
        'start_date': startDate,
        'end_date': endDate,
      },
    );
    return GSTReturnDto.fromJson(response.data);
  }

  Future<List<ReportTemplateDto>> getTemplates(String propertyId) async {
    final response = await _dio.get(
      '/reports/templates',
      queryParameters: {'property_id': propertyId},
    );
    final items = response.data['items'] as List;
    return items.map((e) => ReportTemplateDto.fromJson(e)).toList();
  }

  Future<ReportTemplateDto> createTemplate({
    required String propertyId,
    required String reportName,
    required String reportType,
    Map<String, dynamic>? config,
  }) async {
    _audit.log(
      moduleName: 'reports',
      actionType: 'create_template',
      targetEntity: 'report_template',
      targetRecordId: reportName,
      propertyId: propertyId,
      newValue: {
        'report_name': reportName,
        'report_type': reportType,
        'configuration_json': config,
      },
    );
    final response = await _dio.post(
      '/reports/templates',
      queryParameters: {'property_id': propertyId},
      data: {
        'report_name': reportName,
        'report_type': reportType,
        'configuration_json': config,
      },
    );
    return ReportTemplateDto.fromJson(response.data);
  }

  Future<List<ScheduledReportDto>> getSchedules(String propertyId) async {
    final response = await _dio.get(
      '/reports/schedules',
      queryParameters: {'property_id': propertyId},
    );
    final items = response.data['items'] as List;
    return items.map((e) => ScheduledReportDto.fromJson(e)).toList();
  }

  // ── New Report Endpoints ─────────────────────────────────────

  Future<DailyReportDto> getDailyReport({
    required String propertyId,
    String? reportDate,
  }) async {
    final response = await _dio.get(
      '/reports/daily',
      queryParameters: {
        'property_id': propertyId,
        'report_date': reportDate,
      },
    );
    return DailyReportDto.fromJson(response.data);
  }

  Future<MonthlyReportDto> getMonthlyReport({
    required String propertyId,
    required int month,
    required int year,
  }) async {
    final response = await _dio.get(
      '/reports/monthly',
      queryParameters: {
        'property_id': propertyId,
        'month': month,
        'year': year,
      },
    );
    return MonthlyReportDto.fromJson(response.data);
  }

  Future<OccupancyReportDto> getOccupancyReport({
    required String propertyId,
    required String startDate,
    required String endDate,
    String? roomType,
  }) async {
    final response = await _dio.get(
      '/reports/occupancy',
      queryParameters: {
        'property_id': propertyId,
        'start_date': startDate,
        'end_date': endDate,
        'room_type': roomType,
      },
    );
    return OccupancyReportDto.fromJson(response.data);
  }

  Future<RevenueReportDto> getRevenueReport({
    required String propertyId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _dio.get(
      '/reports/revenue',
      queryParameters: {
        'property_id': propertyId,
        'start_date': startDate,
        'end_date': endDate,
      },
    );
    return RevenueReportDto.fromJson(response.data);
  }

  Future<CollectionReportDto> getCollectionReport({
    required String propertyId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _dio.get(
      '/reports/collection',
      queryParameters: {
        'property_id': propertyId,
        'start_date': startDate,
        'end_date': endDate,
      },
    );
    return CollectionReportDto.fromJson(response.data);
  }

  Future<OutstandingReportDto> getOutstandingReport({
    required String propertyId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _dio.get(
      '/reports/outstanding',
      queryParameters: {
        'property_id': propertyId,
        'start_date': startDate,
        'end_date': endDate,
      },
    );
    return OutstandingReportDto.fromJson(response.data);
  }

  Future<ExpensesReportDto> getExpensesReport({
    required String propertyId,
    required String startDate,
    required String endDate,
    String? category,
  }) async {
    final response = await _dio.get(
      '/reports/expenses',
      queryParameters: {
        'property_id': propertyId,
        'start_date': startDate,
        'end_date': endDate,
        'category': category,
      },
    );
    return ExpensesReportDto.fromJson(response.data);
  }

  Future<BestCustomersReportDto> getBestCustomers({
    required String propertyId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _dio.get(
      '/reports/best-customers',
      queryParameters: {
        'property_id': propertyId,
        'start_date': startDate,
        'end_date': endDate,
      },
    );
    return BestCustomersReportDto.fromJson(response.data);
  }

  Future<RoomUtilizationReportDto> getRoomUtilization({
    required String propertyId,
    required String startDate,
    required String endDate,
    String? roomType,
  }) async {
    final response = await _dio.get(
      '/reports/room-utilization',
      queryParameters: {
        'property_id': propertyId,
        'start_date': startDate,
        'end_date': endDate,
        'room_type': roomType,
      },
    );
    return RoomUtilizationReportDto.fromJson(response.data);
  }

  Future<StaffPerformanceReportDto> getStaffPerformance({
    required String propertyId,
    required String startDate,
    required String endDate,
    String? staffId,
  }) async {
    final response = await _dio.get(
      '/reports/staff-performance',
      queryParameters: {
        'property_id': propertyId,
        'start_date': startDate,
        'end_date': endDate,
        'staff_id': staffId,
      },
    );
    return StaffPerformanceReportDto.fromJson(response.data);
  }
}

