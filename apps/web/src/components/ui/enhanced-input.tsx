'use client'

import React, { useState, useRef, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { cn } from '@/lib/utils'

interface EnhancedInputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  error?: string
  label?: string
  icon?: React.ReactNode
  success?: boolean
}

export const EnhancedInput = React.forwardRef<HTMLInputElement, EnhancedInputProps>(
  ({ className, type, error, label, icon, success, ...props }, ref) => {
    const [isFocused, setIsFocused] = useState(false)
    const [hasValue, setHasValue] = useState(false)
    const [isTyping, setIsTyping] = useState(false)
    const inputRef = useRef<HTMLInputElement>(null)
    const typingTimeoutRef = useRef<NodeJS.Timeout>()

    useEffect(() => {
      const input = inputRef.current
      if (input) {
        setHasValue(input.value.length > 0)
      }
    }, [props.value])

    const handleFocus = (e: React.FocusEvent<HTMLInputElement>) => {
      setIsFocused(true)
      props.onFocus?.(e)
    }

    const handleBlur = (e: React.FocusEvent<HTMLInputElement>) => {
      setIsFocused(false)
      setIsTyping(false)
      props.onBlur?.(e)
    }

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
      setHasValue(e.target.value.length > 0)
      setIsTyping(true)
      
      // Clear typing state after user stops typing
      if (typingTimeoutRef.current) {
        clearTimeout(typingTimeoutRef.current)
      }
      typingTimeoutRef.current = setTimeout(() => {
        setIsTyping(false)
      }, 1000)
      
      props.onChange?.(e)
    }

    return (
      <div className="relative">
        {/* Floating Label */}
        {label && (
          <motion.label
            className={cn(
              "absolute left-3 text-sm pointer-events-none transition-all duration-200",
              isFocused || hasValue
                ? "top-2 text-xs text-accent"
                : "top-1/2 -translate-y-1/2 text-low"
            )}
            animate={{
              scale: isFocused || hasValue ? 0.85 : 1,
              y: isFocused || hasValue ? -8 : 0,
            }}
            transition={{ duration: 0.2, ease: "easeOut" }}
          >
            {label}
          </motion.label>
        )}

        {/* Input Container */}
        <motion.div
          className="relative"
          whileTap={{ scale: 0.995 }}
          transition={{ duration: 0.1 }}
        >
          {/* Icon */}
          {icon && (
            <motion.div
              className="absolute left-3 top-1/2 -translate-y-1/2 text-low"
              animate={{
                color: isFocused ? '#FFD700' : '#B5B5B5',
                scale: isFocused ? 1.1 : 1,
              }}
              transition={{ duration: 0.2 }}
            >
              {icon}
            </motion.div>
          )}

          {/* Input Field */}
          <motion.input
            ref={(node) => {
              inputRef.current = node
              if (typeof ref === 'function') {
                ref(node)
              } else if (ref) {
                ref.current = node
              }
            }}
            type={type}
            className={cn(
              "flex h-12 w-full rounded-input border bg-surface-2 px-3 py-2 text-sm text-high",
              "placeholder:text-low focus:outline-none disabled:cursor-not-allowed disabled:opacity-50",
              "transition-all duration-200",
              icon && "pl-10",
              label && "pt-6 pb-2",
              error && "border-error focus:border-error",
              success && "border-success focus:border-success",
              !error && !success && "border-[var(--c-border)] focus:border-accent",
              className
            )}
            onFocus={handleFocus}
            onBlur={handleBlur}
            onChange={handleChange}
            {...props}
            animate={{
              boxShadow: isFocused
                ? error
                  ? "0 0 0 2px rgba(255, 59, 48, 0.2)"
                  : success
                  ? "0 0 0 2px rgba(140, 229, 99, 0.2)"
                  : "0 0 0 2px rgba(255, 215, 0, 0.2)"
                : "none",
            }}
            transition={{ duration: 0.2 }}
          />

          {/* Focus Ring */}
          <motion.div
            className="absolute inset-0 rounded-input pointer-events-none"
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{
              opacity: isFocused ? 1 : 0,
              scale: isFocused ? 1 : 0.95,
            }}
            transition={{ duration: 0.2, ease: "easeOut" }}
          >
            <div
              className={cn(
                "absolute inset-0 rounded-input border-2",
                error ? "border-error/50" : success ? "border-success/50" : "border-accent/50"
              )}
            />
          </motion.div>

          {/* Typing Indicator */}
          <AnimatePresence>
            {isTyping && (
              <motion.div
                className="absolute right-3 top-1/2 -translate-y-1/2"
                initial={{ opacity: 0, scale: 0 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0 }}
                transition={{ duration: 0.2 }}
              >
                <div className="flex space-x-1">
                  {[0, 1, 2].map((i) => (
                    <motion.div
                      key={i}
                      className="w-1 h-1 bg-accent rounded-full"
                      animate={{
                        scale: [1, 1.5, 1],
                        opacity: [0.5, 1, 0.5],
                      }}
                      transition={{
                        duration: 0.8,
                        repeat: Infinity,
                        delay: i * 0.1,
                      }}
                    />
                  ))}
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Success/Error Icons */}
          <AnimatePresence>
            {(success || error) && !isTyping && (
              <motion.div
                className="absolute right-3 top-1/2 -translate-y-1/2"
                initial={{ opacity: 0, scale: 0, rotate: -180 }}
                animate={{ opacity: 1, scale: 1, rotate: 0 }}
                exit={{ opacity: 0, scale: 0, rotate: 180 }}
                transition={{ duration: 0.3, ease: "backOut" }}
              >
                {success ? (
                  <div className="w-4 h-4 rounded-full bg-success flex items-center justify-center">
                    <svg className="w-2 h-2 text-white" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                    </svg>
                  </div>
                ) : (
                  <div className="w-4 h-4 rounded-full bg-error flex items-center justify-center">
                    <svg className="w-2 h-2 text-white" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
                    </svg>
                  </div>
                )}
              </motion.div>
            )}
          </AnimatePresence>
        </motion.div>

        {/* Error Message */}
        <AnimatePresence>
          {error && (
            <motion.div
              initial={{ opacity: 0, y: -10, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -10, scale: 0.95 }}
              transition={{ duration: 0.2, ease: "easeOut" }}
              className="mt-2"
            >
              <motion.p
                className="text-sm text-error flex items-center space-x-2"
                animate={{ x: [0, -2, 2, -2, 2, 0] }}
                transition={{ duration: 0.4, ease: "easeInOut" }}
              >
                <span>⚠️</span>
                <span>{error}</span>
              </motion.p>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Character Count (for longer inputs) */}
        {props.maxLength && hasValue && (
          <motion.div
            className="absolute bottom-2 right-3 text-xs text-low"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.5 }}
          >
            {(props.value as string)?.length || 0}/{props.maxLength}
          </motion.div>
        )}
      </div>
    )
  }
)

EnhancedInput.displayName = "EnhancedInput" 