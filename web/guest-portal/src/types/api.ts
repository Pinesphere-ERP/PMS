export interface PortalGuestInfo {
  name: string;
  mobile: string | null;
  email: string | null;
}

export interface PortalStayInfo {
  booking_reference: string;
  check_in_date: string;
  check_out_date: string;
  status: string;
}

export interface PortalRoomInfo {
  room_number: string | null;
  category_title: string | null;
}

export interface PortalMeResponse {
  guest: PortalGuestInfo;
  stay: PortalStayInfo;
  room: PortalRoomInfo;
}

export interface PortalStayResponse {
  booking_status: string;
  booked_at: string;
  checked_in_at: string | null;
  checked_out_at: string | null;
  adults: number;
  children: number;
}

export interface PortalRoomResponse {
  room_number: string;
  category: string;
  description: string | null;
}

export interface PortalPropertyResponse {
  name: string;
  address: string | null;
  contact_email: string | null;
  contact_phone: string | null;
  check_in_time: string | null;
  check_out_time: string | null;
}

export interface PortalAmenity {
  id: string;
  name: string;
  description: string | null;
}

export interface PortalAmenitiesResponse {
  amenities: PortalAmenity[];
}

export interface PortalFolioItem {
  description: string;
  amount: number;
  date: string;
}

export interface PortalFolioSummaryResponse {
  booking_id: string;
  total_charges: number;
  total_paid: number;
  balance_due: number;
  items: PortalFolioItem[];
}

export interface PortalCapabilities {
  can_login: boolean;
  can_view_dashboard: boolean;
  can_request_service: boolean;
  can_pay: boolean;
  can_download_invoice: boolean;
  can_submit_feedback: boolean;
}

export interface PortalServiceCatalogItem {
  task_type: string;
  display_name: string;
  description: string;
  icon: string;
}

export interface PortalServiceCreate {
  task_type: string;
  description: string;
}

export interface PortalServiceResponse {
  task_id: string;
  task_type: string;
  status: 'pending' | 'accepted' | 'in_progress' | 'completed' | 'canceled';
  description: string | null;
  created_at: string;
  completed_at: string | null;
}

export interface PortalSecurePaymentRequest {
  mode: string;
  razorpay_payment_id?: string;
  razorpay_order_id?: string;
  razorpay_signature?: string;
}

export interface PortalPaymentResponse {
  payment_id: string;
  amount: number;
  mode: string;
  status: string;
  transaction_id: string;
  created_at: string;
}

export interface PortalInvoiceResponse {
  invoice_id: string;
  invoice_number: string;
  date: string;
  due_date: string;
  amount: number;
  gst: number;
  status: string;
}

// F&B Interfaces
export interface PortalMenuItem {
  id: string;
  name: string;
  description?: string;
  price: number;
  veg_type: 'veg' | 'non-veg' | 'egg';
  is_available: boolean;
  image_url?: string;
}

export interface PortalMenuCategory {
  id: string;
  name: string;
  description?: string;
  items: PortalMenuItem[];
}

export interface PortalFoodOrderCreateItem {
  item_id: string;
  quantity: number;
}

export interface PortalFoodOrderCreate {
  items: PortalFoodOrderCreateItem[];
  special_instructions?: string;
}

export interface PortalFoodOrderResponse {
  task_id: string;
  status: string;
  description: string;
  created_at: string;
}

// Feedback & Ratings
export interface PortalComplaintCreate {
  description: string;
}

export interface GuestFeedbackCreate {
  task_id?: string;
  overall_rating?: number;
  food_rating?: number;
  service_rating?: number;
  staff_rating?: number;
  comments?: string;
  is_anonymous: boolean;
}

export interface GuestFeedbackResponse {
  id: string;
  task_id?: string;
  overall_rating?: number;
  food_rating?: number;
  service_rating?: number;
  staff_rating?: number;
  comments?: string;
  is_anonymous: boolean;
  created_at: string;
  updated_at: string;
}

// Checkout Lifecycle
export interface PortalCheckoutStatusResponse {
  state: "ACTIVE" | "REQUESTED" | "COMPLETED" | "REVOKED";
  balance: number;
  checkout_task_id: string | null;
  grace_period_ends_at: string | null;
}
