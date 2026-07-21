import 'package:pinesphere_stay/main.dart';
import 'package:pinesphere_stay/features/requests/data/models/service_request_model.dart';
import 'package:pinesphere_stay/objectbox.g.dart';

class ServiceRequestRepository {
  late final Box<ServiceRequestModel> _requestBox;

  ServiceRequestRepository() {
    _requestBox = databaseService.store.box<ServiceRequestModel>();
  }

  Stream<List<ServiceRequestModel>> watchRequestsByProperty(String propertyId) {
    final query = _requestBox.query(ServiceRequestModel_.propertyId.equals(propertyId))
        .order(ServiceRequestModel_.createdAt, flags: Order.descending)
        .watch(triggerImmediately: true);
    return query.map((q) => q.find());
  }

  Stream<List<ServiceRequestModel>> watchMyRequests(String userId) {
    // Guest or User ID
    final query = _requestBox.query(
        ServiceRequestModel_.requestedByUserId.equals(userId)
        .or(ServiceRequestModel_.requestedByGuestId.equals(userId)))
        .order(ServiceRequestModel_.createdAt, flags: Order.descending)
        .watch(triggerImmediately: true);
    return query.map((q) => q.find());
  }

  Stream<List<ServiceRequestModel>> watchMyTasks(String userId) {
    final query = _requestBox.query(ServiceRequestModel_.assignedTo.equals(userId))
        .order(ServiceRequestModel_.createdAt, flags: Order.descending)
        .watch(triggerImmediately: true);
    return query.map((q) => q.find());
  }

  void saveRequest(ServiceRequestModel request) {
    request.syncStatus = 'pending';
    request.updatedAt = DateTime.now();
    _requestBox.put(request);
  }

  void assignRequest(String requestId, String assignedTo) {
    final query = _requestBox.query(ServiceRequestModel_.requestId.equals(requestId)).build();
    final request = query.findFirst();
    query.close();

    if (request != null) {
      request.assignedTo = assignedTo;
      request.status = 'assigned';
      request.assignedAt = DateTime.now();
      request.syncStatus = 'pending';
      request.updatedAt = DateTime.now();
      _requestBox.put(request);
    }
  }

  void completeRequest(String requestId, String userId, String photoUrl, {String? remarks}) {
    final query = _requestBox.query(ServiceRequestModel_.requestId.equals(requestId)).build();
    final request = query.findFirst();
    query.close();

    if (request != null) {
      request.status = 'completed';
      request.completedBy = userId;
      request.completedAt = DateTime.now();
      request.completionPhotoUrl = photoUrl;
      if (remarks != null) {
        request.remarks = remarks;
      }
      request.syncStatus = 'pending';
      request.updatedAt = DateTime.now();
      _requestBox.put(request);
    }
  }

  void verifyRequest(String requestId, String managerId, {String? remarks}) {
    final query = _requestBox.query(ServiceRequestModel_.requestId.equals(requestId)).build();
    final request = query.findFirst();
    query.close();

    if (request != null) {
      request.status = 'verified';
      request.managerVerified = true;
      request.verifiedBy = managerId;
      request.verifiedAt = DateTime.now();
      if (remarks != null) {
        request.remarks = "${request.remarks ?? ''} | Mgr: $remarks";
      }
      request.syncStatus = 'pending';
      request.updatedAt = DateTime.now();
      _requestBox.put(request);
    }
  }
}
