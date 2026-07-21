"use client";

import { useServiceCatalog, useCreateService } from "@/hooks/useServices";
import { ArrowLeft, SprayCan, Utensils, Wrench } from "lucide-react";
import { useRouter, useParams } from "next/navigation";
import { useState, useMemo } from "react";
import Link from "next/link";

const IconMap: Record<string, React.ElementType> = {
  broom: SprayCan,
  wrench: Wrench,
  utensils: Utensils,
};

export default function CreateServicePage() {
  const router = useRouter();
  const params = useParams();
  const taskType = params.type as string;

  const { data: catalog, isLoading: isCatalogLoading } = useServiceCatalog();
  const createService = useCreateService();

  const [description, setDescription] = useState("");
  const [errorMsg, setErrorMsg] = useState("");

  const service = useMemo(() => {
    return catalog?.find((s) => s.task_type === taskType);
  }, [catalog, taskType]);

  if (isCatalogLoading) {
    return (
      <div className="p-6 max-w-lg mx-auto pb-24">
        <div className="h-8 w-1/3 bg-gray-800 rounded mb-6 animate-pulse"></div>
        <div className="h-48 bg-gray-800 rounded-xl animate-pulse"></div>
      </div>
    );
  }

  if (!service) {
    return (
      <div className="p-6 max-w-lg mx-auto pb-24 text-center mt-10">
        <h2 className="text-xl font-semibold text-white mb-2">Service not found</h2>
        <p className="text-gray-400 mb-6">The requested service type is invalid.</p>
        <Link href="/services" className="bg-blue-600 text-white px-4 py-2 rounded-lg">
          Back to Services
        </Link>
      </div>
    );
  }

  const IconComponent = IconMap[service.icon] || SprayCan;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg("");

    createService.mutate(
      { task_type: service.task_type, description: description.trim() },
      {
        onSuccess: () => {
          router.replace("/services/history");
        },
        onError: () => {
          setErrorMsg("Failed to create request. Please try again.");
        },
      }
    );
  };

  return (
    <div className="p-6 pb-24 max-w-lg mx-auto">
      <header className="flex items-center gap-3 mb-8">
        <button onClick={() => router.back()} className="p-2 -ml-2 text-gray-400 hover:text-white transition-colors">
          <ArrowLeft size={20} />
        </button>
        <h1 className="text-2xl font-semibold text-white">Request Service</h1>
      </header>

      <div className="bg-gray-800 border border-gray-700 rounded-xl p-6 mb-6">
        <div className="flex items-center gap-4 mb-4">
          <div className="bg-gray-900 p-3 rounded-lg text-blue-400">
            <IconComponent size={24} />
          </div>
          <div>
            <h2 className="text-xl font-medium text-white">{service.display_name}</h2>
          </div>
        </div>
        <p className="text-sm text-gray-400">{service.description}</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label htmlFor="description" className="block text-sm font-medium text-gray-300 mb-2">
            Additional Details (Optional)
          </label>
          <textarea
            id="description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            rows={4}
            className="w-full bg-gray-900 border border-gray-700 rounded-xl p-4 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-shadow resize-none"
            placeholder="E.g., Please bring extra pillows..."
          />
        </div>

        {errorMsg && (
          <p className="text-red-400 text-sm">{errorMsg}</p>
        )}

        <button
          type="submit"
          disabled={createService.isPending}
          className="w-full bg-blue-600 hover:bg-blue-500 text-white font-medium py-3.5 rounded-xl transition-colors disabled:opacity-50 flex justify-center items-center"
        >
          {createService.isPending ? (
            <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
          ) : (
            "Submit Request"
          )}
        </button>
      </form>
    </div>
  );
}
