import axios from 'axios';

export const apiClient = axios.create({
  baseURL: 'http://localhost:3000', // Points directly to the NestJS backend
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request Interceptor: Attach the JWT token to every request
apiClient.interceptors.request.use(
  (config) => {
    // We store the token in localStorage
    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('parking-auth-token');
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response Interceptor: Handle 401 Unauthorized globally
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      if (typeof window !== 'undefined') {
        // Clear token and redirect to login if unauthorized
        localStorage.removeItem('parking-auth-token');
        if (window.location.pathname !== '/login' && window.location.pathname !== '/forgot-password') {
            window.location.href = '/login';
        }
      }
    }
    return Promise.reject(error);
  }
);
