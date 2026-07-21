import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/staff_member_model.dart';
import '../../data/repositories/staff_repository.dart';
part 'staff_notifier.g.dart';

@riverpod
class StaffNotifier extends _$StaffNotifier {
  @override
  Future<List<StaffMemberModel>> build() async {
    return _fetchStaff();
  }

  Future<List<StaffMemberModel>> _fetchStaff() async {
    final repo = ref.read(staffRepositoryProvider);
    return repo.getStaffList();
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchStaff());
  }

  Future<bool> inviteStaff({
    required String mobileNumber,
    required String name,
    required String roleId,
  }) async {
    final repo = ref.read(staffRepositoryProvider);
    final success = await repo.inviteStaff(
      mobileNumber: mobileNumber,
      name: name,
      roleId: roleId,
    );
    if (success) {
      await reload();
    }
    return success;
  }

  Future<bool> updateStaffStatus(String staffId, String status) async {
    final repo = ref.read(staffRepositoryProvider);
    final success = await repo.updateStaffStatus(staffId, status);
    if (success) {
      await reload();
    }
    return success;
  }
}
