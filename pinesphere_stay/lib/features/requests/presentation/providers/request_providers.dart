import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/requests/data/repositories/service_request_repository.dart';

final serviceRequestRepositoryProvider = Provider<ServiceRequestRepository>((ref) {
  return ServiceRequestRepository();
});
