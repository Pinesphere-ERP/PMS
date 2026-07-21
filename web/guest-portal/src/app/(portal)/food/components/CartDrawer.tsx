"use client";

import { useCartStore } from "@/store/useCartStore";
import { useCreateFoodOrder } from "@/hooks/useFoodAPI";
import { ShoppingBag, X, Plus, Minus, Loader2, CheckCircle2 } from "lucide-react";
import { useState } from "react";
import { useRouter, usePathname } from "next/navigation";

export function CartDrawer() {
  const { items, getTotalItems, getTotalPrice, updateQuantity, clearCart } = useCartStore();
  const [isOpen, setIsOpen] = useState(false);
  const [instructions, setInstructions] = useState("");
  const [isSuccess, setIsSuccess] = useState(false);
  const pathname = usePathname();
  const router = useRouter();

  const { mutate: createOrder, isPending } = useCreateFoodOrder();

  const totalItems = getTotalItems();
  const totalPrice = getTotalPrice();

  if (totalItems === 0 && !isOpen) return null;
  if (pathname.includes("/history")) return null; // Don't show cart on history page

  const handleCheckout = () => {
    if (items.length === 0) return;
    
    createOrder({
      items: items.map(i => ({ item_id: i.menuItem.id, quantity: i.quantity })),
      special_instructions: instructions || undefined
    }, {
      onSuccess: () => {
        setIsSuccess(true);
        setTimeout(() => {
          clearCart();
          setIsOpen(false);
          setIsSuccess(false);
          setInstructions("");
          router.push("/food/history");
        }, 2000);
      }
    });
  };

  return (
    <>
      {/* Floating Action Button */}
      {!isOpen && totalItems > 0 && (
        <button 
          onClick={() => setIsOpen(true)}
          className="fixed bottom-24 left-1/2 -translate-x-1/2 w-[calc(100%-3rem)] max-w-sm bg-blue-600 text-white rounded-2xl p-4 shadow-xl shadow-blue-900/20 flex items-center justify-between z-40 transition-transform active:scale-95"
        >
          <div className="flex items-center gap-3">
            <div className="bg-white/20 p-2 rounded-xl">
              <ShoppingBag size={20} />
            </div>
            <div className="text-left">
              <p className="text-sm font-semibold">{totalItems} Item{totalItems > 1 ? 's' : ''}</p>
              <p className="text-xs text-blue-200">View Cart</p>
            </div>
          </div>
          <div className="font-semibold text-lg">
            ₹{totalPrice.toFixed(2)}
          </div>
        </button>
      )}

      {/* Drawer Overlay */}
      {isOpen && (
        <div className="fixed inset-0 z-50 flex justify-center items-end sm:items-center p-0 sm:p-4 bg-black/60 backdrop-blur-sm transition-opacity">
          <div className="bg-gray-900 w-full max-w-lg h-[90vh] sm:h-auto sm:max-h-[85vh] sm:rounded-3xl rounded-t-3xl shadow-2xl flex flex-col animate-in slide-in-from-bottom-10 sm:zoom-in-95 duration-200">
            
            <header className="p-4 border-b border-gray-800 flex justify-between items-center bg-gray-900/95 sticky top-0 rounded-t-3xl z-10">
              <h2 className="text-xl font-semibold text-white flex items-center gap-2">
                <ShoppingBag size={20} className="text-blue-500" />
                Your Order
              </h2>
              <button 
                onClick={() => setIsOpen(false)}
                className="p-2 text-gray-400 hover:text-white bg-gray-800 rounded-full transition"
                disabled={isPending || isSuccess}
              >
                <X size={20} />
              </button>
            </header>

            <div className="flex-1 overflow-y-auto p-4 custom-scrollbar">
              {isSuccess ? (
                <div className="flex flex-col items-center justify-center h-full text-center p-6">
                  <div className="w-16 h-16 bg-green-900/30 rounded-full flex items-center justify-center text-green-500 mb-4 animate-in zoom-in">
                    <CheckCircle2 size={32} />
                  </div>
                  <h3 className="text-xl font-semibold text-white mb-2">Order Placed!</h3>
                  <p className="text-gray-400">Your food is being prepared.</p>
                </div>
              ) : items.length === 0 ? (
                <div className="flex flex-col items-center justify-center h-full text-center text-gray-500">
                  <ShoppingBag size={48} className="mb-4 opacity-50" />
                  <p>Your cart is empty</p>
                </div>
              ) : (
                <div className="space-y-6">
                  <div className="space-y-3">
                    {items.map(item => (
                      <div key={item.menuItem.id} className="flex justify-between items-start">
                        <div className="flex-1 pr-4">
                          <div className="flex items-start gap-2">
                            <div className={`mt-1 shrink-0 w-3 h-3 rounded-sm border flex items-center justify-center ${item.menuItem.veg_type === 'veg' ? 'border-green-500' : item.menuItem.veg_type === 'non-veg' ? 'border-red-500' : 'border-yellow-500'}`}>
                              <div className={`w-1.5 h-1.5 rounded-full ${item.menuItem.veg_type === 'veg' ? 'bg-green-500' : item.menuItem.veg_type === 'non-veg' ? 'bg-red-500' : 'bg-yellow-500'}`}></div>
                            </div>
                            <div>
                              <p className="text-white font-medium text-sm leading-tight">{item.menuItem.name}</p>
                              <p className="text-gray-400 text-xs mt-1">₹{item.menuItem.price.toFixed(2)}</p>
                            </div>
                          </div>
                        </div>
                        <div className="flex flex-col items-end gap-2 shrink-0">
                          <p className="text-white font-semibold text-sm">₹{(item.quantity * item.menuItem.price).toFixed(2)}</p>
                          <div className="flex items-center gap-3 bg-gray-800 rounded-lg p-1 border border-gray-700">
                            <button onClick={() => updateQuantity(item.menuItem.id, item.quantity - 1)} className="p-1 text-gray-400 hover:text-white"><Minus size={14} /></button>
                            <span className="text-white font-medium text-sm w-4 text-center">{item.quantity}</span>
                            <button onClick={() => updateQuantity(item.menuItem.id, item.quantity + 1)} className="p-1 text-gray-400 hover:text-white"><Plus size={14} /></button>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>

                  <div>
                    <label className="text-sm text-gray-400 mb-2 block">Cooking Instructions</label>
                    <textarea 
                      placeholder="E.g. Make it spicy, no onions..."
                      className="w-full bg-gray-800 border border-gray-700 rounded-xl p-3 text-sm text-white focus:outline-none focus:border-blue-500 placeholder:text-gray-600 resize-none h-20"
                      value={instructions}
                      onChange={(e) => setInstructions(e.target.value)}
                    />
                  </div>

                  <div className="bg-gray-800/50 p-4 rounded-xl border border-gray-800 space-y-2">
                    <div className="flex justify-between text-sm text-gray-400">
                      <span>Item Total</span>
                      <span>₹{totalPrice.toFixed(2)}</span>
                    </div>
                    <div className="flex justify-between text-sm text-gray-400">
                      <span>Taxes & Charges</span>
                      <span>Calculated at checkout</span>
                    </div>
                    <div className="pt-2 mt-2 border-t border-gray-700 flex justify-between text-white font-semibold">
                      <span>Grand Total</span>
                      <span>₹{totalPrice.toFixed(2)}</span>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {!isSuccess && items.length > 0 && (
              <div className="p-4 border-t border-gray-800 bg-gray-900/95 sticky bottom-0 sm:rounded-b-3xl">
                <button 
                  onClick={handleCheckout}
                  disabled={isPending}
                  className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-blue-800 disabled:text-blue-300 text-white py-4 rounded-xl font-semibold text-lg shadow-lg flex justify-center items-center gap-2 transition"
                >
                  {isPending ? (
                    <>
                      <Loader2 size={20} className="animate-spin" />
                      Placing Order...
                    </>
                  ) : (
                    `Place Order • ₹${totalPrice.toFixed(2)}`
                  )}
                </button>
                <p className="text-center text-xs text-gray-500 mt-3">
                  Amount will be added to your room folio.
                </p>
              </div>
            )}
            
          </div>
        </div>
      )}
    </>
  );
}
