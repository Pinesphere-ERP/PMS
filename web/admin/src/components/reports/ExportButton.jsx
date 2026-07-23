import { Download } from 'lucide-react';
import { useState } from 'react';
import { fetchAPI } from '../../services/api';

export default function ExportButton({ reportType, params = {}, className = '' }) {
  const [loading, setLoading] = useState(false);

  const handleExport = async () => {
    setLoading(true);
    try {
      const query = new URLSearchParams();
      for (const [key, value] of Object.entries(params)) {
        if (value != null) query.set(key, value);
      }
      const qs = query.toString();
      const url = `/reports/${reportType}/pdf${qs ? '?' + qs : ''}`;

      const token = localStorage.getItem('token');
      const response = await fetch(`${import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api/v1'}${url}`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'X-Client-Platform': 'web',
        },
      });

      if (!response.ok) throw new Error('Export failed');

      const blob = await response.blob();
      const downloadUrl = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = downloadUrl;
      a.download = `${reportType}_report.pdf`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(downloadUrl);
    } catch (err) {
      alert('Failed to export PDF: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <button
      onClick={handleExport}
      disabled={loading}
      className={`flex items-center gap-2 bg-white border border-slate-200 text-slate-700 px-4 py-2 rounded-lg text-sm font-medium hover:bg-slate-50 transition-colors disabled:opacity-50 ${className}`}
    >
      <Download className="w-4 h-4" />
      {loading ? 'Exporting...' : 'Download PDF'}
    </button>
  );
}
