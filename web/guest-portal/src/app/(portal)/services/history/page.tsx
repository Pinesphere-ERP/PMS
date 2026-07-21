"use client";

import { useServiceHistory, useServiceCatalog, useCancelService } from "@/hooks/useServices";
import { ArrowLeft, CheckCircle2, Clock, XCircle, SprayCan, Wrench, Utensils, AlertCircle } from "lucide-react";
import { useRouter } from "next/navigation";
import Link from "next/link";

const IconMap: Record<string, React.ElementType> = {
  broom: SprayCan,
  wrench: Wrench,
  utensils: Utensils,
};

const StatusStyles: Record<string, { bg: string, text: string, icon: React.ElementType, label: string }> = {
  pending: { bg: "bg-yellow-900/30", text: "text-yellow-400", icon: Clock, label: "Pending" },
  accepted: { bg: "bg-blue-900/30", text: "text-blue-400", icon: Clock, label: "Accepted" },
  in_progress: { bg: "bg-blue-900/30", text: "text-blue-400", icon: Clock, label: "In Progress" },
  completed: { bg: "bg-green-900/30", text: "text-green-400", icon: CheckCircle2, label: "Completed" },
  canceled: { bg: "bg-red-900/30", text: "text-red-400", icon: XCircle, label: "Canceled" },
};

export default function ServicesHistoryPage() {
  const router = useRouter();
  const { data: history, isLoading: isHistoryLoading, isError } = useServiceHistory();
  const { data: catalog } = useServiceCatalog();
  const cancelService = useCancelService();

  if (isHistoryLoading) {
    return (
      <div className="p-6 max-w-lg mx-auto pb-24">
        <div className="h-8 w-1/3 bg-gray-800 rounded mb-6 animate-pulse"></div>
        <div className="space-y-4">
          {[1, 2].map((i) => (
            <div key={i} className="h-32 bg-gray-800 rounded-xl animate-pulse"></div>
          ))}
        </div>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="p-6 max-w-lg mx-auto pb-24 text-center mt-20">
        <AlertCircle size={48} className="text-red-500 mb-4 mx-auto" />
        <h2 className="text-xl font-semibold text-white mb-2">Could not load history</h2>
        <button 
          onClick={() => window.location.reload()}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg mt-4"
        >
          Retry
        </button>
      </div>
    );
  }

  const tasks = history || [];

  const handleCancel = (taskId: string) => {
    if (confirm("Are you sure you want to cancel this request?")) {
      cancelService.mutate(taskId, {
        onError: () => {
          alert("Could not cancel request. It may have already been accepted or completed.");
        }
      });
    }
  };

  return (
    <div className="p-6 pb-24 max-w-lg mx-auto">
      <header className="flex items-center gap-3 mb-8">
        <button onClick={() => router.push("/services")} className="p-2 -ml-2 text-gray-400 hover:text-white transition-colors">
          <ArrowLeft size={20} />
        </button>
        <h1 className="text-2xl font-semibold text-white">Request History</h1>
      </header>

      {tasks.length === 0 ? (
        <div className="bg-gray-800 rounded-xl p-8 text-center border border-gray-700 mt-10">
          <HistoryIcon width={48} height={48} className="text-gray-600 mb-4 mx-auto" />
          <h2 className="text-lg font-medium text-white mb-2">No Requests Yet</h2>
          <p className="text-gray-400 mb-6 text-sm">You haven&apos;t made any service requests during this stay.</p>
          <Link href="/services" className="bg-gray-700 hover:bg-gray-600 text-white px-6 py-2.5 rounded-full text-sm font-medium transition-colors">
            Browse Services
          </Link>
        </div>
      ) : (
        <div className="space-y-4 relative before:absolute before:inset-0 before:ml-5 before:-translate-x-px md:before:mx-auto md:before:translate-x-0 before:h-full before:w-0.5 before:bg-gradient-to-b before:from-transparent before:via-gray-700 before:to-transparent">
          {tasks.map((task) => {
            const catalogItem = catalog?.find(c => c.task_type === task.task_type);
            const displayTitle = catalogItem?.display_name || task.task_type;
            const IconComponent = catalogItem ? (IconMap[catalogItem.icon] || SprayCan) : SprayCan;
            const statusStyle = StatusStyles[task.status] || StatusStyles.pending;

            return (
              <div key={task.task_id} className="relative flex items-center justify-between md:justify-normal md:odd:flex-row-reverse group is-active">
                {/* Timeline dot */}
                <div className={`flex items-center justify-center w-10 h-10 rounded-full border-4 border-gray-900 shrink-0 md:order-1 md:group-odd:-translate-x-1/2 md:group-even:translate-x-1/2 shadow absolute left-0 md:relative md:left-auto ${statusStyle.bg} ${statusStyle.text}`}>
                  <IconComponent size={16} />
                </div>

                {/* Card */}
                <div className="w-[calc(100%-4rem)] md:w-[calc(50%-2.5rem)] ml-14 md:ml-0 bg-gray-800 p-4 rounded-xl border border-gray-700 shadow">
                  <div className="flex justify-between items-start mb-2">
                    <h3 className="font-semibold text-white">{displayTitle}</h3>
                    <div className={`flex items-center gap-1 text-[10px] uppercase font-bold px-2 py-0.5 rounded-full ${statusStyle.bg} ${statusStyle.text}`}>
                      {statusStyle.label}
                    </div>
                  </div>
                  
                  {task.description && (
                    <p className="text-sm text-gray-400 mb-3 line-clamp-2">&quot;{task.description}&quot;</p>
                  )}
                  
                  <div className="flex items-center justify-between mt-3 pt-3 border-t border-gray-700/50">
                    <div className="text-xs text-gray-500">
                      {new Date(task.created_at).toLocaleString('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' })}
                    </div>
                    
                    {task.status === "pending" && (
                      <button 
                        onClick={() => handleCancel(task.task_id)}
                        disabled={cancelService.isPending}
                        className="text-xs text-red-400 hover:text-red-300 transition-colors"
                      >
                        Cancel
                      </button>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

function HistoryIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      {...props}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8" />
      <path d="M3 3v5h5" />
      <path d="M12 7v5l4 2" />
    </svg>
  );
}
