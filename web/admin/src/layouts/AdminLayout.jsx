import { Outlet, NavLink, useLocation, useNavigate } from 'react-router-dom';
import { 
  Building2, 
  ClipboardCheck, 
  CreditCard,
  History,
  Key,
  Smartphone,
  Menu,
  Bell,
  Search,
  User,
  Trees,
  ChevronRight,
  PieChart,
  Shield,
  ShieldAlert,
  LogOut,
  Crown,
  Users
} from 'lucide-react';
import { useState } from 'react';

const ownerNavigation = [
  { name: 'Owners', to: '/owners', icon: Crown },
];

const propertyNavigation = [
  { name: 'Property Dashboard', to: '/properties', icon: Building2 }
];

const subscriptionNavigation = [
  { name: 'Subscription Dashboard', to: '/subscriptions/dashboard', icon: PieChart },
  { name: 'Manage Subscriptions', to: '/subscriptions/manage', icon: Building2 },
  { name: 'Payments', to: '/subscriptions/payments', icon: CreditCard },
  { name: 'Renewals', to: '/subscriptions/renewals', icon: History },
];

const deviceNavigation = [
  { name: 'Global Console (Admin)', to: '/devices/global', icon: Smartphone },
  { name: 'My Devices (Owner)', to: '/devices/owner', icon: Key },
  { name: 'Diagnostics (Support)', to: '/devices/support', icon: ClipboardCheck },
];

const auditNavigation = [
  { name: 'System Audit Logs', to: '/audit', icon: ShieldAlert },
];

const systemNavigation = [
  { name: 'System Configuration', to: '/settings/system', icon: Shield },
  { name: 'User Management', to: '/users', icon: User },
];

