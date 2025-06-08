import * as React from "react"
import { cn } from "@/lib/utils"

const inputVariants = {
  default: "bg-background border-border focus:border-ring",
  "poll-option": "hive-input-poll-option",
  anonymous: "hive-input-anonymous", 
  "live-chat": "hive-input-live-chat",
}

export interface HiveInputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  variant?: keyof typeof inputVariants
  label?: string
  error?: string
  helper?: string
}

const HiveInput = React.forwardRef<HTMLInputElement, HiveInputProps>(
  ({ className, variant = "default", label, error, helper, ...props }, ref) => {
    return (
      <div className="space-y-2">
        {label && (
          <label className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70">
            {label}
          </label>
        )}
        
        <div className="relative">
          <input
            className={cn(
              "flex h-10 w-full rounded-md border px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50",
              inputVariants[variant],
              error && "border-destructive focus:border-destructive focus:ring-destructive",
              className
            )}
            ref={ref}
            {...props}
          />
          
          {/* Variant-specific indicators */}
          {variant === 'anonymous' && (
            <div className="absolute right-3 top-1/2 -translate-y-1/2">
              <span className="rounded-full bg-muted px-2 py-1 text-xs text-muted-foreground">
                ANONYMOUS
              </span>
            </div>
          )}
          
          {variant === 'live-chat' && (
            <div className="absolute right-3 top-1/2 -translate-y-1/2">
              <div className="h-2 w-2 animate-pulse rounded-full bg-primary"></div>
            </div>
          )}
        </div>
        
        {/* Helper and error text */}
        {(helper || error) && (
          <div className="text-sm">
            {error ? (
              <span className="text-destructive">{error}</span>
            ) : (
              <span className="text-muted-foreground">{helper}</span>
            )}
          </div>
        )}
      </div>
    )
  }
)
HiveInput.displayName = "HiveInput"

export { HiveInput } 