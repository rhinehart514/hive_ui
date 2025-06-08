import { format, parseISO } from 'date-fns';

// Date formatting utilities
export const formatEventDate = (dateString: string): string => {
  return format(parseISO(dateString), 'MMM dd, yyyy');
};

export const formatEventTime = (dateString: string): string => {
  return format(parseISO(dateString), 'h:mm a');
};

// String utilities
export const truncateText = (text: string, maxLength: number): string => {
  if (text.length <= maxLength) return text;
  return text.slice(0, maxLength) + '...';
}; 