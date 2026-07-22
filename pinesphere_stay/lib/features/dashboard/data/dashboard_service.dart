import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../domain/models/dashboard_metrics_model.dart';

part 'dashboard_service.g.dart';

@riverpod
DashboardService dashboardService(Ref ref) {
  return DashboardService(ref.watch(dioClientProvider));
}

class DashboardService {
  final Dio _dio;

  DashboardService(this._dio);

  Future<DashboardMetricsModel> getMetrics(String propertyId) async {
    final response = await _dio.get('/dashboard', queryParameters: {
      'property_id': propertyId,
    });
    
    // The backend responds with standard response: { "status": "success", "data": { ... } }
    if (response.data != null && response.data['data'] != null) {
      return DashboardMetricsModel.fromJson(response.data['data']);
    }
    
    return const DashboardMetricsModel();
  }
}
