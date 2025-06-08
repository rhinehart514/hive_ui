import { cn } from '@/lib/utils';
import { cva, type VariantProps } from 'class-variance-authority';

// Loading spinner variants
const spinnerVariants = cva(
  'animate-spin rounded-full border-solid border-current',
  {
    variants: {
      size: {
        sm: 'h-4 w-4 border-2',
        default: 'h-8 w-8 border-2',
        lg: 'h-12 w-12 border-3',
        xl: 'h-16 w-16 border-4',
      },
      variant: {
        default: 'border-white/20 border-t-white',
        accent: 'border-[#FFD700]/20 border-t-[#FFD700]',
        subtle: 'border-white/10 border-t-white/60',
      },
    },
    defaultVariants: {
      size: 'default',
      variant: 'default',
    },
  }
);

interface SpinnerProps extends VariantProps<typeof spinnerVariants> {
  className?: string;
}

export function Spinner({ className, size, variant }: SpinnerProps) {
  return (
    <div className={cn(spinnerVariants({ size, variant }), className)} />
  );
}

// Loading skeleton variants
const skeletonVariants = cva(
  'animate-pulse rounded-lg bg-gradient-to-r from-white/5 via-white/10 to-white/5 bg-[length:200%_100%]',
  {
    variants: {
      variant: {
        default: 'bg-white/10',
        card: 'bg-white/5',
        text: 'bg-white/8',
      },
    },
    defaultVariants: {
      variant: 'default',
    },
  }
);

interface SkeletonProps extends VariantProps<typeof skeletonVariants> {
  className?: string;
  width?: string | number;
  height?: string | number;
}

export function Skeleton({ className, variant, width, height }: SkeletonProps) {
  return (
    <div
      className={cn(skeletonVariants({ variant }), className)}
      style={{
        width: typeof width === 'number' ? `${width}px` : width,
        height: typeof height === 'number' ? `${height}px` : height,
      }}
    />
  );
}

// Page loading component
interface PageLoadingProps {
  message?: string;
  size?: 'sm' | 'default' | 'lg';
}

export function PageLoading({ message = 'Loading...', size = 'default' }: PageLoadingProps) {
  return (
    <div className="min-h-screen bg-[#0A0A0A] flex items-center justify-center">
      <div className="text-center space-y-4">
        <Spinner size={size} variant="accent" />
        <p className="text-white/60 text-sm">{message}</p>
      </div>
    </div>
  );
}

// Content loading component
interface ContentLoadingProps {
  message?: string;
  size?: 'sm' | 'default' | 'lg';
  className?: string;
}

export function ContentLoading({ 
  message = 'Loading...', 
  size = 'default',
  className 
}: ContentLoadingProps) {
  return (
    <div className={cn('flex items-center justify-center py-12', className)}>
      <div className="text-center space-y-3">
        <Spinner size={size} variant="accent" />
        <p className="text-white/60 text-sm">{message}</p>
      </div>
    </div>
  );
}

// Card skeleton for feed/list items
export function CardSkeleton() {
  return (
    <div className="bg-white/5 border border-white/10 rounded-lg p-6 space-y-4">
      <div className="flex items-center gap-3">
        <Skeleton className="w-10 h-10 rounded-full" />
        <div className="space-y-2 flex-1">
          <Skeleton className="h-4 w-24" />
          <Skeleton className="h-3 w-16" />
        </div>
      </div>
      <div className="space-y-2">
        <Skeleton className="h-4 w-full" />
        <Skeleton className="h-4 w-3/4" />
        <Skeleton className="h-4 w-1/2" />
      </div>
      <div className="flex gap-6 pt-2">
        <Skeleton className="h-6 w-12" />
        <Skeleton className="h-6 w-12" />
        <Skeleton className="h-6 w-16" />
      </div>
    </div>
  );
}

// Profile skeleton
export function ProfileSkeleton() {
  return (
    <div className="bg-white/5 border border-white/10 rounded-lg p-6 space-y-4">
      <div className="text-center space-y-3">
        <Skeleton className="w-16 h-16 rounded-full mx-auto" />
        <Skeleton className="h-5 w-32 mx-auto" />
        <Skeleton className="h-4 w-24 mx-auto" />
      </div>
      <div className="space-y-2 pt-2">
        {[1, 2, 3].map((i) => (
          <div key={i} className="flex items-center justify-between">
            <Skeleton className="h-4 w-16" />
            <Skeleton className="h-4 w-8" />
          </div>
        ))}
      </div>
    </div>
  );
}

// List skeleton
interface ListSkeletonProps {
  count?: number;
  variant?: 'card' | 'simple';
}

export function ListSkeleton({ count = 3, variant = 'card' }: ListSkeletonProps) {
  if (variant === 'simple') {
    return (
      <div className="space-y-3">
        {Array.from({ length: count }).map((_, i) => (
          <div key={i} className="flex items-center gap-3 p-3">
            <Skeleton className="w-8 h-8 rounded-full" />
            <div className="space-y-2 flex-1">
              <Skeleton className="h-4 w-3/4" />
              <Skeleton className="h-3 w-1/2" />
            </div>
          </div>
        ))}
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {Array.from({ length: count }).map((_, i) => (
        <CardSkeleton key={i} />
      ))}
    </div>
  );
}

// Loading overlay
interface LoadingOverlayProps {
  isVisible: boolean;
  message?: string;
}

export function LoadingOverlay({ isVisible, message = 'Loading...' }: LoadingOverlayProps) {
  if (!isVisible) return null;

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center">
      <div className="bg-[#111]/90 border border-white/10 rounded-lg p-6 max-w-sm mx-4">
        <div className="text-center space-y-4">
          <Spinner size="lg" variant="accent" />
          <p className="text-white text-sm">{message}</p>
        </div>
      </div>
    </div>
  );
} 