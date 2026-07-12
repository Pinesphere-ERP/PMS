import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/permissions/user_role.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    required String email,
    required UserRole role,
    @JsonKey(name: 'property_id') String? propertyId,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}
