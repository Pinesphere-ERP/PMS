"use client";

import { useComplaints } from "@/hooks/useFeedbackAPI";
import { ArrowLeft, Clock, CheckCircle2, Check, XCircle, AlertCircle } from "lucide-react";
import Link from "next/link";

const statusConfig: Record<string, { label: string, color: string, bg: string, icon: React.ElementType }> = {
  pending: { label: "Under Review", color: "text-blue-400", bg: "bg-blue-900/30", icon: Clock },
  accepted: { label: "Investigating", color: "text-yellow-400", bg: "bg-yellow-900/30", icon: Check },
  in_progress: { label: "Fixing", color: "text-orange-400", bg: "bg-orange-900/30", icon: Clock },
  completed: { label: "Resolved", color: "text-green-500", bg: "bg-green-900/30", icon: CheckCircle2 },
  closed: { label: "Closed", color: "text-green-500", bg: "bg-green-900/30", icon: CheckCircle2 },
  cancelled: { label: "Cancelled", color: "text-red-400", bg: "bg-red-900/30", icon: XCircle }
};

export default function ComplaintsHistoryPage() {
  const { data: complaints, isLoading } = useComplaints();

  if (isLoading) {
    return (
      <div className="p-6 max-w-lg mx-auto pb-24">
        <div className="h-8 w-1/3 bg-gray-800 rounded mb-8 animate-pulse"></div>
        <div className="space-y-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-32 bg-gray-800 rounded-xl animate-pulse"></div>
          ))}
        </div>
      </div>
    );
  }

  const safeComplaints = complaints || [];

  return (
    <div className="p-6 pb-24 max-w-lg mx-auto">
      <header className="flex items-center gap-3 mb-8">
        <Link href="/feedback" className="p-2 -ml-2 text-gray-400 hover:text-white transition">
          <ArrowLeft size={20} />
        </Link>
        <h1 className="text-2xl font-semibold text-white">Active Issues</h1>
      </header>

      {safeComplaints.length === 0 ? (
        <div className="bg-gray-800 rounded-xl p-8 text-center border border-gray-700 mt-10">
          <AlertCircle size={48} className="text-gray-600 mb-4 mx-auto" />
          <h2 className="text-lg font-medium text-white mb-2">No Active Issues</h2>
          <p className="text-gray-400 mb-6 text-sm">You haven&apos;t reported any issues during this stay.</p>
        </div>
      ) : (
        <div className="space-y-4">
          {safeComplaints.map((issue) => {
            const config = statusConfig[issue.status.toLowerCase()] || statusConfig.pending;
            const Icon = config.icon;
            
            return (
              <div key={issue.task_id} className="bg-gray-800 p-5 rounded-xl border border-gray-700 shadow relative overflow-hidden">
                <div className={`absolute top-0 left-0 w-1 h-full ${config.bg.replace('bg-', 'bg-').replace('/30', '')}`}></div>
                
                <div className="flex justify-between items-start mb-4">
                  <div className="flex items-center gap-2">
                    <div className={`p-1.5 rounded-lg ${config.bg} ${config.color}`}>
                      <Icon size={16} />
                    </div>
                    <span className={`text-xs font-semibold uppercase tracking-wider ${config.color}`}>
                      {config.label}
                    </span>
                  </div>
                  <span className="text-xs text-gray-500">
                    {new Date(issue.created_at).toLocaleString('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' })}
                  </span>
                </div>
                
                <div className="bg-gray-900/50 p-3 rounded-lg">
                  <p className="text-sm text-gray-300 font-medium leading-relaxed">
                    {issue.description}
                  </p>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
