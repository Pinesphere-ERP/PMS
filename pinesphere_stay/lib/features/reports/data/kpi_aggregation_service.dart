import '../../../main.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/dao/kpi_dao.dart';
import '../domain/models/kpi_snapshot_entity.dart';

part 'kpi_aggregation_service.g.dart';

@Riverpod(keepAlive: true)
KpiAggregationService kpiAggregationService(Ref ref) {
  final service = KpiAggregationService();
  service.initialize(databaseService.kpiDao);
  return service;
}

class KpiAggregationService {
  late IKpiDao _dao;

  void initialize(IKpiDao kpiDao) {
    _dao = kpiDao;
  }

  /// Returns the formatted date key for today in YYYY-MM-DD.
  String get _todayKey =>
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Fetch today's KPI entity from ObjectBox. Returns null if none exists.
  KpiSnapshotEntity? getTodaySnapshot(String propertyId) {
    return _dao.findByPropertyAndDate(propertyId, _todayKey);
  }

  /// Stream that emits whenever today's KPI entity changes, enabling reactive UI.
  Stream<KpiSnapshotEntity?> watchTodaySnapshot(String propertyId) {
    return _dao.watchByPropertyAndDate(propertyId, _todayKey);
  }

  /// Get KPI snapshots for a date range (for charts / multi-day views).
  List<KpiSnapshotEntity> getRange(String propertyId, DateTime start, DateTime end) {
    final startKey = DateFormat('yyyy-MM-dd').format(start);
    final endKey = DateFormat('yyyy-MM-dd').format(end);
    return _dao.getRange(propertyId, startKey, endKey);
  }

  // ───────────────────────────────────────────────────────────
  //  Incremental mutators — called by other modules
  // ───────────────────────────────────────────────────────────

  /// Increment room rent revenue for today. Call from PaymentRepository
  /// when a room-rent payment is recorded.
  void incrementRoomRent(String propertyId, double amount) {
    _mutateToday(propertyId, (entity) {
      entity.revenueRoomRent += amount;
    });
  }

  /// Increment addon revenue (F&B, laundry, minibar, etc.).
  void incrementAddons(String propertyId, double amount) {
    _mutateToday(propertyId, (entity) {
      entity.revenueAddons += amount;
    });
  }

  /// Increment expenses for today (housekeeping supplies, maintenance, etc.).
  void incrementExpenses(String propertyId, double amount) {
    _mutateToday(propertyId, (entity) {
      entity.expensesAmount += amount;
    });
  }

  /// Increment outstanding (unpaid) balance.
  void incrementOutstanding(String propertyId, double amount) {
    _mutateToday(propertyId, (entity) {
      entity.outstandingPayments += amount;
    });
  }

  /// Decrement outstanding when a payment is collected.
  void decrementOutstanding(String propertyId, double amount) {
    _mutateToday(propertyId, (entity) {
      entity.outstandingPayments =
          (entity.outstandingPayments - amount).clamp(0, double.infinity);
    });
  }

  /// Increment GST collected.
  void incrementGst(String propertyId, double amount) {
    _mutateToday(propertyId, (entity) {
      entity.gstCollected += amount;
    });
  }

  /// Update occupancy counts.
  void updateOccupancy({
    required String propertyId,
    required int occupiedRooms,
    required int vacantRooms,
  }) {
    _mutateToday(propertyId, (entity) {
      entity.occupiedRooms = occupiedRooms;
      entity.vacantRooms = vacantRooms;
    });
  }

  /// Decrement room rent when a refund is processed.
  void decrementRoomRent(String propertyId, double amount) {
    _mutateToday(propertyId, (entity) {
      entity.revenueRoomRent =
          (entity.revenueRoomRent - amount).clamp(0, double.infinity);
    });
  }

  // ───────────────────────────────────────────────────────────
  //  Internal helper
  // ───────────────────────────────────────────────────────────

  /// Atomically upserts today's KPI snapshot and applies [mutator].
  void _mutateToday(
    String propertyId,
    void Function(KpiSnapshotEntity entity) mutator,
  ) {
    final dateKey = _todayKey;
    final hlc = DateTime.now().toUtc().toIso8601String();

    var entity = _dao.findByPropertyAndDate(propertyId, dateKey);

    entity ??= KpiSnapshotEntity(
        uuid: '',
        propertyId: propertyId,
        snapshotDate: dateKey,
        isLocalOnly: true,
        lastModifiedHlc: hlc,
      );

    mutator(entity);
    entity.lastModifiedHlc = hlc;
    _dao.put(entity);
  }
}

// ───────────────────────────────────────────────────────────────
//  Riverpod providers for reactive UI binding
// ───────────────────────────────────────────────────────────────



/// Stream provider: emits today's KPI snapshot (or null) reactively.
/// Bind to ObjectBox so the UI re-renders on every local mutation.
@riverpod
Stream<KpiSnapshotEntity?> todaysKpiStream(
  Ref ref, {
  required String propertyId,
}) {
  final service = ref.watch(kpiAggregationServiceProvider);
  return service.watchTodaySnapshot(propertyId);
}
