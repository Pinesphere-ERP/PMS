class DashboardKPI {
  final String name;
  final String value;
  final String? icon;
  final String? trend;

  DashboardKPI({
    required this.name,
    required this.value,
    this.icon,
    this.trend,
  });

  factory DashboardKPI.fromJson(Map<String, dynamic> json) {
    return DashboardKPI(
      name: json['name'] as String,
      value: json['value'] as String,
      icon: json['icon'] as String?,
      trend: json['trend'] as String?,
    );
  }
}

class StaffAvailabilityItem {
  final String staffId;
  final String name;
  final String? roleCode;
  final String shiftStatus;

  StaffAvailabilityItem({
    required this.staffId,
    required this.name,
    this.roleCode,
    required this.shiftStatus,
  });

  factory StaffAvailabilityItem.fromJson(Map<String, dynamic> json) {
    return StaffAvailabilityItem(
      staffId: json['staff_id'] as String,
      name: json['name'] as String,
      roleCode: json['role_code'] as String?,
      shiftStatus: json['shift_status'] as String,
    );
  }
}

class ManagerDashboardResponse {
  final String date;
  final List<DashboardKPI> kpis;
  final int arrivals;
  final int departures;
  final double occupancyPercent;
  final int activeTasks;
  final int pendingRequests;
  final int todayMaintenance;
  final int todayCleaning;
  final int roomBlocks;
  final int staffOnShift;
  final List<StaffAvailabilityItem> staffAvailability;

  ManagerDashboardResponse({
    required this.date,
    required this.kpis,
    required this.arrivals,
    required this.departures,
    required this.occupancyPercent,
    required this.activeTasks,
    required this.pendingRequests,
    required this.todayMaintenance,
    required this.todayCleaning,
    required this.roomBlocks,
    required this.staffOnShift,
    required this.staffAvailability,
  });

  factory ManagerDashboardResponse.fromJson(Map<String, dynamic> json) {
    return ManagerDashboardResponse(
      date: json['date'] as String,
      kpis: (json['kpis'] as List<dynamic>?)
              ?.map((e) => DashboardKPI.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      arrivals: json['arrivals'] as int? ?? 0,
      departures: json['departures'] as int? ?? 0,
      occupancyPercent: (json['occupancy_percent'] as num?)?.toDouble() ?? 0.0,
      activeTasks: json['active_tasks'] as int? ?? 0,
      pendingRequests: json['pending_requests'] as int? ?? 0,
      todayMaintenance: json['today_maintenance'] as int? ?? 0,
      todayCleaning: json['today_cleaning'] as int? ?? 0,
      roomBlocks: json['room_blocks'] as int? ?? 0,
      staffOnShift: json['staff_on_shift'] as int? ?? 0,
      staffAvailability: (json['staff_availability'] as List<dynamic>?)
              ?.map((e) =>
                  StaffAvailabilityItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
