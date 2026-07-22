import React, { useState, useMemo, useEffect } from 'react';
import { 
  ChevronLeft, 
  ChevronRight,
  Loader2,
  AlertCircle,
  Search,
  ArrowUpDown
} from 'lucide-react';

export default function DataTable({ 
  columns = [], 
  data = [], 
  loading = false, 
  error = null,
  emptyStateMessage = "No records found.",
  searchable = true,
  searchPlaceholder = "Search...",
  pagination = true,
  itemsPerPage = 10,
  onRowClick = null,
  actions = null
}) {
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [sortConfig, setSortConfig] = useState({ key: null, direction: 'asc' });

  // Handle sort
  const handleSort = (key) => {
    let direction = 'asc';
    if (sortConfig.key === key && sortConfig.direction === 'asc') {
      direction = 'desc';
    }
    setSortConfig({ key, direction });
  };

  // Filter and sort data
  const processedData = useMemo(() => {
    let result = [...data];

    // Global Search Filter (basic string match on all values)
    if (searchTerm) {
      const lowerSearch = searchTerm.toLowerCase();
      result = result.filter((row) => {
        return Object.values(row).some((val) => {
          if (val === null || val === undefined) return false;
          return String(val).toLowerCase().includes(lowerSearch);
        });
      });
    }

    // Sort
    if (sortConfig.key) {
      result.sort((a, b) => {
        const aVal = a[sortConfig.key];
        const bVal = b[sortConfig.key];
        if (aVal < bVal) return sortConfig.direction === 'asc' ? -1 : 1;
        if (aVal > bVal) return sortConfig.direction === 'asc' ? 1 : -1;
        return 0;
      });
    }

    return result;
  }, [data, searchTerm, sortConfig]);

  // Pagination
  const totalPages = Math.max(1, Math.ceil(processedData.length / itemsPerPage));
  const currentData = pagination 
    ? processedData.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage)
    : processedData;

  const handlePageChange = (newPage) => {
    if (newPage >= 1 && newPage <= totalPages) {
      setCurrentPage(newPage);
    }
  };

  // Reset page when search changes
  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm]);

  return (
    <div className="bg-white shadow rounded-lg border border-gray-100 overflow-hidden relative flex flex-col min-h-[400px]">
      
      {/* Top Bar: Search and Custom Actions */}
      <div className="p-4 border-b border-gray-200 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        {searchable ? (
          <div className="relative max-w-md w-full sm:w-80">
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <Search className="h-5 w-5 text-gray-400" />
            </div>
            <input
              type="text"
              placeholder={searchPlaceholder}
              className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:ring-pine focus:border-pine sm:text-sm"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
        ) : <div />}
        <div className="flex-shrink-0 flex space-x-2 w-full sm:w-auto overflow-x-auto pb-2 sm:pb-0">
          {actions}
        </div>
      </div>

      {/* Loading Overlay */}
      {loading && (
        <div className="absolute inset-0 top-[73px] flex flex-col items-center justify-center bg-white/80 z-10 backdrop-blur-sm min-h-[300px]">
           <Loader2 className="h-8 w-8 text-pine animate-spin mb-2" />
           <p className="text-gray-500 text-sm font-medium">Loading data...</p>
        </div>
      )}

      {/* Error Overlay */}
      {error && !loading && (
        <div className="absolute inset-0 top-[73px] flex flex-col items-center justify-center bg-white/95 z-10 min-h-[300px]">
           <AlertCircle className="h-10 w-10 text-red-500 mb-3" />
           <p className="text-gray-800 text-base font-semibold">Failed to load data</p>
           <p className="text-gray-500 text-sm mt-1 max-w-md text-center">{error}</p>
        </div>
      )}

      {/* Table Container */}
      <div className="overflow-x-auto flex-1 relative">
        {!loading && !error && processedData.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-64 text-center">
            <div className="bg-gray-50 p-4 rounded-full mb-3">
              <Search className="h-8 w-8 text-gray-400" />
            </div>
            <p className="text-gray-500 font-medium">{emptyStateMessage}</p>
            {searchTerm && <p className="text-gray-400 text-sm mt-1">Try adjusting your search query.</p>}
          </div>
        ) : (
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50 sticky top-0 z-0">
              <tr>
                {columns.map((col, idx) => (
                  <th 
                    key={idx} 
                    className={`px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider ${col.sortable ? 'cursor-pointer hover:bg-gray-100 select-none transition-colors' : ''}`}
                    onClick={() => col.sortable && col.accessor && handleSort(col.accessor)}
                  >
                    <div className="flex items-center gap-1.5">
                      {col.header}
                      {col.sortable && (
                        <ArrowUpDown className={`h-3 w-3 ${sortConfig.key === col.accessor ? 'text-pine' : 'text-gray-300'}`} />
                      )}
                    </div>
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {currentData.map((row, rowIndex) => (
                <tr 
                  key={row.id || rowIndex} 
                  className={`transition-colors ${onRowClick ? 'cursor-pointer hover:bg-gray-50' : 'hover:bg-gray-50'}`}
                  onClick={() => onRowClick && onRowClick(row)}
                >
                  {columns.map((col, colIndex) => (
                    <td key={colIndex} className={`px-6 py-4 whitespace-nowrap text-sm text-gray-700 ${col.className || ''}`}>
                      {col.render ? col.render(row) : (row[col.accessor] || '—')}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
      
      {/* Pagination Footer */}
      {pagination && !loading && !error && processedData.length > 0 && (
        <div className="bg-gray-50 px-6 py-3 flex items-center justify-between border-t border-gray-200">
          <div className="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
            <div>
              <p className="text-sm text-gray-600">
                Showing <span className="font-semibold text-gray-900">{(currentPage - 1) * itemsPerPage + 1}</span> to <span className="font-semibold text-gray-900">{Math.min(currentPage * itemsPerPage, processedData.length)}</span> of <span className="font-semibold text-gray-900">{processedData.length}</span> results
              </p>
            </div>
            <div>
              <nav className="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
                <button 
                  onClick={() => handlePageChange(currentPage - 1)}
                  disabled={currentPage === 1}
                  className="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  <span className="sr-only">Previous</span>
                  <ChevronLeft className="h-5 w-5" aria-hidden="true" />
                </button>
                <div className="relative inline-flex items-center px-4 py-2 border-t border-b border-gray-300 bg-white text-sm font-medium text-gray-700">
                  Page {currentPage} of {totalPages}
                </div>
                <button 
                  onClick={() => handlePageChange(currentPage + 1)}
                  disabled={currentPage === totalPages}
                  className="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  <span className="sr-only">Next</span>
                  <ChevronRight className="h-5 w-5" aria-hidden="true" />
                </button>
              </nav>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
