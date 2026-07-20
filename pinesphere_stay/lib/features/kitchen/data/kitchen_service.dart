import 'package:dio/dio.dart';
import 'package:pinesphere_stay/core/network/dio_client.dart';
import 'package:pinesphere_stay/features/tasks/data/models/task_model.dart';
import 'package:pinesphere_stay/core/utils/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'kitchen_service.g.dart';

@Riverpod(keepAlive: true)
KitchenService kitchenService(Ref ref) {
  return KitchenService(dio: ref.watch(dioClientProvider));
}

class KitchenService {
  final Dio _dio;

  KitchenService({required this._dio});

  Future<List<TaskModel>> getOrders(String propertyId) async {
    try {
      final response = await _dio.get(
        '/kitchen/orders',
        queryParameters: {'property_id': propertyId},
      );
      final List<dynamic> data = response.data;
      return data.map((json) => _mapJsonToTask(json)).toList();
    } catch (e) {
      AppLogger.e('Failed to fetch kitchen orders', e);
      return [];
    }
  }

  Future<TaskModel?> updateOrderStatus(String taskId, String status) async {
    try {
      final response = await _dio.patch(
        '/kitchen/orders/$taskId/status',
        data: {'status': status},
      );
      return _mapJsonToTask(response.data);
    } catch (e) {
      AppLogger.e('Failed to update kitchen order status', e);
      return null;
    }
  }

  TaskModel _mapJsonToTask(Map<String, dynamic> json) {
    return TaskModel(
      taskId: json['task_id'] ?? const Uuid().v4(),
      taskType: json['task_type'] ?? 'food',
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'normal',
      roomId: json['room_id'],
      bookingId: json['booking_id'],
      assignedTo: json['assigned_to'],
      description: json['description'],
      dueAt: json['due_at'] != null ? DateTime.parse(json['due_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      photos: json['photos'],
      remarks: json['remarks'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}
