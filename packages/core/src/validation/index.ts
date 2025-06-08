import { z } from 'zod';

// Email validation for .edu domains
export const eduEmailSchema = z.string().email().regex(
  /\.edu$/,
  'Must be a valid .edu email address'
);

// User profile validation
export const userProfileSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: eduEmailSchema,
  major: z.string().optional(),
  year: z.number().min(1).max(8).optional(),
  residential_status: z.enum(['on-campus', 'off-campus', 'commuter']).optional(),
}); 