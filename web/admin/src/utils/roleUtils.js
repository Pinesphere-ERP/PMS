const REPORT_ACCESS_MATRIX = {
  SUPER_ADMIN: [
    'daily', 'monthly', 'occupancy', 'revenue', 'collection',
    'outstanding', 'expenses', 'best_customers', 'room_utilization',
    'staff_performance', 'pl', 'gst_returns', 'global'
  ],
  OWNER: [
    'daily', 'monthly', 'occupancy', 'revenue', 'collection',
    'outstanding', 'expenses', 'best_customers', 'room_utilization',
    'staff_performance', 'pl', 'gst_returns'
  ],
  PROPERTY_MANAGER: [
    'daily', 'monthly', 'occupancy', 'room_utilization', 'staff_performance'
  ],
  MANAGER: [
    'daily', 'monthly', 'occupancy', 'room_utilization', 'staff_performance'
  ],
  RECEPTIONIST: [
    'daily', 'occupancy', 'room_utilization'
  ],
  RECEPTION: [
    'daily', 'occupancy', 'room_utilization'
  ],
  ACCOUNTANT: [
    'revenue', 'collection', 'outstanding', 'expenses', 'monthly'
  ],
  HOUSEKEEPING: [],
  KITCHEN: [],
  GUEST: [],
};

const REPORT_LABELS = {
  daily: 'Daily Report',
  monthly: 'Monthly Report',
  occupancy: 'Occupancy Report',
  revenue: 'Revenue Report',
  collection: 'Collection Report',
  outstanding: 'Outstanding Report',
  expenses: 'Expenses Report',
  best_customers: 'Best Customers',
  room_utilization: 'Room Utilization',
  staff_performance: 'Staff Performance',
  pl: 'Profit & Loss',
  gst_returns: 'GST Returns',
  global: 'Global Reports',
};

const REPORT_ROUTES = {
  daily: '/reports/daily',
  monthly: '/reports/monthly',
  occupancy: '/reports/occupancy',
  revenue: '/reports/revenue',
  collection: '/reports/collection',
  outstanding: '/reports/outstanding',
  expenses: '/reports/expenses',
  best_customers: '/reports/best-customers',
  room_utilization: '/reports/room-utilization',
  staff_performance: '/reports/staff-performance',
  pl: '/reports/pl',
  gst_returns: '/reports/gst-returns',
  global: '/reports/global',
};

export function getUserRole() {
  try {
    const userStr = localStorage.getItem('user');
    if (userStr) {
      const user = JSON.parse(userStr);
      return (user.role_code || user.roleCode || user.role || '').toUpperCase();
    }
    const token = localStorage.getItem('token');
    if (token) {
      const payload = JSON.parse(atob(token.split('.')[1]));
      return (payload.role_code || payload.role || '').toUpperCase();
    }
  } catch {
    return '';
  }
  return '';
}

export function canAccessReport(roleCode, reportType) {
  if (!roleCode) return false;
  const normalized = roleCode.toUpperCase().replace(' ', '_');
  const allowed = REPORT_ACCESS_MATRIX[normalized];
  if (!allowed) return false;
  return allowed.includes(reportType);
}

export function getAllowedReports(roleCode) {
  if (!roleCode) return [];
  const normalized = roleCode.toUpperCase().replace(' ', '_');
  return REPORT_ACCESS_MATRIX[normalized] || [];
}

export function getReportLabel(reportType) {
  return REPORT_LABELS[reportType] || reportType;
}

export function getReportRoute(reportType) {
  return REPORT_ROUTES[reportType] || '/reports';
}

export { REPORT_ACCESS_MATRIX, REPORT_LABELS, REPORT_ROUTES };
