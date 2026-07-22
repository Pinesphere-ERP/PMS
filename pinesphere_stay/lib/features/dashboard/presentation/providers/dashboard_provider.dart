import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/dashboard_service.dart';
import '../../domain/models/dashboard_metrics_model.dart';
import '../../../../core/auth/session_context.dart';

part 'dashboard_provider.g.dart';

@riverpod
class DashboardMetrics extends _$DashboardMetrics {
  @override
  FutureOr<DashboardMetricsModel> build() async {
    final activePropertyId = ref.watch(sessionContextProvider).activePropertyId;
    
    if (activePropertyId == null || activePropertyId.isEmpty || activePropertyId == 'default') {
      return const DashboardMetricsModel();
    }
    
    final service = ref.watch(dashboardServiceProvider);
    return await service.getMetrics(activePropertyId);
  }

  Future<void> refreshMetrics() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final activePropertyId = ref.read(sessionContextProvider).activePropertyId;
      if (activePropertyId == null || activePropertyId.isEmpty || activePropertyId == 'default') {
        return const DashboardMetricsModel();
      }
      return await ref.read(dashboardServiceProvider).getMetrics(activePropertyId);
    });
  }
}
