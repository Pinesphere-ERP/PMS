import { fetchAPI } from './api';

const MANAGER_API_BASE = '/manager';

const managerService = {
  // Dashboard
  getDashboard: async (propertyId) => {
    return fetchAPI(`${MANAGER_API_BASE}/dashboard?property_id=${propertyId}`);
  },

  // Staff
  getStaffList: async (propertyId) => {
    return fetchAPI(`${MANAGER_API_BASE}/staff?property_id=${propertyId}`);
  },
  getStaffAttendance: async (propertyId, date, staffId) => {
    let url = `${MANAGER_API_BASE}/staff/attendance?property_id=${propertyId}`;
    if (date) url += `&attendance_date=${date}`;
    if (staffId) url += `&staff_id=${staffId}`;
    return fetchAPI(url);
  },
  getStaffPerformance: async (propertyId, staffId) => {
    let url = `${MANAGER_API_BASE}/staff/performance?property_id=${propertyId}`;
    if (staffId) url += `&staff_id=${staffId}`;
    return fetchAPI(url);
  },
  assignTaskToStaff: async (payload) => {
    return fetchAPI(`${MANAGER_API_BASE}/staff/assign-task`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },
  createShift: async (payload) => {
    return fetchAPI(`${MANAGER_API_BASE}/staff/shifts`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },
  getShifts: async (propertyId, date, staffId) => {
    let url = `${MANAGER_API_BASE}/staff/shifts?property_id=${propertyId}`;
    if (date) url += `&shift_date=${date}`;
    if (staffId) url += `&staff_id=${staffId}`;
    return fetchAPI(url);
  },

  // Bookings
  getBookings: async (propertyId, status, fromDate, toDate, skip = 0, limit = 50) => {
    let url = `${MANAGER_API_BASE}/bookings?property_id=${propertyId}&skip=${skip}&limit=${limit}`;
    if (status) url += `&booking_status=${status}`;
    if (fromDate) url += `&from_date=${fromDate}`;
    if (toDate) url += `&to_date=${toDate}`;
    return fetchAPI(url);
  },
  getBookingDetail: async (bookingId) => {
    return fetchAPI(`${MANAGER_API_BASE}/bookings/${bookingId}`);
  },
  modifyBooking: async (bookingId, payload) => {
    return fetchAPI(`${MANAGER_API_BASE}/bookings/${bookingId}`, {
      method: 'PATCH',
      body: JSON.stringify(payload),
    });
  },
  changeBookingRoom: async (bookingId, payload) => {
    return fetchAPI(`${MANAGER_API_BASE}/bookings/${bookingId}/change-room`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },
  confirmBooking: async (bookingId) => {
    return fetchAPI(`${MANAGER_API_BASE}/bookings/${bookingId}/confirm`, {
      method: 'POST',
    });
  },

  // Check-ins
  getCheckinFeed: async (propertyId, status) => {
    let url = `${MANAGER_API_BASE}/checkins?property_id=${propertyId}`;
    if (status) url += `&status_filter=${status}`;
    return fetchAPI(url);
  },
  getCheckoutFeed: async (propertyId) => {
    return fetchAPI(`${MANAGER_API_BASE}/checkouts?property_id=${propertyId}`);
  },
  getRoomReadiness: async (propertyId) => {
    return fetchAPI(`${MANAGER_API_BASE}/rooms/readiness?property_id=${propertyId}`);
  },

  // Housekeeping
  getHousekeepingTasks: async (propertyId, status) => {
    let url = `${MANAGER_API_BASE}/housekeeping?property_id=${propertyId}`;
    if (status) url += `&status_filter=${status}`;
    return fetchAPI(url);
  },
  assignHousekeepingTask: async (payload) => {
    return fetchAPI(`${MANAGER_API_BASE}/housekeeping/assign`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },
  reassignHousekeepingTask: async (taskId, payload) => {
    return fetchAPI(`${MANAGER_API_BASE}/housekeeping/${taskId}/reassign`, {
      method: 'PATCH',
      body: JSON.stringify(payload),
    });
  },
  inspectHousekeepingTask: async (taskId, payload) => {
    return fetchAPI(`${MANAGER_API_BASE}/housekeeping/${taskId}/inspect`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },
  closeHousekeepingTask: async (taskId, payload) => {
    return fetchAPI(`${MANAGER_API_BASE}/housekeeping/${taskId}/close`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  // Maintenance
  getMaintenanceTickets: async (propertyId, status, skip = 0, limit = 50) => {
    let url = `${MANAGER_API_BASE}/maintenance?property_id=${propertyId}&skip=${skip}&limit=${limit}`;
    if (status) url += `&status_filter=${status}`;
    return fetchAPI(url);
  },
  createMaintenanceTicket: async (payload) => {
    return fetchAPI(`${MANAGER_API_BASE}/maintenance`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },
  assignMaintenanceTicket: async (ticketId, payload) => {
    return fetchAPI(`${MANAGER_API_BASE}/maintenance/${ticketId}/assign`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },
  updateMaintenanceTicket: async (ticketId, payload) => {
    return fetchAPI(`${MANAGER_API_BASE}/maintenance/${ticketId}`, {
      method: 'PATCH',
      body: JSON.stringify(payload),
    });
  },
  closeMaintenanceTicket: async (ticketId) => {
    return fetchAPI(`${MANAGER_API_BASE}/maintenance/${ticketId}/close`, {
      method: 'POST',
    });
  },

  // Reports
  getOperationalReport: async (propertyId, fromDate, toDate) => {
    return fetchAPI(`${MANAGER_API_BASE}/reports/operational?property_id=${propertyId}&from_date=${fromDate}&to_date=${toDate}`);
  },
  getOccupancyReport: async (propertyId, fromDate, toDate) => {
    return fetchAPI(`${MANAGER_API_BASE}/reports/occupancy?property_id=${propertyId}&from_date=${fromDate}&to_date=${toDate}`);
  },
  getHousekeepingReport: async (propertyId, fromDate, toDate) => {
    return fetchAPI(`${MANAGER_API_BASE}/reports/housekeeping?property_id=${propertyId}&from_date=${fromDate}&to_date=${toDate}`);
  },
  getMaintenanceReport: async (propertyId, fromDate, toDate) => {
    return fetchAPI(`${MANAGER_API_BASE}/reports/maintenance?property_id=${propertyId}&from_date=${fromDate}&to_date=${toDate}`);
  },
  getStaffPerformanceReport: async (propertyId, fromDate, toDate) => {
    return fetchAPI(`${MANAGER_API_BASE}/reports/staff-performance?property_id=${propertyId}&from_date=${fromDate}&to_date=${toDate}`);
  },

  // Room Blocks
  getRoomBlocks: async (propertyId, activeOnly = true) => {
    return fetchAPI(`${MANAGER_API_BASE}/room-blocks?property_id=${propertyId}&active_only=${activeOnly}`);
  },
  createRoomBlock: async (payload) => {
    return fetchAPI(`${MANAGER_API_BASE}/room-blocks`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },
  releaseRoomBlock: async (blockId) => {
    return fetchAPI(`${MANAGER_API_BASE}/room-blocks/${blockId}`, {
      method: 'DELETE',
    });
  },

  // Notes
  getManagerNotes: async (propertyId, noteType, isResolved, skip = 0, limit = 50) => {
    let url = `${MANAGER_API_BASE}/notes?property_id=${propertyId}&skip=${skip}&limit=${limit}`;
    if (noteType) url += `&note_type=${noteType}`;
    if (isResolved !== undefined && isResolved !== null) url += `&is_resolved=${isResolved}`;
    return fetchAPI(url);
  },
  createManagerNote: async (payload) => {
    return fetchAPI(`${MANAGER_API_BASE}/notes`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },
  resolveManagerNote: async (noteId) => {
    return fetchAPI(`${MANAGER_API_BASE}/notes/${noteId}/resolve`, {
      method: 'POST',
    });
  },
  deleteManagerNote: async (noteId) => {
    return fetchAPI(`${MANAGER_API_BASE}/notes/${noteId}`, {
      method: 'DELETE',
    });
  },

  // Checklists
  getChecklists: async (propertyId, date, shift) => {
    let url = `${MANAGER_API_BASE}/checklists?property_id=${propertyId}`;
    if (date) url += `&checklist_date=${date}`;
    if (shift) url += `&shift=${shift}`;
    return fetchAPI(url);
  },
  createChecklist: async (payload) => {
    return fetchAPI(`${MANAGER_API_BASE}/checklists`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },
  updateChecklist: async (checklistId, payload) => {
    return fetchAPI(`${MANAGER_API_BASE}/checklists/${checklistId}`, {
      method: 'PATCH',
      body: JSON.stringify(payload),
    });
  },
  signOffChecklist: async (checklistId, payload) => {
    return fetchAPI(`${MANAGER_API_BASE}/checklists/${checklistId}/sign-off`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  // Service Requests
  getServiceRequests: async (propertyId, status, skip = 0, limit = 50) => {
    let url = `${MANAGER_API_BASE}/service-requests?property_id=${propertyId}&skip=${skip}&limit=${limit}`;
    if (status) url += `&status_filter=${status}`;
    return fetchAPI(url);
  },
  assignServiceRequest: async (requestId, payload) => {
    return fetchAPI(`${MANAGER_API_BASE}/service-requests/${requestId}/assign`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },
};

export default managerService;
