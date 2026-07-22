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
    final propId = (activePropertyId == null || activePropertyId.isEmpty || activePropertyId == 'default')
        ? '511e5f8b-bb1e-4f76-a817-6133613f1dd0'
        : activePropertyId;
    
    final service = ref.watch(dashboardServiceProvider);
    return await service.getMetrics(propId);
  }

  Future<void> refreshMetrics() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final activePropertyId = ref.read(sessionContextProvider).activePropertyId;
      final propId = (activePropertyId == null || activePropertyId.isEmpty || activePropertyId == 'default')
          ? '511e5f8b-bb1e-4f76-a817-6133613f1dd0'
          : activePropertyId;
      return await ref.read(dashboardServiceProvider).getMetrics(propId);
    });
  }
}
