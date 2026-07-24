import { useState, useEffect } from 'react';
import { CalendarDays } from 'lucide-react';

export default function DateRangeFilter({ onChange, defaults = {} }) {
  const today = new Date().toISOString().split('T')[0];
  const [startDate, setStartDate] = useState(defaults.startDate || today);
  const [endDate, setEndDate] = useState(defaults.endDate || today);

  useEffect(() => {
    onChange({ startDate, endDate });
  }, []);

  const handleApply = () => {
    onChange({ startDate, endDate });
  };

  return (
    <div className="flex flex-wrap items-end gap-3 bg-white p-4 rounded-xl border border-slate-100 shadow-sm">
      <div>
        <label className="block text-xs font-medium text-slate-500 mb-1">From</label>
        <input
          type="date"
          value={startDate}
          onChange={(e) => setStartDate(e.target.value)}
          className="saas-input text-sm"
        />
      </div>
      <div>
        <label className="block text-xs font-medium text-slate-500 mb-1">To</label>
        <input
          type="date"
          value={endDate}
          onChange={(e) => setEndDate(e.target.value)}
          className="saas-input text-sm"
        />
      </div>
      <button
        onClick={handleApply}
        className="flex items-center gap-2 bg-emerald-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-emerald-700 transition-colors"
      >
        <CalendarDays className="w-4 h-4" />
        Apply
      </button>
    </div>
  );
}
