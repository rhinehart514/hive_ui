'use client'

import { useRef, useEffect, useState } from 'react'
import { gsap } from 'gsap'
import { useGSAP } from '@gsap/react'

interface AnimatedHiveLogoProps {
  size?: number
  variant?: 'hero' | 'nav' | 'footer'
  animate?: boolean
}

export default function AnimatedHiveLogo({ 
  size = 120, 
  variant = 'hero',
  animate = true 
}: AnimatedHiveLogoProps) {
  const containerRef = useRef<HTMLDivElement>(null)
  const logoRef = useRef<HTMLDivElement>(null)
  const hexagonsRef = useRef<SVGGElement>(null)
  const textRef = useRef<HTMLDivElement>(null)
  const glowRef = useRef<HTMLDivElement>(null)
  const [isHovered, setIsHovered] = useState(false)

  const { contextSafe } = useGSAP(() => {
    if (!animate) return

    // Initial state
    gsap.set([hexagonsRef.current, textRef.current], {
      opacity: 0,
      scale: 0.8
    })

    // Entrance animation
    const tl = gsap.timeline({ delay: 0.5 })
    
    tl.to(hexagonsRef.current, {
      opacity: 1,
      scale: 1,
      duration: 1.2,
      ease: "back.out(1.7)",
      stagger: 0.1
    })
    .to(textRef.current, {
      opacity: 1,
      scale: 1,
      duration: 0.8,
      ease: "power3.out"
    }, "-=0.4")

    // Continuous floating animation
    gsap.to(logoRef.current, {
      y: -8,
      duration: 3,
      ease: "sine.inOut",
      yoyo: true,
      repeat: -1
    })

    // Hexagon rotation
    gsap.to(hexagonsRef.current?.children || [], {
      rotation: 360,
      duration: 20,
      ease: "none",
      repeat: -1,
      stagger: {
        each: 2,
        from: "random"
      }
    })

  }, { scope: containerRef })

  const handleHoverEnter = contextSafe(() => {
    setIsHovered(true)
    
    gsap.to(logoRef.current, {
      scale: 1.05,
      duration: 0.4,
      ease: "power2.out"
    })

    gsap.to(glowRef.current, {
      opacity: 1,
      scale: 1.2,
      duration: 0.4,
      ease: "power2.out"
    })

    // Speed up rotation on hover
    gsap.to(hexagonsRef.current?.children || [], {
      rotation: "+=180",
      duration: 0.8,
      ease: "power2.out",
      stagger: 0.05
    })
  })

  const handleHoverLeave = contextSafe(() => {
    setIsHovered(false)
    
    gsap.to(logoRef.current, {
      scale: 1,
      duration: 0.4,
      ease: "power2.out"
    })

    gsap.to(glowRef.current, {
      opacity: 0,
      scale: 1,
      duration: 0.4,
      ease: "power2.out"
    })
  })

  const logoSize = variant === 'nav' ? size * 0.6 : variant === 'footer' ? size * 0.8 : size
  const textSize = variant === 'nav' ? 'text-xl' : variant === 'footer' ? 'text-2xl' : 'text-4xl'

  return (
    <div 
      ref={containerRef}
      className="relative inline-flex items-center gap-4 cursor-pointer select-none"
      onMouseEnter={handleHoverEnter}
      onMouseLeave={handleHoverLeave}
      style={{ width: 'fit-content' }}
    >
      {/* Glow effect */}
      <div
        ref={glowRef}
        className="absolute inset-0 blur-xl bg-gradient-to-r from-hive-gold/30 to-white/20 rounded-full opacity-0"
        style={{ 
          filter: 'blur(20px)',
          transform: 'scale(1.5)',
          zIndex: -1
        }}
      />

      {/* Logo container */}
      <div 
        ref={logoRef}
        className="relative flex items-center justify-center"
        style={{ width: logoSize, height: logoSize }}
      >
        {/* Hexagonal background */}
        <div className="absolute inset-0 bg-gradient-to-br from-hive-black via-hive-surface to-hive-surface-light rounded-2xl border border-white/10">
          <div className="absolute inset-[1px] bg-gradient-to-br from-hive-surface/50 to-transparent rounded-2xl" />
        </div>

        {/* Animated hexagons */}
        <svg 
          width={logoSize * 0.8} 
          height={logoSize * 0.8} 
          viewBox="0 0 100 100" 
          className="absolute"
        >
          <defs>
            <linearGradient id="hexGradient" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#FFD700" stopOpacity="0.8" />
              <stop offset="50%" stopColor="#FFFFFF" stopOpacity="0.4" />
              <stop offset="100%" stopColor="#FFD700" stopOpacity="0.2" />
            </linearGradient>
            <filter id="glow">
              <feGaussianBlur stdDeviation="2" result="coloredBlur"/>
              <feMerge> 
                <feMergeNode in="coloredBlur"/>
                <feMergeNode in="SourceGraphic"/>
              </feMerge>
            </filter>
          </defs>
          
          <g ref={hexagonsRef}>
            {/* Main hexagon */}
            <polygon
              points="50,15 65,25 65,45 50,55 35,45 35,25"
              fill="none"
              stroke="url(#hexGradient)"
              strokeWidth="0.8"
              filter="url(#glow)"
              opacity="0.9"
            />
            
            {/* Inner hexagons */}
            <polygon
              points="50,25 58,30 58,40 50,45 42,40 42,30"
              fill="none"
              stroke="#FFD700"
              strokeWidth="0.6"
              opacity="0.6"
            />
            
            <polygon
              points="50,30 54,32.5 54,37.5 50,40 46,37.5 46,32.5"
              fill="#FFD700"
              opacity="0.3"
            />

            {/* Corner accent hexagons */}
            <polygon
              points="25,25 30,27.5 30,32.5 25,35 20,32.5 20,27.5"
              fill="none"
              stroke="#FFFFFF"
              strokeWidth="0.4"
              opacity="0.4"
            />
            
            <polygon
              points="75,25 80,27.5 80,32.5 75,35 70,32.5 70,27.5"
              fill="none"
              stroke="#FFFFFF"
              strokeWidth="0.4"
              opacity="0.4"
            />
            
            <polygon
              points="25,65 30,67.5 30,72.5 25,75 20,72.5 20,67.5"
              fill="none"
              stroke="#FFFFFF"
              strokeWidth="0.4"
              opacity="0.4"
            />
            
            <polygon
              points="75,65 80,67.5 80,72.5 75,75 70,72.5 70,67.5"
              fill="none"
              stroke="#FFFFFF"
              strokeWidth="0.4"
              opacity="0.4"
            />
          </g>
        </svg>

        {/* Center H */}
        <div className="relative z-10 text-hive-gold font-bold text-3xl font-sf tracking-wider">
          H
        </div>

        {/* Tech grid overlay */}
        <div className="absolute inset-0 opacity-20">
          <div className="w-full h-full bg-gradient-to-br from-transparent via-hive-gold/5 to-transparent" />
          <div 
            className="absolute inset-0 bg-repeat opacity-30"
            style={{
              backgroundImage: `
                linear-gradient(0deg, transparent 24%, rgba(255, 255, 255, 0.05) 25%, rgba(255, 255, 255, 0.05) 26%, transparent 27%, transparent 74%, rgba(255, 255, 255, 0.05) 75%, rgba(255, 255, 255, 0.05) 76%, transparent 77%, transparent),
                linear-gradient(90deg, transparent 24%, rgba(255, 255, 255, 0.05) 25%, rgba(255, 255, 255, 0.05) 26%, transparent 27%, transparent 74%, rgba(255, 255, 255, 0.05) 75%, rgba(255, 255, 255, 0.05) 76%, transparent 77%, transparent)
              `,
              backgroundSize: '20px 20px'
            }}
          />
        </div>
      </div>

      {/* HIVE text */}
      <div ref={textRef} className="flex flex-col">
        <div className={`${textSize} font-sf font-bold text-white tracking-wide leading-none`}>
          HIVE
        </div>
        {variant === 'hero' && (
          <div className="text-sm text-white/60 font-sf-text tracking-widest uppercase">
            Platform
          </div>
        )}
        {variant === 'footer' && (
          <div className="text-xs text-white/40 font-sf-text tracking-wide">
            Campus, now playable.
          </div>
        )}
      </div>

      {/* Particle effects */}
      {variant === 'hero' && (
        <div className="absolute inset-0 pointer-events-none">
          {[...Array(6)].map((_, i) => (
            <div
              key={i}
              className="absolute w-1 h-1 bg-hive-gold rounded-full opacity-60"
              style={{
                left: `${20 + i * 15}%`,
                top: `${30 + (i % 2) * 40}%`,
                animation: `float ${3 + i * 0.5}s ease-in-out infinite`,
                animationDelay: `${i * 0.2}s`
              }}
            />
          ))}
        </div>
      )}

      <style jsx>{`
        @keyframes float {
          0%, 100% { transform: translateY(0px) rotate(0deg); opacity: 0.6; }
          33% { transform: translateY(-4px) rotate(120deg); opacity: 1; }
          66% { transform: translateY(2px) rotate(240deg); opacity: 0.8; }
        }
      `}</style>
    </div>
  )
} 