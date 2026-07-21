import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/manager/repository/manager_repository.dart';

import 'package:pinesphere_stay/features/manager/models/checkin_model.dart';

final managerCheckinsProvider = FutureProvider.autoDispose<List<Checkin>>((ref) async {
  final repository = ref.watch(managerRepositoryProvider);
  final data = await repository.getCheckinFeed();
  return data.map((e) => Checkin.fromJson(e as Map<String, dynamic>)).toList();
});
