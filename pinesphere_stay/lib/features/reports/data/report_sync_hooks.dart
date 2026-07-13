import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../../../objectbox.g.dart';
import '../../sync/domain/models/sync_queue_entity.dart';
import '../domain/models/kpi_dto.dart';

/// Provides enqueue operations for report-related entities to the existing
/// SyncQueueEntity outbox. This does NOT change sync queue processing —
/// it only demonstrates how report mutations enter the queue.
class ReportSyncHooks {
  final Box<SyncQueueEntity> _syncQueueBox;
  // ignore: unused_field
  static const _uuid = Uuid();

  ReportSyncHooks(Store store)
      : _syncQueueBox = store.box<SyncQueueEntity>();

  /// Enqueue a ReportTemplate creation for sync to cloud.
  void enqueueCreateTemplate(ReportTemplateDto template) {
    final payload = jsonEncode({
      'template_id': template.templateId,
      'report_name': template.reportName,
      'report_type': template.reportType,
      'configuration_json': template.configurationJson,
    });

    final item = SyncQueueEntity(
      entityType: 'ReportTemplate',
      entityId: 0, // local auto-generated; server assigns UUID
      operation: 'CREATE',
      payload: payload,
      hlcTimestamp: DateTime.now().toUtc().toIso8601String(),
      status: 0,
    );

    _syncQueueBox.put(item);
  }

  /// Enqueue a ReportTemplate update for sync to cloud.
  void enqueueUpdateTemplate(ReportTemplateDto template) {
    final payload = jsonEncode({
      'template_id': template.templateId,
      'report_name': template.reportName,
      'report_type': template.reportType,
      'configuration_json': template.configurationJson,
    });

    final item = SyncQueueEntity(
      entityType: 'ReportTemplate',
      entityId: 0,
      operation: 'UPDATE',
      payload: payload,
      hlcTimestamp: DateTime.now().toUtc().toIso8601String(),
      status: 0,
    );

    _syncQueueBox.put(item);
  }

  /// Enqueue a ScheduledReport creation for sync to cloud.
  void enqueueCreateSchedule(ScheduledReportDto schedule) {
    final payload = jsonEncode({
      'schedule_id': schedule.scheduleId,
      'template_id': schedule.templateId,
      'recipient_role': schedule.recipientRole,
      'delivery_channel': schedule.deliveryChannel,
      'frequency': schedule.frequency,
      'is_active': schedule.isActive,
    });

    final item = SyncQueueEntity(
      entityType: 'ScheduledReport',
      entityId: 0,
      operation: 'CREATE',
      payload: payload,
      hlcTimestamp: DateTime.now().toUtc().toIso8601String(),
      status: 0,
    );

    _syncQueueBox.put(item);
  }

  /// Enqueue a ScheduledReport update for sync to cloud.
  void enqueueUpdateSchedule(ScheduledReportDto schedule) {
    final payload = jsonEncode({
      'schedule_id': schedule.scheduleId,
      'template_id': schedule.templateId,
      'recipient_role': schedule.recipientRole,
      'delivery_channel': schedule.deliveryChannel,
      'frequency': schedule.frequency,
      'is_active': schedule.isActive,
    });

    final item = SyncQueueEntity(
      entityType: 'ScheduledReport',
      entityId: 0,
      operation: 'UPDATE',
      payload: payload,
      hlcTimestamp: DateTime.now().toUtc().toIso8601String(),
      status: 0,
    );

    _syncQueueBox.put(item);
  }

  /// Enqueue a deletion for either entity type.
  void enqueueDelete(String entityType, String serverUuid) {
    final payload = jsonEncode({'uuid': serverUuid});

    final item = SyncQueueEntity(
      entityType: entityType,
      entityId: 0,
      operation: 'DELETE',
      payload: payload,
      hlcTimestamp: DateTime.now().toUtc().toIso8601String(),
      status: 0,
    );

    _syncQueueBox.put(item);
  }
}
