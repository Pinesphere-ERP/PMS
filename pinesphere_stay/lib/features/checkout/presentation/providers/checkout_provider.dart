import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/checkout_service.dart';
import '../../../audit/data/audit_service.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../rooms/presentation/providers/pms_provider.dart';

part 'checkout_provider.freezed.dart';
part 'checkout_provider.g.dart';

@freezed
sealed class CheckOutState with _$CheckOutState {
  const factory CheckOutState.initial() = _Initial;
  const factory CheckOutState.loading() = _Loading;
  const factory CheckOutState.success(String message, {String? checkoutId}) = _Success;
  const factory CheckOutState.error(String message) = _Error;
  const factory CheckOutState.loadedPendingCheckouts(List<Map<String, dynamic>> checkouts) = _LoadedPending;
  const factory CheckOutState.loadedBilling(Map<String, dynamic> billing) = _LoadedBilling;
  const factory CheckOutState.loadedTodaysCheckouts(List<Map<String, dynamic>> checkouts) = _LoadedTodays;
  const factory CheckOutState.loadedDetail(Map<String, dynamic> detail) = _LoadedDetail;
}

@riverpod
class CheckOutNotifier extends _$CheckOutNotifier {
  @override
  CheckOutState build() => const CheckOutState.initial();

  Future<void> getPendingCheckOuts(String propertyId) async {
    state = const CheckOutState.loading();
    try {
      final service = ref.read(checkOutServiceProvider);
      final result = await service.getPendingCheckOuts(propertyId);
      final checkouts = result.cast<Map<String, dynamic>>();
      state = CheckOutState.loadedPendingCheckouts(checkouts);
    } catch (e) {
      state = CheckOutState.error('Failed to load pending checkouts: $e');
    }
  }

  Future<void> getBillingPreview(String checkinId) async {
    state = const CheckOutState.loading();
    try {
      final service = ref.read(checkOutServiceProvider);
      final result = await service.getCheckOutBilling(checkinId);
      state = CheckOutState.loadedBilling(result);
    } catch (e) {
      state = CheckOutState.error('Failed to load billing preview: $e');
    }
  }

  Future<void> performCheckOut({required Map<String, dynamic> data}) async {
    state = const CheckOutState.loading();

    ref.read(auditServiceProvider).log(
      moduleName: 'checkout',
      actionType: 'check_out',
      targetEntity: 'check_out',
      targetRecordId: '',
      propertyId: data['property_id']?.toString(),
      userId: data['staff_id']?.toString(),
      newValue: {
        'booking_id': data['booking_id'],
        'checkin_id': data['checkin_id'],
        'room_id': data['room_id'],
        'total_amount': data['total_amount'],
        'payment_status': data['payment_status'],
      },
    );

    try {
      final service = ref.read(checkOutServiceProvider);
      final result = await service.performCheckOut(data);
      ref.invalidate(dashboardMetricsProvider);
      ref.invalidate(pmsProvider);
      final checkoutId = result['id']?.toString();
      state = CheckOutState.success('Checkout completed successfully', checkoutId: checkoutId);
    } catch (e) {
      state = CheckOutState.error('Checkout failed: $e');
    }
  }

  Future<void> getTodaysCheckOuts(String propertyId) async {
    state = const CheckOutState.loading();
    try {
      final service = ref.read(checkOutServiceProvider);
      final result = await service.getTodaysCheckOuts(propertyId);
      final checkouts = result.cast<Map<String, dynamic>>();
      state = CheckOutState.loadedTodaysCheckouts(checkouts);
    } catch (e) {
      state = CheckOutState.error('Failed to load today\'s checkouts: $e');
    }
  }

  Future<void> getCheckOutDetail(String checkoutId) async {
    state = const CheckOutState.loading();
    try {
      final service = ref.read(checkOutServiceProvider);
      final result = await service.getCheckOutDetail(checkoutId);
      state = CheckOutState.loadedDetail(result);
    } catch (e) {
      state = CheckOutState.error('Failed to load checkout detail: $e');
    }
  }
}
