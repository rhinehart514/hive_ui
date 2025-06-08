import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Animation easing curves that match HIVE's sophisticated motion design
export const easings = {
  // HIVE's primary easing for premium feel
  hiveEase: [0.25, 0.8, 0.25, 1] as const,
  
  // For surface fade animations
  surfaceFade: [0.4, 0, 0.2, 1] as const,
  
  // For content slide animations
  contentSlide: [0.0, 0, 0.2, 1] as const,
  
  // For tap feedback
  tapFeedback: [0.4, 0, 1, 1] as const,
  
  // For deep press interactions
  deepPress: [0.2, 0, 0.2, 1] as const,
  
  // For page transitions
  pageTransition: [0.25, 0.8, 0.30, 1] as const,
} as const;

// Animation durations matching HIVE's motion standards
export const durations = {
  // Micro-interactions
  micro: 150,
  tap: 150,
  
  // Button interactions
  button: 200,
  
  // Surface animations
  surface: 300,
  
  // Content transitions
  content: 400,
  
  // Page transitions
  page: 320,
  
  // Modal animations
  modal: 400,
} as const;

// Stagger configurations for consistent timing
export const staggerConfig = {
  default: {
    staggerChildren: 0.15,
  },
  fast: {
    staggerChildren: 0.1,
  },
  slow: {
    staggerChildren: 0.2,
  },
} as const;

// Common animation variants
export const animationVariants = {
  fadeInUp: {
    initial: { opacity: 0, y: 60 },
    animate: { opacity: 1, y: 0 },
    transition: { duration: 0.8, ease: easings.hiveEase }
  },
  
  fadeInScale: {
    initial: { opacity: 0, scale: 0.9 },
    animate: { opacity: 1, scale: 1 },
    transition: { duration: 0.6, ease: easings.hiveEase }
  },
  
  slideInLeft: {
    initial: { opacity: 0, x: -60 },
    animate: { opacity: 1, x: 0 },
    transition: { duration: 0.8, ease: easings.contentSlide }
  },
  
  slideInRight: {
    initial: { opacity: 0, x: 60 },
    animate: { opacity: 1, x: 0 },
    transition: { duration: 0.8, ease: easings.contentSlide }
  },
} as const;

// HIVE brand colors for programmatic use
export const hiveColors = {
  black: '#0D0D0D',
  surface: '#1E1E1E',
  surfaceLight: '#2A2A2A',
  gold: '#FFD700',
  goldHover: '#FFDF2B',
  goldPressed: '#CCAD00',
  success: '#8CE563',
  error: '#FF3B30',
  warning: '#FF9500',
  info: '#56CCF2',
} as const;

// Responsive breakpoints
export const breakpoints = {
  sm: '640px',
  md: '768px',
  lg: '1024px',
  xl: '1280px',
  '2xl': '1536px',
} as const;

// Typography scale matching HIVE's design system
export const typography = {
  caption: {
    fontSize: '14px',
    lineHeight: '17px',
  },
  body: {
    fontSize: '17px',
    lineHeight: '22px',
  },
  title: {
    fontSize: '22px',
    lineHeight: '28px',
  },
  headline: {
    fontSize: '28px',
    lineHeight: '34px',
  },
  display: {
    fontSize: '34px',
    lineHeight: '41px',
  },
} as const;

// Helper function to create smooth scroll behavior
export const smoothScrollTo = (elementId: string, offset: number = 0) => {
  const element = document.getElementById(elementId);
  if (element) {
    const top = element.offsetTop - offset;
    window.scrollTo({
      top,
      behavior: 'smooth',
    });
  }
};

// Helper function to detect reduced motion preference
export const prefersReducedMotion = () => {
  if (typeof window === 'undefined') return false;
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
};

// Helper function to create responsive animations
export const createResponsiveAnimation = (
  mobileVariant: any,
  desktopVariant: any,
  breakpoint: string = '768px'
) => {
  if (typeof window === 'undefined') return desktopVariant;
  
  const mediaQuery = window.matchMedia(`(max-width: ${breakpoint})`);
  return mediaQuery.matches ? mobileVariant : desktopVariant;
};

// Performance optimized scroll handler
export const throttle = (func: Function, limit: number) => {
  let inThrottle: boolean;
  return function (this: any, ...args: any[]) {
    if (!inThrottle) {
      func.apply(this, args);
      inThrottle = true;
      setTimeout(() => (inThrottle = false), limit);
    }
  };
};

// Intersection Observer helper for performance
export const createIntersectionObserver = (
  callback: IntersectionObserverCallback,
  options?: IntersectionObserverInit
) => {
  const defaultOptions: IntersectionObserverInit = {
    threshold: 0.1,
    rootMargin: '0px 0px -100px 0px',
    ...options,
  };
  
  return new IntersectionObserver(callback, defaultOptions);
}; 