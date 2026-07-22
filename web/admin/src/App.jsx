import { BrowserRouter, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import AdminLayout from './layouts/AdminLayout';

// Property Management (New)
import PropertyDashboard from './pages/PropertyManagement/PropertyDashboard';
import AddPropertyWizard from './pages/PropertyManagement/AddPropertyWizard';
import PropertyDetails from './pages/PropertyManagement/PropertyDetails';
import PropertyRooms from './pages/PropertyManagement/PropertyRooms';

// Subscription Module (New)
import SubscriptionDashboard from './pages/SubscriptionManagement/SubscriptionDashboard';
import SubscriptionManagement from './pages/SubscriptionManagement/SubscriptionManagement';
import SubscriptionPlans from './pages/SubscriptionManagement/SubscriptionPlans';
import PaymentManagement from './pages/SubscriptionManagement/PaymentManagement';
import RenewalManagement from './pages/SubscriptionManagement/RenewalManagement';

// Device Management (New)
import GlobalDeviceConsole from './pages/DeviceManagement/GlobalDeviceConsole';
import MyDevicesPanel from './pages/DeviceManagement/MyDevicesPanel';
import DeviceDiagnosticsPanel from './pages/DeviceManagement/DeviceDiagnosticsPanel';

// Audit Logs (New)
import AuditLogs from './pages/AuditManagement/AuditLogs';
// Global Reports
import GlobalReports from './pages/GlobalReports/GlobalReports';
// System Management
import SystemSettings from './pages/SystemManagement/SystemSettings';

// User Management
import UserManagement from './pages/UserManagement/UserManagement';

// Auth
import Login from './pages/Login';

// Owner Management
import OwnerList from './pages/OwnerManagement/OwnerList';

// Create User for Property
import CreateUserForProperty from './pages/UserManagement/CreateUserForProperty';

const ProtectedRoute = ({ children }) => {
  const token = localStorage.getItem('token');
  const location = useLocation();

  if (!token) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return children;
};

const PublicRoute = ({ children }) => {
  const token = localStorage.getItem('token');
  
  if (token) {
    return <Navigate to="/properties" replace />;
  }

  return children;
};

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={
          <PublicRoute>
            <Login />
          </PublicRoute>
        } />
        
        <Route path="/" element={
          <ProtectedRoute>
            <AdminLayout />
          </ProtectedRoute>
        }>
          <Route index element={<Navigate to="/properties" replace />} />
          
          {/* Property Management */}
          <Route path="properties" element={<PropertyDashboard />} />
          <Route path="properties/add" element={<AddPropertyWizard />} />
          <Route path="properties/:id" element={<PropertyDetails />} />
          <Route path="properties/:id/rooms" element={<PropertyRooms />} />

          {/* Subscription Management */}
          <Route path="subscriptions/dashboard" element={<SubscriptionDashboard />} />
          <Route path="subscriptions/manage" element={<SubscriptionManagement />} />
          <Route path="subscriptions/plans" element={<SubscriptionPlans />} />
          <Route path="subscriptions/payments" element={<PaymentManagement />} />
          <Route path="subscriptions/renewals" element={<RenewalManagement />} />

          {/* Device Management */}
          <Route path="devices/global" element={<GlobalDeviceConsole />} />
          <Route path="devices/owner" element={<MyDevicesPanel />} />
          <Route path="devices/support" element={<DeviceDiagnosticsPanel />} />

          {/* Audit Logs */}
          <Route path="audit" element={<AuditLogs />} />
          {/* Global Reports */}
          <Route path="reports/global" element={<GlobalReports />} />
          {/* System Management */}
          <Route path="settings/system" element={<SystemSettings />} />
          {/* User Management */}
          <Route path="users" element={<UserManagement />} />

          {/* Owner Management */}
          <Route path="owners" element={<OwnerList />} />

          {/* Create User scoped to a Property (property pre-locked) */}
          <Route path="properties/:id/users/create" element={<CreateUserForProperty />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;
