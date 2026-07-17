import 'package:pinesphere_stay/main.dart';
import 'package:pinesphere_stay/features/tasks/data/models/task_model.dart';
import 'package:pinesphere_stay/objectbox.g.dart';

class TaskRepository {
  late final Box<TaskModel> _taskBox;

  TaskRepository() {
    _taskBox = objectBox.store.box<TaskModel>();
  }

  Stream<List<TaskModel>> watchTasksByType(String taskType) {
    final query = _taskBox.query(TaskModel_.taskType.equals(taskType)).watch(triggerImmediately: true);
    return query.map((q) => q.find());
  }

  Stream<List<TaskModel>> watchAllTasks() {
    return _taskBox.query().watch(triggerImmediately: true).map((q) => q.find());
  }

  void saveTask(TaskModel task) {
    task.syncStatus = 'pending';
    task.updatedAt = DateTime.now();
    _taskBox.put(task);
  }

  void updateTaskStatus(String taskId, String newStatus) {
    final query = _taskBox.query(TaskModel_.taskId.equals(taskId)).build();
    final task = query.findFirst();
    query.close();

    if (task != null) {
      task.status = newStatus;
      if (newStatus == 'completed') {
        task.completedAt = DateTime.now();
      }
      task.syncStatus = 'pending';
      task.updatedAt = DateTime.now();
      _taskBox.put(task);
    }
  }

  List<TaskModel> getPendingSyncTasks() {
    final query = _taskBox.query(TaskModel_.syncStatus.equals('pending')).build();
    final tasks = query.find();
    query.close();
    return tasks;
  }
}
