import { auth } from '@/lib/firebase';

// Base API configuration
const API_BASE_URL = process.env.NODE_ENV === 'production' 
  ? 'https://hive-9265c.web.app/api' 
  : '/api';

// API Error types
export class APIError extends Error {
  constructor(
    message: string,
    public status: number,
    public code?: string
  ) {
    super(message);
    this.name = 'APIError';
  }
}

// Request configuration
interface RequestConfig extends RequestInit {
  requireAuth?: boolean;
  timeout?: number;
}

// Response wrapper for consistent API responses
export interface APIResponse<T = any> {
  data: T;
  success: boolean;
  message?: string;
  error?: string;
}

// Main API client class
class APIClient {
  private baseURL: string;
  private defaultTimeout: number = 10000;

  constructor(baseURL: string) {
    this.baseURL = baseURL;
  }

  private async getAuthToken(): Promise<string | null> {
    try {
      const user = auth.currentUser;
      if (!user) return null;
      return await user.getIdToken();
    } catch (error) {
      console.error('Failed to get auth token:', error);
      return null;
    }
  }

  private async makeRequest<T>(
    endpoint: string,
    config: RequestConfig = {}
  ): Promise<APIResponse<T>> {
    const {
      requireAuth = false,
      timeout = this.defaultTimeout,
      headers = {},
      ...fetchConfig
    } = config;

    // Prepare headers
    const requestHeaders: Record<string, string> = {
      'Content-Type': 'application/json',
      ...headers,
    };

    // Add authentication if required
    if (requireAuth) {
      const token = await this.getAuthToken();
      if (!token) {
        throw new APIError('Authentication required', 401, 'UNAUTHORIZED');
      }
      requestHeaders['Authorization'] = `Bearer ${token}`;
    }

    // Create abort controller for timeout
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);

    try {
      const response = await fetch(`${this.baseURL}${endpoint}`, {
        ...fetchConfig,
        headers: requestHeaders,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      // Handle non-JSON responses
      const contentType = response.headers.get('content-type');
      if (!contentType?.includes('application/json')) {
        if (!response.ok) {
          throw new APIError(
            `HTTP ${response.status}: ${response.statusText}`,
            response.status
          );
        }
        return {
          data: null as T,
          success: true,
        };
      }

      const result = await response.json();

      if (!response.ok) {
        throw new APIError(
          result.error || result.message || `HTTP ${response.status}`,
          response.status,
          result.code
        );
      }

      return result;
    } catch (error) {
      clearTimeout(timeoutId);

      if (error instanceof APIError) {
        throw error;
      }

      if (error instanceof DOMException && error.name === 'AbortError') {
        throw new APIError('Request timeout', 408, 'TIMEOUT');
      }

      throw new APIError(
        error instanceof Error ? error.message : 'Network error',
        0,
        'NETWORK_ERROR'
      );
    }
  }

  // HTTP Methods
  async get<T>(endpoint: string, config?: RequestConfig): Promise<APIResponse<T>> {
    return this.makeRequest<T>(endpoint, { ...config, method: 'GET' });
  }

  async post<T>(
    endpoint: string,
    data?: any,
    config?: RequestConfig
  ): Promise<APIResponse<T>> {
    return this.makeRequest<T>(endpoint, {
      ...config,
      method: 'POST',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  async put<T>(
    endpoint: string,
    data?: any,
    config?: RequestConfig
  ): Promise<APIResponse<T>> {
    return this.makeRequest<T>(endpoint, {
      ...config,
      method: 'PUT',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  async patch<T>(
    endpoint: string,
    data?: any,
    config?: RequestConfig
  ): Promise<APIResponse<T>> {
    return this.makeRequest<T>(endpoint, {
      ...config,
      method: 'PATCH',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  async delete<T>(endpoint: string, config?: RequestConfig): Promise<APIResponse<T>> {
    return this.makeRequest<T>(endpoint, { ...config, method: 'DELETE' });
  }
}

// Export singleton instance
export const apiClient = new APIClient(API_BASE_URL);

// Convenience functions for common use cases
export const api = {
  // Authentication endpoints
  auth: {
    status: () => apiClient.get('/auth/status'),
    setToken: (token: string) => apiClient.post('/auth/status', { token }),
    clearAuth: () => apiClient.delete('/auth/status'),
  },

  // User endpoints
  users: {
    getProfile: (uid: string) => apiClient.get(`/users/${uid}`, { requireAuth: true }),
    updateProfile: (uid: string, data: any) => 
      apiClient.patch(`/users/${uid}`, data, { requireAuth: true }),
  },

  // Spaces endpoints (to be implemented in Phase 3)
  spaces: {
    list: () => apiClient.get('/spaces', { requireAuth: true }),
    get: (id: string) => apiClient.get(`/spaces/${id}`, { requireAuth: true }),
    join: (id: string) => apiClient.post(`/spaces/${id}/join`, {}, { requireAuth: true }),
    leave: (id: string) => apiClient.post(`/spaces/${id}/leave`, {}, { requireAuth: true }),
  },

  // Events endpoints (to be implemented in Phase 4)
  events: {
    list: () => apiClient.get('/events', { requireAuth: true }),
    get: (id: string) => apiClient.get(`/events/${id}`, { requireAuth: true }),
    rsvp: (id: string, status: 'yes' | 'no' | 'maybe') => 
      apiClient.post(`/events/${id}/rsvp`, { status }, { requireAuth: true }),
  },
}; 