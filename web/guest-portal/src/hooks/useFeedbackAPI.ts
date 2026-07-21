import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { FeedbackAPI } from "@/lib/feedback-api";
import { GuestFeedbackCreate, PortalComplaintCreate } from "@/types/api";

export function useFeedback() {
  return useQuery({
    queryKey: ["portal", "feedback"],
    queryFn: FeedbackAPI.getFeedback,
  });
}

export function useComplaints() {
  return useQuery({
    queryKey: ["portal", "complaints"],
    queryFn: FeedbackAPI.getComplaints,
    refetchInterval: 10 * 1000,
  });
}

export function useSubmitFeedback() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: GuestFeedbackCreate) => FeedbackAPI.submitFeedback(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["portal", "feedback"] });
    },
  });
}

export function useSubmitComplaint() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: PortalComplaintCreate) => FeedbackAPI.submitComplaint(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["portal", "complaints"] });
    },
  });
}
