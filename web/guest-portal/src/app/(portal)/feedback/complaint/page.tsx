"use client";

import { useState } from "react";
import { useSubmitComplaint } from "@/hooks/useFeedbackAPI";
import { AlertCircle, ArrowLeft, Loader2 } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";

export default function NewComplaintPage() {
  const router = useRouter();
  const { mutate: submitComplaint, isPending } = useSubmitComplaint();
  const [description, setDescription] = useState("");

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!description.trim()) return;
    
    submitComplaint({ description }, {
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
        <h1 className="text-2xl font-semibold text-white">Report an Issue</h1>
      </header>

      <div className="bg-red-900/20 border border-red-900/50 rounded-xl p-4 mb-8 flex gap-3">
        <AlertCircle className="text-red-400 shrink-0 mt-0.5" size={20} />
        <p className="text-sm text-red-200">
          This issue will be immediately escalated to our front desk team for resolution.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label className="text-sm font-medium text-gray-300 block mb-2">Describe the problem</label>
          <textarea
            required
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="e.g., The AC in my room is not working..."
            className="w-full h-40 bg-gray-800 border border-gray-700 rounded-xl p-4 text-white placeholder:text-gray-500 focus:outline-none focus:border-red-500 resize-none transition"
          />
        </div>

        <button
          type="submit"
          disabled={isPending || !description.trim()}
          className="w-full bg-red-600 hover:bg-red-700 disabled:bg-red-800 disabled:text-red-300 text-white font-semibold py-4 rounded-xl shadow-lg flex items-center justify-center gap-2 transition"
        >
          {isPending && <Loader2 size={20} className="animate-spin" />}
          {isPending ? "Submitting..." : "Submit Report"}
        </button>
      </form>
    </div>
  );
}
