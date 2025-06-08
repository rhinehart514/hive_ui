import * as React from "react"
import * as AvatarPrimitive from "@radix-ui/react-avatar"
import { cn } from "@/lib/utils"

const avatarSizes = {
  sm: "h-8 w-8 text-xs",
  default: "h-10 w-10 text-sm", 
  lg: "h-12 w-12 text-base",
  xl: "h-16 w-16 text-lg",
}

const statusColors = {
  online: "bg-green-500",
  busy: "bg-red-500", 
  away: "bg-yellow-500",
  offline: "bg-gray-400",
}

const roleColors = {
  builder: "border-primary",
  ra: "border-blue-500",
  leader: "border-green-500",
}

export interface HiveAvatarProps extends React.ComponentPropsWithoutRef<typeof AvatarPrimitive.Root> {
  src?: string
  alt?: string
  size?: keyof typeof avatarSizes
  status?: keyof typeof statusColors
  role?: keyof typeof roleColors
  fallback?: string
}

const HiveAvatar = React.forwardRef<
  React.ElementRef<typeof AvatarPrimitive.Root>,
  HiveAvatarProps
>(({ className, src, alt, size = "default", status, role, fallback, ...props }, ref) => (
  <div className="relative">
    <AvatarPrimitive.Root
      ref={ref}
      className={cn(
        "relative flex shrink-0 overflow-hidden rounded-full",
        avatarSizes[size],
        role && `ring-2 ring-offset-2 ring-offset-background ${roleColors[role]}`,
        className
      )}
      {...props}
    >
      <AvatarPrimitive.Image
        src={src}
        alt={alt}
        className="aspect-square h-full w-full"
      />
      <AvatarPrimitive.Fallback className="flex h-full w-full items-center justify-center rounded-full bg-muted">
        {fallback || "?"}
      </AvatarPrimitive.Fallback>
    </AvatarPrimitive.Root>
    
    {/* Status indicator */}
    {status && (
      <div 
        className={cn(
          "absolute bottom-0 right-0 rounded-full border-2 border-background",
          statusColors[status],
          {
            "h-2 w-2": size === "sm",
            "h-2.5 w-2.5": size === "default", 
            "h-3 w-3": size === "lg",
            "h-4 w-4": size === "xl",
          }
        )}
      />
    )}
  </div>
))
HiveAvatar.displayName = "HiveAvatar"

export { HiveAvatar } 