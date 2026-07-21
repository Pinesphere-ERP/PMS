import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/manager/repository/manager_repository.dart';

import 'package:pinesphere_stay/features/manager/models/booking_model.dart';

final managerBookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) async {
  final repository = ref.watch(managerRepositoryProvider);
  final data = await repository.getBookings();
  return data.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
});
