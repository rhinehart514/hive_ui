'use client'

import { motion, useMotionValue, useSpring, useTransform } from 'framer-motion'
import { useState, useRef } from 'react'
import { Terminal, ArrowRight, Cpu } from 'lucide-react'

interface AnimatedButtonProps {
  children: React.ReactNode
  onClick?: () => void
  variant?: 'primary' | 'secondary' | 'ghost' | 'system'
  size?: 'sm' | 'md' | 'lg'
  className?: string
  icon?: boolean
  disabled?: boolean
  systemIcon?: 'terminal' | 'cpu' | 'arrow'
}

export default function AnimatedButton({
  children,
  onClick,
  variant = 'primary',
  size = 'md',
  className = '',
  icon = false,
  disabled = false,
  systemIcon = 'arrow'
}: AnimatedButtonProps) {
  const ref = useRef<HTMLButtonElement>(null)
  const [isHovered, setIsHovered] = useState(false)
  const [isPressed, setIsPressed] = useState(false)
  const [ripples, setRipples] = useState<Array<{ id: number; x: number; y: number }>>([])

  // AI-inspired magnetic effect with neural network transforms
  const x = useMotionValue(0)
  const y = useMotionValue(0)
  
  const mouseX = useSpring(x, { damping: 35, stiffness: 600 })
  const mouseY = useSpring(y, { damping: 35, stiffness: 600 })

  const rotateX = useTransform(mouseY, [-100, 100], [6, -6])
  const rotateY = useTransform(mouseX, [-100, 100], [-6, 6])
  const scale = useTransform(mouseX, [-100, 100], [1.01, 1.04])

  const handleMouseMove = (e: React.MouseEvent<HTMLButtonElement>) => {
    if (!ref.current || disabled) return
    
    const rect = ref.current.getBoundingClientRect()
    const centerX = rect.left + rect.width / 2
    const centerY = rect.top + rect.height / 2
    
    const offsetX = (e.clientX - centerX) * 0.2
    const offsetY = (e.clientY - centerY) * 0.2
    
    x.set(offsetX)
    y.set(offsetY)
  }

  const handleMouseLeave = () => {
    setIsHovered(false)
    x.set(0)
    y.set(0)
  }

  const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {
    if (disabled) return
    
    const rect = e.currentTarget.getBoundingClientRect()
    const clickX = e.clientX - rect.left
    const clickY = e.clientY - rect.top
    
    const newRipple = { id: Date.now(), x: clickX, y: clickY }
    setRipples(prev => [...prev, newRipple])
    
    setTimeout(() => {
      setRipples(prev => prev.filter(ripple => ripple.id !== newRipple.id))
    }, 800)
    
    onClick?.()
  }

  const baseClasses = 'relative overflow-hidden font-mono font-medium rounded-2xl transition-all duration-500 ease-[cubic-bezier(0.19,1,0.22,1)] focus:outline-none focus:ring-2 focus:ring-white/60 focus:ring-offset-2 focus:ring-offset-black disabled:opacity-30 disabled:cursor-not-allowed will-change-transform neural-hover'
  
  const variants = {
    primary: 'bg-white text-black shadow-lg border border-white/20',
    secondary: 'bg-black border border-white/30 text-white hover:bg-white/5 hover:border-white/60',
    ghost: 'text-white hover:text-white/80 border border-white/20 hover:border-white/40 bg-black/50 backdrop-blur-sm',
    system: 'bg-gradient-to-r from-black to-gray-900 border border-white/20 text-white hover:border-white/40'
  }
  
  const sizes = {
    sm: 'px-4 py-2 text-sm h-9',
    md: 'px-6 py-3 text-base h-11',
    lg: 'px-8 py-4 text-lg h-14'
  }

  const iconVariants = {
    rest: { x: 0, rotate: 0, scale: 1 },
    hover: { 
      x: 4,
      rotate: variant === 'system' ? 0 : -10,
      scale: 1.1,
      transition: {
        type: "spring",
        stiffness: 400,
        damping: 15
      }
    }
  }

  const getSystemIcon = () => {
    switch (systemIcon) {
      case 'terminal':
        return <Terminal size={18} />
      case 'cpu':
        return <Cpu size={18} />
      default:
        return <ArrowRight size={18} />
    }
  }

  return (
    <motion.button
      ref={ref}
      className={`${baseClasses} ${variants[variant]} ${sizes[size]} ${className}`}
      style={{
        rotateX: disabled ? 0 : rotateX,
        rotateY: disabled ? 0 : rotateY,
        scale: disabled ? 1 : scale,
        transformStyle: "preserve-3d",
      }}
      onMouseMove={handleMouseMove}
      onMouseEnter={() => !disabled && setIsHovered(true)}
      onMouseLeave={handleMouseLeave}
      onTapStart={() => !disabled && setIsPressed(true)}
      onTap={() => setIsPressed(false)}
      onClick={handleClick}
      disabled={disabled}
      whileHover={disabled ? {} : { 
        y: -1,
        boxShadow: variant === 'primary' 
          ? "0 0 30px rgba(255, 255, 255, 0.3)"
          : "0 0 20px rgba(255, 255, 255, 0.1)",
        transition: {
          type: "spring",
          stiffness: 400,
          damping: 20,
        }
      }}
      whileTap={disabled ? {} : { 
        scale: 0.98,
        y: 0,
        transition: {
          type: "spring",
          stiffness: 600,
          damping: 15,
        }
      }}
    >
      {/* AI Neural Network Background */}
      <motion.div
        className="absolute inset-0 rounded-2xl"
        style={{
          background: variant === 'primary' 
            ? 'radial-gradient(circle, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0.05) 50%, transparent 100%)'
            : 'radial-gradient(circle, rgba(255,255,255,0.05) 0%, rgba(255,255,255,0.02) 50%, transparent 100%)'
        }}
        animate={{
          scale: isHovered && !disabled ? [1, 1.2, 1.05] : 0.9,
          opacity: isHovered && !disabled ? [0.2, 0.6, 0.3] : 0,
          rotate: isHovered && !disabled ? [0, 90, 180] : 0,
        }}
        transition={{ 
          duration: isHovered ? 4 : 0.4, 
          ease: [0.16, 1, 0.3, 1],
          repeat: isHovered && !disabled ? Infinity : 0,
        }}
      />

      {/* Data Stream Overlay */}
      <motion.div
        className="absolute inset-0 rounded-2xl"
        style={{
          background: 'linear-gradient(110deg, transparent 30%, rgba(255,255,255,0.3) 50%, transparent 70%)',
          backgroundSize: '200% 100%',
        }}
        animate={{
          backgroundPosition: isHovered && !disabled ? ['0% 50%', '200% 50%'] : '0% 50%',
        }}
        transition={{
          duration: 2.5,
          ease: [0.25, 0.46, 0.45, 0.94],
          repeat: isHovered && !disabled ? Infinity : 0,
        }}
      />

      {/* AI Pulse Effects */}
      {ripples.map((ripple) => (
        <motion.div
          key={ripple.id}
          className="absolute rounded-full"
          style={{
            left: ripple.x - 12,
            top: ripple.y - 12,
            width: 24,
            height: 24,
            background: variant === 'primary' 
              ? 'radial-gradient(circle, rgba(0,0,0,0.2) 0%, transparent 70%)'
              : 'radial-gradient(circle, rgba(255,255,255,0.3) 0%, transparent 70%)'
          }}
          initial={{ scale: 0, opacity: 1 }}
          animate={{ 
            scale: [0, 2.5, 4], 
            opacity: [1, 0.6, 0] 
          }}
          transition={{ 
            duration: 0.8, 
            ease: [0.25, 0.46, 0.45, 0.94],
            times: [0, 0.4, 1]
          }}
        />
      ))}

      {/* Button Content */}
      <motion.div 
        className="relative z-10 flex items-center justify-center gap-2"
        animate={{
          filter: isPressed && !disabled ? "brightness(0.9)" : "brightness(1)"
        }}
        transition={{ duration: 0.1 }}
      >
        <span className="relative">
          {children}
          
          {/* Matrix-style text shadow effect */}
          <motion.span
            className="absolute inset-0 text-transparent"
            style={{
              background: 'linear-gradient(45deg, transparent, rgba(255,255,255,0.1), transparent)',
              backgroundClip: 'text',
              WebkitBackgroundClip: 'text',
            }}
            animate={{
              backgroundPosition: isHovered && !disabled ? ['0% 0%', '100% 100%'] : '0% 0%'
            }}
            transition={{
              duration: 1.5,
              ease: "linear",
              repeat: isHovered && !disabled ? Infinity : 0
            }}
          >
            {children}
          </motion.span>
        </span>
        
        {icon && (
          <motion.div
            variants={iconVariants}
            animate={isHovered && !disabled ? "hover" : "rest"}
            className="relative"
          >
            {getSystemIcon()}
            
            {/* Icon glow effect */}
            <motion.div
              className="absolute inset-0 opacity-0"
              animate={{
                opacity: isHovered && !disabled ? [0, 0.6, 0] : 0,
                scale: isHovered && !disabled ? [1, 1.3, 1] : 1
              }}
              transition={{
                duration: 2,
                repeat: isHovered && !disabled ? Infinity : 0,
                ease: [0.25, 0.46, 0.45, 0.94]
              }}
            >
              {getSystemIcon()}
            </motion.div>
          </motion.div>
        )}
      </motion.div>

      {/* Neural Activity Lines */}
      {isHovered && !disabled && (
        <>
          <motion.div
            className="absolute top-0 left-1/4 w-px h-full bg-white/20"
            initial={{ scaleY: 0, opacity: 0 }}
            animate={{ 
              scaleY: [0, 1, 0],
              opacity: [0, 0.6, 0]
            }}
            transition={{
              duration: 1.5,
              repeat: Infinity,
              delay: 0.2,
              ease: [0.25, 0.46, 0.45, 0.94]
            }}
          />
          <motion.div
            className="absolute top-0 right-1/3 w-px h-full bg-white/15"
            initial={{ scaleY: 0, opacity: 0 }}
            animate={{ 
              scaleY: [0, 1, 0],
              opacity: [0, 0.4, 0]
            }}
            transition={{
              duration: 1.8,
              repeat: Infinity,
              delay: 0.6,
              ease: [0.25, 0.46, 0.45, 0.94]
            }}
          />
        </>
      )}

      {/* System Status Indicator */}
      {variant === 'system' && (
        <motion.div
          className="absolute top-2 right-2 w-2 h-2 bg-white/60 rounded-full"
          animate={{
            opacity: [0.4, 1, 0.4],
            scale: [1, 1.2, 1]
          }}
          transition={{
            duration: 2,
            repeat: Infinity,
            ease: [0.37, 0, 0.63, 1]
          }}
        />
      )}
    </motion.button>
  )
} 