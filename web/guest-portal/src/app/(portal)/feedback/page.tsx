"use client";

import { useFeedback, useComplaints } from "@/hooks/useFeedbackAPI";
import { Star, AlertCircle, ArrowRight, Home } from "lucide-react";
import Link from "next/link";

export default function FeedbackDashboardPage() {
  const { data: feedbackData, isLoading: isLoadingFeedback } = useFeedback();
  const { data: complaintsData, isLoading: isLoadingComplaints } = useComplaints();

  const isLoading = isLoadingFeedback || isLoadingComplaints;
  const safeFeedback = feedbackData || [];
  const safeComplaints = complaintsData || [];
  
  // Get the most recent overall rating if any
  const overallFeedback = safeFeedback.find(f => !f.task_id);

  if (isLoading) {
    return (
      <div className="p-6 max-w-lg mx-auto">
        <div className="h-8 w-1/3 bg-gray-800 rounded mb-8 animate-pulse"></div>
        <div className="grid grid-cols-2 gap-4 mb-8">
          {[1, 2].map((i) => (
            <div key={i} className="h-32 bg-gray-800 rounded-xl animate-pulse"></div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 pb-24 max-w-lg mx-auto">
      <header className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-semibold text-white">Feedback</h1>
          <p className="text-sm text-gray-400">Help us improve your stay.</p>
        </div>
        <Link href="/dashboard" className="p-2 text-gray-400 hover:text-white transition">
          <Home size={20} />
        </Link>
      </header>

      <div className="grid grid-cols-2 gap-4 mb-8">
        <Link href="/feedback/new" className="bg-gradient-to-br from-indigo-900 to-gray-900 border border-indigo-800/50 p-5 rounded-2xl flex flex-col items-center text-center group hover:border-indigo-500 transition">
          <div className="w-12 h-12 bg-indigo-500/20 rounded-full flex items-center justify-center mb-3 group-hover:scale-110 transition">
            <Star size={24} className="text-indigo-400 fill-indigo-400/20" />
          </div>
          <h3 className="text-white font-medium mb-1">
            {overallFeedback ? "Update Rating" : "Rate Stay"}
          </h3>
          <p className="text-xs text-indigo-200">Share your experience</p>
        </Link>
        
        <Link href="/feedback/complaint" className="bg-gradient-to-br from-red-900 to-gray-900 border border-red-800/50 p-5 rounded-2xl flex flex-col items-center text-center group hover:border-red-500 transition">
          <div className="w-12 h-12 bg-red-500/20 rounded-full flex items-center justify-center mb-3 group-hover:scale-110 transition">
            <AlertCircle size={24} className="text-red-400" />
          </div>
          <h3 className="text-white font-medium mb-1">Report Issue</h3>
          <p className="text-xs text-red-200">We&apos;re here to help</p>
        </Link>
      </div>

      <div className="space-y-6">
        {safeComplaints.length > 0 && (
          <section>
            <div className="flex justify-between items-end mb-4">
              <h2 className="text-lg font-semibold text-white flex items-center gap-2">
                <AlertCircle size={18} className="text-red-400" /> Active Issues
              </h2>
              <Link href="/feedback/history" className="text-sm text-blue-400 hover:text-blue-300 flex items-center gap-1">
                View all <ArrowRight size={14} />
              </Link>
            </div>
            
            <div className="space-y-3">
              {safeComplaints.slice(0, 2).map((c) => (
                <Link key={c.task_id} href="/feedback/history" className="block bg-gray-800 border border-gray-700 rounded-xl p-4 hover:bg-gray-750 transition">
                  <div className="flex justify-between items-start mb-2">
                    <span className="text-xs font-semibold text-red-400 uppercase tracking-wider">{c.status}</span>
                    <span className="text-xs text-gray-500">{new Date(c.created_at).toLocaleString('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' })}</span>
                  </div>
                  <p className="text-sm text-gray-300 font-medium line-clamp-1">{c.description}</p>
                </Link>
              ))}
            </div>
          </section>
        )}

        {overallFeedback && (
          <section>
            <h2 className="text-lg font-semibold text-white flex items-center gap-2 mb-4">
              <Star size={18} className="text-yellow-400" /> Your Recent Rating
            </h2>
            <div className="bg-gray-800 border border-gray-700 rounded-xl p-5">
              <div className="flex items-center gap-1 mb-3">
                {[1, 2, 3, 4, 5].map((star) => (
                  <Star 
                    key={star} 
                    size={20} 
                    className={star <= (overallFeedback.overall_rating || 0) ? "text-yellow-400 fill-yellow-400" : "text-gray-600"} 
                  />
                ))}
              </div>
              {overallFeedback.comments ? (
                <p className="text-sm text-gray-300 italic">&quot;{overallFeedback.comments}&quot;</p>
              ) : (
                <p className="text-sm text-gray-500 italic">No comments provided.</p>
              )}
            </div>
          </section>
        )}
      </div>
    </div>
  );
}
