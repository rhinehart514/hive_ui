'use client'

import React from 'react'
import { motion } from 'framer-motion'

interface AnimatedHiveLogoProps {
  className?: string
  variant?: 'full' | 'icon'
}

export function AnimatedHiveLogo({ 
  className = "w-16 h-16", 
  variant = 'icon' 
}: AnimatedHiveLogoProps) {
  return (
    <motion.div
      className={`relative ${className}`}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.4 }}
    >
      {variant === 'icon' ? (
        // Clean geometric icon version
        <div className="relative w-full h-full flex items-center justify-center">
          <svg
            viewBox="0 0 48 48"
            className="w-full h-full"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            {/* Main square grid structure */}
            <motion.g
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 0.3, delay: 0.1 }}
    >
              {/* Outer border */}
              <rect
                x="8"
                y="8"
                width="32"
                height="32"
                stroke="var(--text-primary)"
                strokeWidth="1.5"
                fill="none"
                rx="2"
              />
              
              {/* Inner grid - 3x3 */}
              <g stroke="var(--text-secondary)" strokeWidth="1">
                {/* Vertical lines */}
                <line x1="19.33" y1="8" x2="19.33" y2="40" />
                <line x1="28.67" y1="8" x2="28.67" y2="40" />

                {/* Horizontal lines */}
                <line x1="8" y1="19.33" x2="40" y2="19.33" />
                <line x1="8" y1="28.67" x2="40" y2="28.67" />
              </g>
              
              {/* Accent elements - strategic gold placement */}
              <motion.g
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ duration: 0.2, delay: 0.3 }}
      >
                {/* Bottom gold accent line */}
                <rect
                  x="8"
                  y="38"
                  width="32"
                  height="2"
                  fill="var(--accent)"
                />
                
                {/* Corner accent dots */}
                <circle cx="13" cy="13" r="1" fill="var(--text-primary)" />
                <circle cx="35" cy="13" r="1" fill="var(--text-primary)" />
                <circle cx="35" cy="35" r="1" fill="var(--accent)" />
              </motion.g>
            </motion.g>
          </svg>
        </div>
      ) : (
        // Full logo with text
        <motion.div
          className="flex items-center space-x-3"
          initial={{ opacity: 0, x: -10 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.4 }}
        >
          {/* Icon */}
          <div className="w-8 h-8 flex-shrink-0">
            <svg
              viewBox="0 0 48 48"
              className="w-full h-full"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <rect
                x="8"
                y="8"
                width="32"
                height="32"
                stroke="var(--text-primary)"
                strokeWidth="1.5"
              fill="none"
                rx="2"
              />
              <g stroke="var(--text-secondary)" strokeWidth="1">
                <line x1="19.33" y1="8" x2="19.33" y2="40" />
                <line x1="28.67" y1="8" x2="28.67" y2="40" />
                <line x1="8" y1="19.33" x2="40" y2="19.33" />
                <line x1="8" y1="28.67" x2="40" y2="28.67" />
              </g>
              <rect x="8" y="38" width="32" height="2" fill="var(--accent)" />
        </svg>
        </div>

          {/* Text */}
          <div className="font-display font-medium text-text-primary text-2xl tracking-tight">
          HIVE
          </div>
        </motion.div>
      )}
    </motion.div>
  )
} 