import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/main.dart';
import 'package:pinesphere_stay/objectbox.g.dart';
import 'package:pinesphere_stay/features/notifications/data/models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final unreadNotificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchUnreadNotifications();
});

class NotificationRepository {
  late final Box<NotificationModel> _notificationBox;

  NotificationRepository() {
    _notificationBox = databaseService.store.box<NotificationModel>();
  }

  Stream<List<NotificationModel>> watchUnreadNotifications() {
    return _notificationBox
        .query(NotificationModel_.status.equals('unread'))
        .order(NotificationModel_.createdAt, flags: Order.descending)
        .watch(triggerImmediately: true)
        .map((q) => q.find());
  }

  void markAsRead(String notificationId) {
    final query = _notificationBox.query(NotificationModel_.notificationId.equals(notificationId)).build();
    final notif = query.findFirst();
    query.close();

    if (notif != null) {
      notif.status = 'read';
      notif.readAt = DateTime.now();
      notif.syncStatus = 'pending';
      notif.updatedAt = DateTime.now();
      _notificationBox.put(notif);
    }
  }

  void dismiss(String notificationId) {
    final query = _notificationBox.query(NotificationModel_.notificationId.equals(notificationId)).build();
    final notif = query.findFirst();
    query.close();

    if (notif != null) {
      notif.status = 'dismissed';
      notif.syncStatus = 'pending';
      notif.updatedAt = DateTime.now();
      _notificationBox.put(notif);
    }
  }
}
