import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/tasks/data/repositories/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});
