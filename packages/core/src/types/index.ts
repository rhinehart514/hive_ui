// HIVE Core Types
export interface User {
  id: string;
  email: string;
  name: string;
  major?: string;
  year?: number;
  residential_status?: string;
}

export interface Space {
  id: string;
  name: string;
  type: 'academic' | 'residential' | 'organization';
  description?: string;
} 