import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/manager/repository/manager_repository.dart';

import 'package:pinesphere_stay/features/manager/models/note_model.dart';

final managerNotesProvider = FutureProvider.autoDispose<List<ManagerNote>>((ref) async {
  final repository = ref.watch(managerRepositoryProvider);
  final data = await repository.getNotes();
  return data.map((e) => ManagerNote.fromJson(e as Map<String, dynamic>)).toList();
});
