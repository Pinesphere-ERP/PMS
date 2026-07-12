import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/models/kpi_dto.dart';
import '../../../../core/network/dio_client.dart';

part 'reports_repository.g.dart';

@riverpod
ReportsRepository reportsRepository(Ref ref) {
  return ReportsRepository(ref.watch(dioClientProvider));
}

class ReportsRepository {
  final Dio _dio;

  ReportsRepository(this._dio);

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
}
