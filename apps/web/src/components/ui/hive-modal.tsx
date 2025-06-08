'use client'

import * as React from 'react'
import * as DialogPrimitive from '@radix-ui/react-dialog'
import { AnimatePresence, motion } from 'framer-motion'
import { X } from 'lucide-react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

// HIVE Modal Root
const HiveModal = DialogPrimitive.Root

// HIVE Modal Trigger
const HiveModalTrigger = DialogPrimitive.Trigger

// HIVE Modal Portal with AnimatePresence wrapper
const HiveModalPortal = ({ children }: { children: React.ReactNode }) => (
  <DialogPrimitive.Portal>
    <AnimatePresence>{children}</AnimatePresence>
  </DialogPrimitive.Portal>
)
HiveModalPortal.displayName = DialogPrimitive.Portal.displayName

// HIVE Modal Overlay with blur and dim effects
const HiveModalOverlay = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Overlay>,
  React.ComponentPropsWithoutRef<typeof DialogPrimitive.Overlay>
>(({ className, ...props }, ref) => (
  <DialogPrimitive.Overlay asChild>
    <motion.div
      ref={ref}
      className={cn("fixed inset-0 z-50 bg-background/80 backdrop-blur-sm", className)}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ type: 'spring', stiffness: 300, damping: 30 }}
      {...props}
    />
  </DialogPrimitive.Overlay>
))
HiveModalOverlay.displayName = DialogPrimitive.Overlay.displayName

const modalContentVariants = cva(
  "fixed z-50 grid w-full gap-4 rounded-2xl p-6 shadow-lg",
  {
    variants: {
      variant: {
        default: "bg-card border border-border",
        glass: "glass-card",
      },
      size: {
        sm: 'max-w-sm',
        default: 'max-w-lg',
        lg: 'max-w-2xl',
        xl: 'max-w-4xl',
        full: 'max-w-[95vw] h-[95vh]',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
)

export interface HiveModalContentProps
  extends React.ComponentPropsWithoutRef<typeof DialogPrimitive.Content>,
    VariantProps<typeof modalContentVariants> {}

// HIVE Modal Content with Z-zoom cinematic entrance
const HiveModalContent = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Content>,
  HiveModalContentProps
>(({ className, children, variant, size, ...props }, ref) => (
  <HiveModalPortal>
    <HiveModalOverlay />
    <DialogPrimitive.Content ref={ref} asChild {...props}>
      <motion.div
        className={cn(modalContentVariants({ variant, size }), className)}
        initial={{ opacity: 0, scale: 0.9, y: "-48%", x: "-50%", rotateX: -10 }}
        animate={{ opacity: 1, scale: 1, y: "-50%", x: "-50%", rotateX: 0 }}
        exit={{ opacity: 0, scale: 0.95, y: "-48%", x: "-50%", rotateX: 10 }}
        transition={{ type: 'spring', stiffness: 400, damping: 30, mass: 1 }}
        style={{ perspective: 1000, top: '50%', left: '50%' }}
      >
        {children}
        <DialogPrimitive.Close asChild>
          <motion.button
            className="absolute right-4 top-4 rounded-full p-1.5 text-muted-foreground transition-colors hover:bg-secondary hover:text-foreground"
            whileHover={{ scale: 1.1, rotate: 90 }}
            whileTap={{ scale: 0.9 }}
          >
            <X className="h-4 w-4" />
            <span className="sr-only">Close</span>
          </motion.button>
        </DialogPrimitive.Close>
      </motion.div>
    </DialogPrimitive.Content>
  </HiveModalPortal>
))
HiveModalContent.displayName = DialogPrimitive.Content.displayName

// HIVE Modal Header with gradient support
const HiveModalHeader = ({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) => (
  <div className={cn("flex flex-col space-y-1.5 text-center sm:text-left", className)} {...props} />
)
HiveModalHeader.displayName = "HiveModalHeader"

// HIVE Modal Footer with actions
const HiveModalFooter = ({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) => (
  <div className={cn("flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2", className)} {...props} />
)
HiveModalFooter.displayName = "HiveModalFooter"

// HIVE Modal Title component
const HiveModalTitle = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Title>,
  React.ComponentPropsWithoutRef<typeof DialogPrimitive.Title>
>(({ className, ...props }, ref) => (
  <DialogPrimitive.Title
    ref={ref}
    className={cn("text-lg font-semibold leading-none tracking-tight", className)}
    {...props}
  />
))
HiveModalTitle.displayName = DialogPrimitive.Title.displayName

// HIVE Modal Description component
const HiveModalDescription = React.forwardRef<
  React.ElementRef<typeof DialogPrimitive.Description>,
  React.ComponentPropsWithoutRef<typeof DialogPrimitive.Description>
>(({ className, ...props }, ref) => (
  <DialogPrimitive.Description
    ref={ref}
    className={cn("text-sm text-muted-foreground", className)}
    {...props}
  />
))
HiveModalDescription.displayName = DialogPrimitive.Description.displayName

// Convenience hook for modal state
const useHiveModal = () => {
  const [isOpen, setIsOpen] = React.useState(false)
  
  const openModal = React.useCallback(() => setIsOpen(true), [])
  const closeModal = React.useCallback(() => setIsOpen(false), [])
  const toggleModal = React.useCallback(() => setIsOpen(prev => !prev), [])
  
  return {
    isOpen,
    openModal,
    closeModal,
    toggleModal,
    setIsOpen
  }
}

export {
  HiveModal,
  HiveModalTrigger,
  HiveModalContent,
  HiveModalHeader,
  HiveModalFooter,
  HiveModalTitle,
  HiveModalDescription,
  useHiveModal
} 