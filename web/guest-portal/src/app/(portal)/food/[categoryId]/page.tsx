"use client";

import { useMenu } from "@/hooks/useFoodAPI";
import { useCartStore } from "@/store/useCartStore";
import { ArrowLeft, Plus, Minus, Info } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";

export default function CategoryPage() {
  const params = useParams();
  const categoryId = params.categoryId as string;
  
  const { data: categories, isLoading } = useMenu();
  const { items: cartItems, addItem, updateQuantity, removeItem } = useCartStore();

  if (isLoading) {
    return (
      <div className="p-6 pb-32 max-w-lg mx-auto">
        <div className="h-8 w-1/3 bg-gray-800 rounded mb-8 animate-pulse"></div>
        <div className="space-y-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-24 bg-gray-800 rounded-xl animate-pulse"></div>
          ))}
        </div>
      </div>
    );
  }

  const category = categories?.find(c => c.id === categoryId);

  if (!category) {
    return (
      <div className="p-6 text-center mt-20">
        <h2 className="text-xl font-semibold text-white mb-2">Category not found</h2>
        <Link href="/food" className="text-blue-500">Return to Menu</Link>
      </div>
    );
  }

  return (
    <div className="p-6 pb-40 max-w-lg mx-auto">
      <header className="flex items-center gap-3 mb-8">
        <Link href="/food" className="p-2 -ml-2 text-gray-400 hover:text-white transition">
          <ArrowLeft size={20} />
        </Link>
        <div>
          <h1 className="text-2xl font-semibold text-white">{category.name}</h1>
          {category.description && <p className="text-sm text-gray-400">{category.description}</p>}
        </div>
      </header>

      <div className="space-y-4">
        {category.items.map(item => {
          const cartItem = cartItems.find(i => i.menuItem.id === item.id);
          const quantity = cartItem?.quantity || 0;
          
          return (
            <div key={item.id} className="bg-gray-800 border border-gray-700 rounded-xl p-4 flex justify-between items-center">
              <div className="flex-1 pr-4">
                <div className="flex items-center gap-2 mb-1">
                  <div className={`w-3 h-3 rounded-sm border flex items-center justify-center ${item.veg_type === 'veg' ? 'border-green-500' : item.veg_type === 'non-veg' ? 'border-red-500' : 'border-yellow-500'}`}>
                    <div className={`w-1.5 h-1.5 rounded-full ${item.veg_type === 'veg' ? 'bg-green-500' : item.veg_type === 'non-veg' ? 'bg-red-500' : 'bg-yellow-500'}`}></div>
                  </div>
                  <h3 className="font-medium text-white">{item.name}</h3>
                </div>
                <p className="text-sm font-semibold text-white mb-1">₹{item.price.toFixed(2)}</p>
                {item.description && <p className="text-xs text-gray-400 line-clamp-2">{item.description}</p>}
              </div>
              
              <div className="shrink-0">
                {quantity === 0 ? (
                  <button 
                    onClick={() => addItem(item, 1)}
                    disabled={!item.is_available}
                    className={`px-4 py-2 rounded-lg text-sm font-medium transition ${item.is_available ? 'bg-blue-600/20 text-blue-400 hover:bg-blue-600/30' : 'bg-gray-700 text-gray-500 cursor-not-allowed'}`}
                  >
                    {item.is_available ? 'ADD' : 'SOLD OUT'}
                  </button>
                ) : (
                  <div className="flex items-center gap-3 bg-gray-900 rounded-lg p-1 border border-gray-700">
                    <button 
                      onClick={() => quantity === 1 ? removeItem(item.id) : updateQuantity(item.id, quantity - 1)}
                      className="p-1 text-gray-400 hover:text-white transition"
                    >
                      <Minus size={16} />
                    </button>
                    <span className="text-white font-medium w-4 text-center">{quantity}</span>
                    <button 
                      onClick={() => updateQuantity(item.id, quantity + 1)}
                      className="p-1 text-gray-400 hover:text-white transition"
                    >
                      <Plus size={16} />
                    </button>
                  </div>
                )}
              </div>
            </div>
          );
        })}
        {category.items.length === 0 && (
          <div className="text-center py-10 bg-gray-800 rounded-xl border border-gray-700">
            <Info className="mx-auto text-gray-500 mb-2" size={32} />
            <p className="text-gray-400">No items in this category yet.</p>
          </div>
        )}
      </div>
    </div>
  );
}