export default function AdminLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const location = useLocation();
  const navigate = useNavigate();

  // Helper to generate breadcrumbs from path
  const pathParts = location.pathname.split('/').filter(Boolean);
  const breadcrumbs = pathParts.map((part) => part.charAt(0).toUpperCase() + part.slice(1));

  const handleLogout = () => {
    localStorage.removeItem('token');
    // Assuming there's a /login route or simply redirect to the landing page
    navigate('/login');
  };

  return (
    <div className="min-h-screen bg-gray-50 flex font-sans text-gray-900 selection:bg-pine-light/20 selection:text-pine">
      {/* Sidebar */}
      <aside className={`fixed inset-y-0 left-0 z-50 w-64 bg-white/70 backdrop-blur-md border-r border-gray-200 transform transition-transform duration-200 ease-in-out ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'} lg:relative lg:translate-x-0 shadow-sm`}>
        <div className="h-16 flex items-center px-6 border-b border-gray-100">
          <Trees className="h-6 w-6 text-pine mr-2" />
          <span className="text-lg font-semibold text-gray-900 tracking-tight">Pinesphere</span>
        </div>
        
        <div className="px-4 py-6">
          <p className="px-2 text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">
            Owner Management
          </p>
          <nav className="space-y-1 mb-6">
            {ownerNavigation.map((item) => (
              <NavLink
                key={item.name}
                to={item.to}
                className={({ isActive }) =>
                  `flex items-center px-2 py-2 text-sm font-medium rounded-lg transition-colors duration-150 ${
                    isActive
                      ? 'bg-amber-50 text-amber-700'
                      : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
                  }`
                }
              >
                <item.icon className={`mr-3 h-4 w-4 flex-shrink-0 ${
                  location.pathname.startsWith(item.to) ? 'text-amber-600' : 'text-gray-400'
                }`} />
                {item.name}
              </NavLink>
            ))}
          </nav>

          <p className="px-2 text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">
            Property Management
          </p>
          <nav className="space-y-1 mb-6">
            {propertyNavigation.map((item) => (
              <NavLink
                key={item.name}
                to={item.to}
                className={({ isActive }) =>
                  `flex items-center px-2 py-2 text-sm font-medium rounded-lg transition-colors duration-150 ${
                    isActive
                      ? 'bg-pine-50 text-pine-DEFAULT'
                      : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
                  }`
                }
              >
                <item.icon className={`mr-3 h-4 w-4 flex-shrink-0 ${
                  location.pathname.startsWith(item.to) && (item.to !== '/properties' || location.pathname === '/properties') ? 'text-pine-DEFAULT' : 'text-gray-400'
                }`} />
                {item.name}
              </NavLink>
            ))}
          </nav>

          <p className="px-2 text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">
            Subscription Module
          </p>
          <nav className="space-y-1 mb-6">
            {subscriptionNavigation.map((item) => (
              <NavLink
                key={item.name}
                to={item.to}
                className={({ isActive }) =>
                  `flex items-center px-2 py-2 text-sm font-medium rounded-lg transition-colors duration-150 ${
                    isActive
                      ? 'bg-pine-50 text-pine-DEFAULT'
                      : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
                  }`
                }
              >
                <item.icon className={`mr-3 h-4 w-4 flex-shrink-0 ${
                  location.pathname === item.to ? 'text-pine-DEFAULT' : 'text-gray-400'
                }`} />
                {item.name}
              </NavLink>
            ))}
          </nav>

          <p className="px-2 text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">
            Device Management
          </p>
          <nav className="space-y-1">
            {deviceNavigation.map((item) => (
              <NavLink
                key={item.name}
                to={item.to}
                className={({ isActive }) =>
                  `flex items-center px-2 py-2 text-sm font-medium rounded-lg transition-colors duration-150 ${
                    isActive
                      ? 'bg-pine-50 text-pine-DEFAULT'
                      : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
                  }`
                }
              >
                <item.icon className={`mr-3 h-4 w-4 flex-shrink-0 ${
                  location.pathname === item.to ? 'text-pine-DEFAULT' : 'text-gray-400'
                }`} />
                {item.name}
              </NavLink>
            ))}
          </nav>

          <p className="px-2 text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">
            System Management
          </p>
          <nav className="space-y-1">
            {systemNavigation.map((item) => (
              <NavLink
                key={item.name}
                to={item.to}
                className={({ isActive }) =>
                  `flex items-center px-2 py-2 text-sm font-medium rounded-lg transition-colors duration-150 ${
                    isActive
                      ? 'bg-pine-50 text-pine-DEFAULT'
                      : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
                  }`
                }
              >
                <item.icon className={`mr-3 h-4 w-4 flex-shrink-0 ${
                  location.pathname === item.to ? 'text-pine-DEFAULT' : 'text-gray-400'
                }`} />
                {item.name}
              </NavLink>
            ))}
          </nav>

          <p className="px-2 text-xs font-semibold text-gray-400 uppercase tracking-wider mt-6 mb-2">
            Security & Compliance
          </p>
          <nav className="space-y-1">
            {auditNavigation.map((item) => (
              <NavLink
                key={item.name}
                to={item.to}
                className={({ isActive }) =>
                  `flex items-center px-2 py-2 text-sm font-medium rounded-lg transition-colors duration-150 ${
                    isActive
                      ? 'bg-pine-50 text-pine-DEFAULT'
                      : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
                  }`
                }
              >
                <item.icon className={`mr-3 h-4 w-4 flex-shrink-0 ${
                  location.pathname === item.to ? 'text-pine-DEFAULT' : 'text-gray-400'
                }`} />
                {item.name}
              </NavLink>
            ))}
          </nav>
        </div>
      </aside>

      {/* Main Content */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* Topbar */}
        <header className="h-16 bg-white/70 backdrop-blur-md border-b border-gray-200 flex items-center justify-between px-4 sm:px-6 lg:px-8 z-10">
          <div className="flex items-center flex-1">
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="lg:hidden p-2 -ml-2 mr-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100"
            >
              <Menu className="h-5 w-5" />
            </button>
            
            {/* Breadcrumbs */}
            <div className="hidden sm:flex items-center space-x-2 text-sm text-gray-500">
              <span>Admin</span>
              {breadcrumbs.map((crumb, idx) => (
                <div key={idx} className="flex items-center space-x-2">
                  <ChevronRight className="h-4 w-4 text-gray-400" />
                  <span className={idx === breadcrumbs.length - 1 ? "font-medium text-gray-900" : ""}>
                    {crumb}
                  </span>
                </div>
              ))}
            </div>
          </div>
          
          <div className="flex items-center space-x-4 ml-4">
            <div className="relative hidden md:block">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Search className="h-4 w-4 text-gray-400" />
              </div>
              <input
                type="text"
                className="saas-input pl-9 w-64 lg:w-80"
                placeholder="Search everywhere..."
              />
            </div>
            
            <button className="p-2 text-gray-400 hover:text-gray-500 relative">
              <Bell className="h-5 w-5" />
              <span className="absolute top-1.5 right-1.5 block h-2 w-2 rounded-full bg-pine ring-2 ring-white"></span>
            </button>
            <div className="h-8 w-8 rounded-full bg-pine-100 border border-pine-200 flex items-center justify-center cursor-pointer hover:ring-2 ring-pine ring-offset-2 transition-all">
              <User className="h-4 w-4 text-pine-DEFAULT" />
            </div>
            <button 
              onClick={handleLogout}
              className="p-2 text-gray-400 hover:text-red-600 transition-colors"
              title="Log out"
            >
              <LogOut className="h-5 w-5" />
            </button>
          </div>
        </header>

        {/* Page Content */}
        <main className="flex-1 overflow-y-auto bg-gray-50 p-4 sm:p-6 lg:p-8 animate-fade-in relative">
          <div className="max-w-7xl mx-auto">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
}
