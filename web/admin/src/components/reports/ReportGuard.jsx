import { Navigate } from 'react-router-dom';
import { getUserRole, canAccessReport } from '../../utils/roleUtils';

export default function ReportGuard({ reportType, children }) {
  const role = getUserRole();

  if (!role) {
    return <Navigate to="/login" replace />;
  }

  if (!canAccessReport(role, reportType)) {
    return (
      <div className="flex flex-col items-center justify-center h-[60vh] text-center">
        <div className="bg-red-50 border border-red-200 rounded-xl p-8 max-w-md">
          <h2 className="text-xl font-bold text-red-700 mb-2">Access Denied</h2>
          <p className="text-red-600 text-sm">
            You do not have permission to view this report.
            Contact your administrator if you believe this is an error.
          </p>
        </div>
      </div>
    );
  }

  return children;
}
