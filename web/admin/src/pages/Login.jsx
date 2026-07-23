import { useState } from 'react';
import { fetchAPI } from '../services/api';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    let device_uid = localStorage.getItem('device_uid');
    if (!device_uid) {
      device_uid = crypto.randomUUID();
      localStorage.setItem('device_uid', device_uid);
    }

    let lat = null;
    let lng = null;
    try {
      const pos = await new Promise((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(resolve, reject, { timeout: 3000 });
      });
      lat = pos.coords.latitude;
      lng = pos.coords.longitude;
    } catch (e) {
      console.warn("Geolocation denied or unavailable:", e);
    }

    const telemetry = {
      browser_name: navigator.userAgentData?.brands?.[0]?.brand || navigator.userAgent,
      platform: navigator.platform,
      os_version: navigator.userAgentData?.platform || navigator.oscpu || "Unknown",
      time_zone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      latitude: lat,
      longitude: lng,
    };

    try {
      const res = await fetchAPI('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password, device_uid, telemetry })
      });
      
      // Persist auth context for the session
      localStorage.setItem('token', res.access_token);
      localStorage.setItem('role_code', res.role_code);
      
      // Store first accessible property if available
      if (res.properties && res.properties.length > 0) {
        const primaryProp = res.properties.find(p => p.is_primary) || res.properties[0];
        localStorage.setItem('property_id', primaryProp.property_id);
        localStorage.setItem('properties', JSON.stringify(res.properties));
      }
      
      // Role-based routing
      if (res.role_code === 'SUPER_ADMIN') {
        window.location.href = '/properties';
      } else if (res.role_code === 'OWNER') {
        window.location.href = '/properties';
      } else if (res.role_code === 'GUEST') {
        window.location.href = '/guest';
      } else {
        // Operational staff — redirect to property dashboard in pinesphere_stay app
        // For now, land on a restricted page
        window.location.href = '/';
      }
    } catch (err) {
      setError(err.message || 'Login failed. Please check your credentials.');
    } finally {
      setLoading(false);
    }
  };


  return (
    <div className="min-h-screen bg-gray-900 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8 bg-gray-800 p-8 rounded-xl shadow-2xl border border-gray-700">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-white">
            Pinesphere PMS
          </h2>
          <p className="mt-2 text-center text-sm text-gray-400">
            Sign in to your account
          </p>
        </div>
        <form className="mt-8 space-y-6" onSubmit={handleLogin}>
          {error && (
            <div className="bg-red-500/10 border border-red-500 text-red-500 px-4 py-3 rounded text-sm">
              {error}
            </div>
          )}
          <div className="rounded-md shadow-sm space-y-4">
            <div>
              <label htmlFor="email-address" className="sr-only">Email address or Username</label>
              <input
                id="email-address"
                name="email"
                type="text"
                autoComplete="email"
                required
                className="appearance-none relative block w-full px-3 py-2 border border-gray-600 placeholder-gray-400 text-white bg-gray-700 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
                placeholder="Email address or Username"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>
            <div>
              <label htmlFor="password" className="sr-only">Password</label>
              <input
                id="password"
                name="password"
                type="password"
                autoComplete="current-password"
                required
                className="appearance-none relative block w-full px-3 py-2 border border-gray-600 placeholder-gray-400 text-white bg-gray-700 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
          </div>

          <div>
            <button
              type="submit"
              disabled={loading}
              className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:bg-blue-400 disabled:cursor-not-allowed transition-colors"
            >
              {loading ? 'Signing in...' : 'Sign in'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
