import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'housekeeping_room_status_model.freezed.dart';
part 'housekeeping_room_status_model.g.dart';

@freezed
class HousekeepingRoomStatusModel with _$HousekeepingRoomStatusModel {
  const HousekeepingRoomStatusModel._();

  const factory HousekeepingRoomStatusModel({
    required String id,
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'room_id') required String roomId,
    @JsonKey(name: 'room_number') required String roomNumber,
    @JsonKey(name: 'room_type') String? roomType,
    String? floor,
    String? description,
    @JsonKey(name: 'occupancy_status') @Default('vacant') String occupancyStatus,
    @JsonKey(name: 'clean_status') @Default('clean') String cleanStatus,
    String? priority,
    @JsonKey(name: 'last_cleaned_at') DateTime? lastCleanedAt,
    @JsonKey(name: 'estimated_cleaning_time') DateTime? estimatedCleaningTime,
    @JsonKey(name: 'image_urls') List<String>? imageUrls,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'updated_by') String? updatedBy,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _HousekeepingRoomStatusModel;

  factory HousekeepingRoomStatusModel.fromJson(Map<String, dynamic> json) =>
      _$HousekeepingRoomStatusModelFromJson(json);

  String get imageUrlsJson => imageUrls != null ? jsonEncode(imageUrls) : '[]';
}
