import * as React from "react"

import { cn } from "@/lib/utils"

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {
  error?: boolean
  icon?: React.ReactNode
}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, error = false, icon, ...props }, ref) => {
    return (
      <div className="relative">
        {icon && (
          <div className="absolute left-3 top-1/2 transform -translate-y-1/2 text-low">
            {icon}
          </div>
        )}
        <input
          type={type}
          className={cn(
            // Base styles with proper rounded-input radius
            "flex h-10 w-full rounded-input border px-3 py-2 text-sm transition-all duration-200",
            "bg-surface-2 text-high placeholder:text-subtle",
            "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2 focus-visible:ring-offset-background",
            "disabled:cursor-not-allowed disabled:opacity-50",
            
            // Border states
            error 
              ? "border-error focus-visible:ring-error" 
              : "border-[var(--c-border)] focus-visible:border-accent hover:border-[var(--c-border-accent)]",
            
            // Icon spacing
            icon && "pl-10",
            
            className
          )}
          ref={ref}
          {...props}
        />
      </div>
    )
  }
)
Input.displayName = "Input"

export { Input }
