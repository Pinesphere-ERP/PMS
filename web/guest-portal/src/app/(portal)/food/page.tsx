"use client";

import { useMenu } from "@/hooks/useFoodAPI";
import { Coffee, ArrowRight, AlertCircle, Search } from "lucide-react";
import Link from "next/link";

export default function FoodHomePage() {
  const { data: categories, isLoading, isError } = useMenu();

  if (isLoading) {
    return (
      <div className="p-6 pb-32 max-w-lg mx-auto">
        <div className="h-8 w-1/2 bg-gray-800 rounded mb-6 animate-pulse"></div>
        <div className="grid grid-cols-2 gap-4">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="h-32 bg-gray-800 rounded-xl animate-pulse"></div>
          ))}
        </div>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="p-6 pb-32 max-w-lg mx-auto text-center mt-20">
        <AlertCircle size={48} className="text-red-500 mb-4 mx-auto" />
        <h2 className="text-xl font-semibold text-white mb-2">Menu Unavailable</h2>
        <p className="text-gray-400 text-sm mb-4">Could not load the menu right now.</p>
        <button onClick={() => window.location.reload()} className="bg-blue-600 text-white px-4 py-2 rounded-lg">Retry</button>
      </div>
    );
  }

  const safeCategories = categories || [];

  return (
    <div className="p-6 pb-32 max-w-lg mx-auto">
      <header className="mb-8">
        <h1 className="text-2xl font-semibold text-white mb-2">In-Room Dining</h1>
        <p className="text-gray-400 text-sm">Delicious food delivered to your room.</p>
      </header>

      <div className="flex gap-3 mb-8">
        <Link href="/food/history" className="flex-1 bg-gray-800 border border-gray-700 p-4 rounded-xl flex items-center justify-between group hover:bg-gray-700 transition">
          <div>
            <h3 className="font-semibold text-white mb-1">Your Orders</h3>
            <p className="text-xs text-gray-400">Track delivery</p>
          </div>
          <ArrowRight size={18} className="text-gray-500 group-hover:text-white transition" />
        </Link>
      </div>

      <div className="mb-6 relative">
        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <Search size={16} className="text-gray-500" />
        </div>
        <input 
          type="text" 
          placeholder="Search menu..." 
          className="w-full bg-gray-900 border border-gray-700 text-white rounded-xl pl-10 pr-4 py-3 text-sm focus:outline-none focus:border-blue-500 transition"
        />
      </div>

      <h2 className="text-lg font-semibold text-white mb-4">Categories</h2>
      
      {safeCategories.length === 0 ? (
        <div className="text-center p-8 bg-gray-800 rounded-xl border border-gray-700">
          <Coffee size={40} className="text-gray-600 mx-auto mb-3" />
          <p className="text-gray-400 text-sm">No items currently available.</p>
        </div>
      ) : (
        <div className="grid grid-cols-2 gap-4">
          {safeCategories.map((cat) => (
            <Link 
              key={cat.id} 
              href={`/food/${cat.id}`}
              className="bg-gray-800 border border-gray-700 rounded-xl p-5 hover:border-blue-500/50 hover:bg-gray-700/50 transition-colors group flex flex-col justify-between aspect-square"
            >
              <div className="bg-gray-900/50 w-10 h-10 rounded-lg flex items-center justify-center text-blue-400 mb-4 group-hover:scale-110 transition-transform">
                <Coffee size={20} />
              </div>
              <div>
                <h3 className="font-semibold text-white text-sm mb-1">{cat.name}</h3>
                <p className="text-xs text-gray-500">{cat.items.length} items</p>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
