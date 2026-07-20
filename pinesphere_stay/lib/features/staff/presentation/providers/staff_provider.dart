import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../main.dart';
import '../../../user_role_management/domain/entities.dart';

part 'staff_provider.g.dart';

// State classes for filtering
class StaffFilterState {
  final String searchQuery;
  final String? roleFilter;

  StaffFilterState({this.searchQuery = '', this.roleFilter});

  StaffFilterState copyWith({String? searchQuery, String? roleFilter}) {
    return StaffFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: roleFilter ?? this.roleFilter,
    );
  }
}

@riverpod
class StaffFilter extends _$StaffFilter {
  @override
  StaffFilterState build() => StaffFilterState();

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateRole(String? role) {
    state = state.copyWith(roleFilter: role);
  }
}

@riverpod
Stream<List<UserEntity>> staffList(Ref ref) {
  final filter = ref.watch(staffFilterProvider);
  final userDao = databaseService.userDao;
  
  return userDao.watchAll().map((users) {
    return users.where((u) {
      if (u.isDeleted) return false;
      
      final matchesSearch = filter.searchQuery.isEmpty || 
                            u.name.toLowerCase().contains(filter.searchQuery.toLowerCase()) ||
                            (u.mobileNumber != null && u.mobileNumber!.contains(filter.searchQuery));
                            
      final matchesRole = filter.roleFilter == null || filter.roleFilter!.isEmpty || u.roleId == filter.roleFilter;
      
      return matchesSearch && matchesRole;
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
  });
}
