const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api/v1';


export const fetchAPI = async (endpoint, options = {}) => {
  const url = `${API_BASE_URL}${endpoint}`;
  
  const headers = {
    'Content-Type': 'application/json',
    'X-Client-Platform': 'web',
    ...options.headers,
  };

  const token = localStorage.getItem('token');
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  if (options.tenantId) {
    headers['X-Tenant-ID'] = options.tenantId;
    delete options.tenantId;
  }

  const response = await fetch(url, {
    cache: 'no-store',
    ...options,
    headers,
  });

  if (!response.ok) {
    if (response.status === 401) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    const errorData = await response.json().catch(() => ({}));
    let errorMessage = 'API request failed';
    if (errorData.detail) {
      if (Array.isArray(errorData.detail) && errorData.detail.length > 0) {
        errorMessage = errorData.detail[0].msg;
      } else if (typeof errorData.detail === 'string') {
        errorMessage = errorData.detail;
      }
    } else if (errorData.message) {
      errorMessage = errorData.message;
    }
    
    throw new Error(errorMessage);
  }

  const json = await response.json();
  if (json && typeof json === 'object' && 'success' in json && 'data' in json) {
    if (!json.success) {
      throw new Error(json.message || 'API request failed');
    }
    return json.data;
  }
  return json;
};
