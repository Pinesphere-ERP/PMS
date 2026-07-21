"use client";

import { useState, useEffect } from "react";
import { useSubmitFeedback, useFeedback } from "@/hooks/useFeedbackAPI";
import { Star, ArrowLeft, Loader2 } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";

export default function NewFeedbackPage() {
  const router = useRouter();
  const { data: existingFeedback } = useFeedback();
  const { mutate: submitFeedback, isPending } = useSubmitFeedback();

  const [ratings, setRatings] = useState({
    overall_rating: 0,
    food_rating: 0,
    service_rating: 0,
    staff_rating: 0,
  });
  const [comments, setComments] = useState("");
  const [isAnonymous, setIsAnonymous] = useState(false);

  useEffect(() => {
    if (existingFeedback) {
      const overall = existingFeedback.find(f => !f.task_id);
      if (overall) {
        // eslint-disable-next-line react-hooks/set-state-in-effect
        setRatings({
          overall_rating: overall.overall_rating || 0,
          food_rating: overall.food_rating || 0,
          service_rating: overall.service_rating || 0,
          staff_rating: overall.staff_rating || 0,
        });
        setComments(overall.comments || "");
        setIsAnonymous(overall.is_anonymous || false);
      }
    }
  }, [existingFeedback]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    submitFeedback({
      overall_rating: ratings.overall_rating || undefined,
      food_rating: ratings.food_rating || undefined,
      service_rating: ratings.service_rating || undefined,
      staff_rating: ratings.staff_rating || undefined,
      comments: comments || undefined,
      is_anonymous: isAnonymous,
    }, {
      onSuccess: () => {
        router.push("/feedback");
      }
    });
  };



  return (
    <div className="p-6 pb-24 max-w-lg mx-auto">
      <header className="flex items-center gap-3 mb-8">
        <Link href="/feedback" className="p-2 -ml-2 text-gray-400 hover:text-white transition">
          <ArrowLeft size={20} />
        </Link>
        <h1 className="text-2xl font-semibold text-white">Rate Your Stay</h1>
      </header>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="space-y-3">
          <div className="bg-gray-800 p-4 rounded-xl border border-gray-700 flex justify-between items-center">
            <span className="text-white font-medium">Overall Experience</span>
            <div className="flex gap-1">
              {[1, 2, 3, 4, 5].map((star) => (
                <button key={star} type="button" onClick={() => setRatings(prev => ({ ...prev, overall_rating: star }))} className="p-1 focus:outline-none transition-transform active:scale-75">
                  <Star size={24} className={star <= ratings.overall_rating ? "text-yellow-400 fill-yellow-400" : "text-gray-600"} />
                </button>
              ))}
            </div>
          </div>
          <div className="bg-gray-800 p-4 rounded-xl border border-gray-700 flex justify-between items-center">
            <span className="text-white font-medium">Food & Dining</span>
            <div className="flex gap-1">
              {[1, 2, 3, 4, 5].map((star) => (
                <button key={star} type="button" onClick={() => setRatings(prev => ({ ...prev, food_rating: star }))} className="p-1 focus:outline-none transition-transform active:scale-75">
                  <Star size={24} className={star <= ratings.food_rating ? "text-yellow-400 fill-yellow-400" : "text-gray-600"} />
                </button>
              ))}
            </div>
          </div>
          <div className="bg-gray-800 p-4 rounded-xl border border-gray-700 flex justify-between items-center">
            <span className="text-white font-medium">Room Service</span>
            <div className="flex gap-1">
              {[1, 2, 3, 4, 5].map((star) => (
                <button key={star} type="button" onClick={() => setRatings(prev => ({ ...prev, service_rating: star }))} className="p-1 focus:outline-none transition-transform active:scale-75">
                  <Star size={24} className={star <= ratings.service_rating ? "text-yellow-400 fill-yellow-400" : "text-gray-600"} />
                </button>
              ))}
            </div>
          </div>
          <div className="bg-gray-800 p-4 rounded-xl border border-gray-700 flex justify-between items-center">
            <span className="text-white font-medium">Staff & Hospitality</span>
            <div className="flex gap-1">
              {[1, 2, 3, 4, 5].map((star) => (
                <button key={star} type="button" onClick={() => setRatings(prev => ({ ...prev, staff_rating: star }))} className="p-1 focus:outline-none transition-transform active:scale-75">
                  <Star size={24} className={star <= ratings.staff_rating ? "text-yellow-400 fill-yellow-400" : "text-gray-600"} />
                </button>
              ))}
            </div>
          </div>
        </div>

        <div>
          <label className="text-sm font-medium text-gray-300 block mb-2">Additional Comments</label>
          <textarea
            value={comments}
            onChange={(e) => setComments(e.target.value)}
            placeholder="Tell us what you loved or how we can improve..."
            className="w-full h-32 bg-gray-800 border border-gray-700 rounded-xl p-4 text-white placeholder:text-gray-500 focus:outline-none focus:border-indigo-500 resize-none transition"
          />
        </div>

        <label className="flex items-center gap-3 cursor-pointer">
          <input 
            type="checkbox" 
            checked={isAnonymous}
            onChange={(e) => setIsAnonymous(e.target.checked)}
            className="w-5 h-5 rounded border-gray-600 bg-gray-800 text-indigo-500 focus:ring-indigo-500 focus:ring-offset-gray-900"
          />
          <span className="text-sm text-gray-300">Submit anonymously</span>
        </label>

        <button
          type="submit"
          disabled={isPending}
          className="w-full bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-800 text-white font-semibold py-4 rounded-xl shadow-lg flex items-center justify-center gap-2 transition"
        >
          {isPending && <Loader2 size={20} className="animate-spin" />}
          {isPending ? "Submitting..." : "Submit Feedback"}
        </button>
      </form>
    </div>
  );
}
