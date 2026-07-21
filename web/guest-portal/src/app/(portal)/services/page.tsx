"use client";

import { useServiceCatalog } from "@/hooks/useServices";
import { SprayCan, Wrench, Utensils, History, ArrowLeft, AlertCircle } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";

// A helper mapping to convert backend icon strings to Lucide components
const IconMap: Record<string, React.ElementType> = {
  broom: SprayCan,
  wrench: Wrench,
  utensils: Utensils,
};

export default function ServicesPage() {
  const router = useRouter();
  const { data: catalog, isLoading, isError } = useServiceCatalog();

  if (isLoading) {
    return (
      <div className="p-6 max-w-lg mx-auto pb-24">
        <div className="h-8 w-1/3 bg-gray-800 rounded mb-6 animate-pulse"></div>
        <div className="space-y-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-24 bg-gray-800 rounded-xl animate-pulse"></div>
          ))}
        </div>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="p-6 max-w-lg mx-auto pb-24 flex flex-col items-center justify-center text-center mt-20">
        <AlertCircle size={48} className="text-red-500 mb-4" />
        <h2 className="text-xl font-semibold text-white mb-2">Could not load services</h2>
        <p className="text-gray-400 mb-6">There was a problem loading the service catalog.</p>
        <button 
          onClick={() => window.location.reload()}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg"
        >
          Retry
        </button>
      </div>
    );
  }

  const services = catalog || [];

  return (
    <div className="p-6 pb-24 max-w-lg mx-auto">
      <header className="flex items-center justify-between mb-8">
        <div className="flex items-center gap-3">
          <button onClick={() => router.push("/dashboard")} className="p-2 -ml-2 text-gray-400 hover:text-white transition-colors">
            <ArrowLeft size={20} />
          </button>
          <h1 className="text-2xl font-semibold text-white">Services</h1>
        </div>
        <Link 
          href="/services/history" 
          className="flex items-center gap-2 text-sm text-blue-400 hover:text-blue-300 bg-blue-900/30 px-3 py-1.5 rounded-full transition-colors"
        >
          <History size={16} />
          History
        </Link>
      </header>

      {services.length === 0 ? (
        <div className="bg-gray-800 rounded-xl p-8 text-center border border-gray-700">
          <p className="text-gray-400">No services are currently available.</p>
        </div>
      ) : (
        <div className="grid gap-4">
          {services.map((service) => {
            const IconComponent = IconMap[service.icon] || SprayCan;
            return (
              <Link
                key={service.task_type}
                href={`/services/${service.task_type}`}
                className="bg-gray-800 border border-gray-700 rounded-xl p-5 flex items-start gap-4 hover:bg-gray-750 transition-colors group"
              >
                <div className="bg-gray-900 p-3 rounded-lg text-blue-400 group-hover:text-blue-300 transition-colors">
                  <IconComponent size={24} />
                </div>
                <div className="flex-1">
                  <h3 className="text-lg font-medium text-white mb-1">
                    {service.display_name}
                  </h3>
                  <p className="text-sm text-gray-400 leading-snug">
                    {service.description}
                  </p>
                </div>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
