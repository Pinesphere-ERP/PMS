class StaffMember {
  final String id;
  final String name;
  final String email;
  final String roleCode;
  final String status;
  final String? phone;
  final bool onShift;

  StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.roleCode,
    required this.status,
    this.phone,
    required this.onShift,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      roleCode: json['role_code'] as String,
      status: json['status'] as String,
      phone: json['phone'] as String?,
      onShift: json['on_shift'] as bool? ?? false,
    );
  }
}

class AttendanceRecord {
  final String id;
  final String staffId;
  final String name;
  final String date;
  final String status;
  final String? checkInTime;
  final String? checkOutTime;

  AttendanceRecord({
    required this.id,
    required this.staffId,
    required this.name,
    required this.date,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      staffId: json['staff_id'] as String,
      name: json['name'] as String,
      date: json['date'] as String,
      status: json['status'] as String,
      checkInTime: json['check_in_time'] as String?,
      checkOutTime: json['check_out_time'] as String?,
    );
  }
}

class PerformanceReview {
  final String id;
  final String staffId;
  final String name;
  final double score;
  final String comments;
  final String reviewDate;

  PerformanceReview({
    required this.id,
    required this.staffId,
    required this.name,
    required this.score,
    required this.comments,
    required this.reviewDate,
  });

  factory PerformanceReview.fromJson(Map<String, dynamic> json) {
    return PerformanceReview(
      id: json['id'] as String,
      staffId: json['staff_id'] as String,
      name: json['name'] as String,
      score: (json['score'] as num).toDouble(),
      comments: json['comments'] as String,
      reviewDate: json['review_date'] as String,
    );
  }
}

class ShiftSchedule {
  final String id;
  final String staffId;
  final String name;
  final String date;
  final String shiftType;
  final String startTime;
  final String endTime;

  ShiftSchedule({
    required this.id,
    required this.staffId,
    required this.name,
    required this.date,
    required this.shiftType,
    required this.startTime,
    required this.endTime,
  });

  factory ShiftSchedule.fromJson(Map<String, dynamic> json) {
    return ShiftSchedule(
      id: json['id'] as String,
      staffId: json['staff_id'] as String,
      name: json['name'] as String,
      date: json['date'] as String,
      shiftType: json['shift_type'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
    );
  }
}
