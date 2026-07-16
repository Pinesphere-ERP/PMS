import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:workmanager/workmanager.dart';
import 'package:pinesphere_stay/main.dart';
import 'package:pinesphere_stay/core/sync/queue/sync_operation.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'syncOutbox') {
      try {
        // Assume ObjectBox is already initialized or initialize it here
        // Note: In background isolate, ObjectBox must be initialized again if main is not running
        final box = objectBox.store.box<SyncOperation>();
        final pendingOps = box.query(SyncOperation_.status.equals('pending')).build().find();
        
        if (pendingOps.isEmpty) return Future.value(true);
        
        final dio = Dio(BaseOptions(
          baseUrl: const String.fromEnvironment('API_URL', defaultValue: 'https://pms-bvko.onrender.com/api/v1'),
        ));
        
        // Setup interceptors if needed (auth token etc)
        // Usually, the token would be fetched from secure storage
        
        for (final op in pendingOps) {
          try {
            op.status = 'in_progress';
            box.put(op);
            
            // Depending on operationType, hit the correct endpoint
            // This is a generic example. In reality, you'd route based on entityType
            await dio.post('/sync/push', data: {
              'records': [
                {
                  'entity_type': op.entityType,
                  'entity_id': op.entityId,
                  'operation': op.operationType.toUpperCase(),
                  'payload': jsonDecode(op.payload),
                  'updated_at': op.createdAt.toIso8601String(),
                }
              ]
            });
            
            op.status = 'completed';
            box.put(op);
          } catch (e) {
            op.status = 'failed';
            op.retryCount += 1;
            box.put(op);
          }
        }
        return Future.value(true);
      } catch (err) {
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}
