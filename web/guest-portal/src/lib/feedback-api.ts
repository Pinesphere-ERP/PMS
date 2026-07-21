import { api } from "./api";
import { GuestFeedbackCreate, GuestFeedbackResponse, PortalComplaintCreate } from "../types/api";

export class FeedbackAPI {
  static async getFeedback(): Promise<GuestFeedbackResponse[]> {
    const res = await api.get<GuestFeedbackResponse[]>("/portal/feedback");
    return res.data;
  }

  static async submitFeedback(payload: GuestFeedbackCreate): Promise<GuestFeedbackResponse> {
    const res = await api.post<GuestFeedbackResponse>("/portal/feedback", payload);
    return res.data;
  }

  static async getComplaints(): Promise<{ task_id: string; status: string; description: string; created_at: string }[]> {
    const res = await api.get("/portal/complaints");
    return res.data;
  }

  static async submitComplaint(payload: PortalComplaintCreate): Promise<{ status: string; task_id: string; message: string }> {
    const res = await api.post("/portal/complaints", payload);
    return res.data;
  }
}
