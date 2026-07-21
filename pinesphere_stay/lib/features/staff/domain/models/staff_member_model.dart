import 'package:freezed_annotation/freezed_annotation.dart';

part 'staff_member_model.freezed.dart';
part 'staff_member_model.g.dart';

@freezed
abstract class StaffMemberModel with _$StaffMemberModel {
  const factory StaffMemberModel({
    required String id,
    required String name,
    required String roleId,
    String? mobileNumber,
    String? email,
    @Default('ACTIVE') String status,
    @Default(false) bool isPendingSync,
    @Default(false) bool isPrimaryOwner,
  }) = _StaffMemberModel;

  factory StaffMemberModel.fromJson(Map<String, dynamic> json) =>
      _$StaffMemberModelFromJson(json);
}
