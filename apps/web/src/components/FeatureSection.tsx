'use client'

import { motion, AnimatePresence, useMotionValue, useTransform } from 'framer-motion'
import { Users, Calendar, Wrench, Activity, Binary, Network, ChevronRight, Circle, Square, Triangle } from 'lucide-react'
import { useState, useEffect, useRef } from 'react'
import Image from 'next/image'

const features = [
  {
    icon: Users,
    title: 'Spaces',
    subtitle: 'Neural Networks',
    description: 'Self-organizing communities that adapt and evolve. AI-powered matching connects like-minded individuals across academic and social dimensions.',
    aiPattern: 'neural-network',
    techElements: [
      { type: 'neural-node', x: 20, y: 30, size: 8, connections: [[80, 20], [60, 70]] },
      { type: 'neural-node', x: 80, y: 20, size: 12, connections: [[60, 70]] },
      { type: 'neural-node', x: 60, y: 70, size: 6, connections: [] },
      { type: 'data-flow', path: [[10, 50], [30, 30], [50, 40], [70, 25], [90, 35]] },
    ]
  },
  {
    icon: Calendar,
    title: 'Events',
    subtitle: 'Predictive Analysis',
    description: 'Real-time event intelligence with predictive algorithms. Machine learning identifies optimal timing and audience for maximum engagement.',
    aiPattern: 'data-stream',
    techElements: [
      { type: 'data-stream', x: 20, y: 20, direction: 'vertical' },
      { type: 'data-stream', x: 50, y: 10, direction: 'diagonal' },
      { type: 'data-stream', x: 80, y: 30, direction: 'vertical' },
      { type: 'pulse-grid', density: 4 },
    ]
  },
  {
    icon: Wrench,
    title: 'HiveLAB',
    subtitle: 'Generative Systems',
    description: 'Modular tool assembly through generative design principles. AI-assisted creation streamlines complex community infrastructure deployment.',
    aiPattern: 'modular-grid',
    techElements: [
      { type: 'module-grid', density: 5 },
      { type: 'assembly-point', x: 25, y: 35, size: 10 },
      { type: 'assembly-point', x: 75, y: 25, size: 8 },
      { type: 'assembly-point', x: 60, y: 75, size: 12 },
      { type: 'connector-beam', from: [25, 35], to: [75, 25] },
      { type: 'connector-beam', from: [75, 25], to: [60, 75] },
    ]
  }
]

function AIBackground({ feature, isActive }: { feature: typeof features[0], isActive: boolean }) {
  return (
    <div className="absolute inset-0 overflow-hidden">
      {/* Base pattern overlay */}
      <motion.div
        className="absolute inset-0 opacity-5"
        style={{
          background: `radial-gradient(circle at 50% 50%, white 0%, transparent 70%)`
        }}
        animate={{
          opacity: isActive ? [0.05, 0.15, 0.05] : 0.02,
          scale: isActive ? [1, 1.2, 1] : 1,
        }}
        transition={{
          duration: isActive ? 6 : 2,
          repeat: isActive ? Infinity : 0,
          ease: [0.25, 0.46, 0.45, 0.94]
        }}
      />

      {/* AI-specific tech elements */}
      {feature.techElements.map((element, index) => {
        if (element.type === 'neural-node') {
          return (
            <div key={index}>
              {/* Neural node */}
              <motion.div
                className="absolute rounded-full border border-white/40 bg-white/10 backdrop-blur-sm"
                style={{
                  left: `${element.x}%`,
                  top: `${element.y}%`,
                  width: `${element.size}px`,
                  height: `${element.size}px`,
                }}
                animate={{
                  scale: isActive ? [1, 1.5, 1] : [0.8, 1, 0.8],
                  opacity: isActive ? [0.8, 1, 0.8] : [0.4, 0.6, 0.4],
                  boxShadow: isActive 
                    ? ["0 0 10px rgba(255, 255, 255, 0.3)", "0 0 20px rgba(255, 255, 255, 0.5)", "0 0 10px rgba(255, 255, 255, 0.3)"]
                    : "0 0 5px rgba(255, 255, 255, 0.2)"
                }}
                transition={{
                  duration: 2 + index * 0.3,
                  repeat: Infinity,
                  ease: [0.25, 0.46, 0.45, 0.94],
                  delay: index * 0.5
                }}
              />

              {/* Neural connections */}
              {element.connections && element.connections.map((target, connIndex) => {
                const length = Math.sqrt(
                  Math.pow(target[0] - element.x, 2) + 
                  Math.pow(target[1] - element.y, 2)
                )
                const angle = Math.atan2(target[1] - element.y, target[0] - element.x) * 180 / Math.PI

                return (
                  <motion.div
                    key={`conn-${connIndex}`}
                    className="absolute h-px bg-gradient-to-r from-transparent via-white/40 to-transparent"
                    style={{
                      left: `${element.x}%`,
                      top: `${element.y}%`,
                      width: `${length * 0.8}%`,
                      transformOrigin: 'left center',
                      transform: `rotate(${angle}deg)`,
                    }}
                    animate={{
                      opacity: isActive ? [0.2, 0.8, 0.2] : [0.1, 0.3, 0.1],
                      scaleX: isActive ? [0, 1, 0] : [0.3, 0.6, 0.3],
                    }}
                    transition={{
                      duration: 4,
                      repeat: Infinity,
                      ease: [0.25, 0.46, 0.45, 0.94],
                      delay: connIndex * 0.8
                    }}
                  />
                )
              })}
            </div>
          )
        }

        if (element.type === 'data-stream') {
          const streamLength = element.direction === 'vertical' ? 40 : 50
          const streamAngle = element.direction === 'diagonal' ? 45 : 
                             element.direction === 'vertical' ? 90 : 0

          return (
            <motion.div
              key={index}
              className="absolute"
              style={{
                left: `${element.x}%`,
                top: `${element.y}%`,
                width: element.direction === 'vertical' ? '2px' : `${streamLength}%`,
                height: element.direction === 'vertical' ? `${streamLength}%` : '2px',
                transform: `rotate(${streamAngle}deg)`,
                transformOrigin: 'top left'
              }}
            >
              {Array.from({ length: 8 }).map((_, i) => (
                <motion.div
                  key={i}
                  className="absolute w-1 h-1 bg-white/60 rounded-full"
                  style={{
                    left: element.direction === 'vertical' ? '0' : `${i * 12}%`,
                    top: element.direction === 'vertical' ? `${i * 12}%` : '0',
                  }}
                  animate={{
                    opacity: isActive ? [0, 1, 0] : [0, 0.5, 0],
                    scale: isActive ? [0.5, 1.2, 0.5] : [0.3, 0.8, 0.3],
                  }}
                  transition={{
                    duration: 2,
                    repeat: Infinity,
                    ease: [0.25, 0.46, 0.45, 0.94],
                    delay: i * 0.2 + index * 0.5
                  }}
                />
              ))}
            </motion.div>
          )
        }

        if (element.type === 'pulse-grid') {
          return (
            <div key={index} className="absolute inset-0">
              {Array.from({ length: element.density }).map((_, i) => (
                <motion.div
                  key={i}
                  className="absolute w-full h-px bg-gradient-to-r from-transparent via-white/20 to-transparent"
                  style={{ top: `${(i + 1) * (100 / (element.density + 1))}%` }}
                  animate={{
                    opacity: isActive ? [0.1, 0.4, 0.1] : [0.05, 0.2, 0.05],
                    scaleX: isActive ? [0.5, 1, 0.5] : [0.3, 0.7, 0.3],
                  }}
                  transition={{
                    duration: 3,
                    repeat: Infinity,
                    ease: [0.25, 0.46, 0.45, 0.94],
                    delay: i * 0.3
                  }}
                />
              ))}
            </div>
          )
        }

        if (element.type === 'module-grid') {
          return (
            <div key={index} className="absolute inset-0">
              {Array.from({ length: element.density * element.density }).map((_, i) => {
                const row = Math.floor(i / element.density)
                const col = i % element.density
                const x = (col + 1) * (100 / (element.density + 1))
                const y = (row + 1) * (100 / (element.density + 1))

                return (
                  <motion.div
                    key={i}
                    className="absolute w-2 h-2 border border-white/30"
                    style={{
                      left: `${x}%`,
                      top: `${y}%`,
                      transform: 'translate(-50%, -50%)'
                    }}
                    animate={{
                      opacity: isActive ? [0.3, 0.8, 0.3] : [0.1, 0.4, 0.1],
                      scale: isActive ? [1, 1.2, 1] : [0.8, 1, 0.8],
                      rotate: isActive ? [0, 90, 0] : [0, 45, 0],
                    }}
                    transition={{
                      duration: 4,
                      repeat: Infinity,
                      ease: [0.25, 0.46, 0.45, 0.94],
                      delay: i * 0.1
                    }}
                  />
                )
              })}
            </div>
          )
        }

        if (element.type === 'assembly-point') {
          return (
            <motion.div
              key={index}
              className="absolute w-3 h-3 border-2 border-white/60 bg-white/20 backdrop-blur-sm"
              style={{
                left: `${element.x}%`,
                top: `${element.y}%`,
                transform: 'translate(-50%, -50%)'
              }}
              animate={{
                scale: isActive ? [1, 1.5, 1] : [0.8, 1, 0.8],
                opacity: isActive ? [0.6, 1, 0.6] : [0.3, 0.5, 0.3],
                rotate: isActive ? [0, 180, 360] : [0, 90, 180],
              }}
              transition={{
                duration: 6,
                repeat: Infinity,
                ease: [0.25, 0.46, 0.45, 0.94],
                delay: index * 0.4
              }}
            />
          )
        }

        if (element.type === 'connector-beam' && element.from && element.to) {
          const length = Math.sqrt(
            Math.pow(element.to[0] - element.from[0], 2) + 
            Math.pow(element.to[1] - element.from[1], 2)
          )
          const angle = Math.atan2(element.to[1] - element.from[1], element.to[0] - element.from[0]) * 180 / Math.PI

          return (
            <motion.div
              key={index}
              className="absolute h-0.5 bg-gradient-to-r from-white/20 via-white/60 to-white/20"
              style={{
                left: `${element.from[0]}%`,
                top: `${element.from[1]}%`,
                width: `${length * 0.8}%`,
                transformOrigin: 'left center',
                transform: `rotate(${angle}deg)`,
              }}
              animate={{
                opacity: isActive ? [0.3, 0.9, 0.3] : [0.1, 0.4, 0.1],
                scaleX: isActive ? [0, 1, 0] : [0.4, 0.8, 0.4],
              }}
              transition={{
                duration: 5,
                repeat: Infinity,
                ease: [0.25, 0.46, 0.45, 0.94],
                delay: index * 0.7
              }}
            />
          )
        }

        return null
      })}
    </div>
  )
}

function FeatureDisplay({ feature, isActive, index }: { 
  feature: typeof features[0], 
  isActive: boolean,
  index: number 
}) {
  const cardRef = useRef<HTMLDivElement>(null)
  const x = useMotionValue(0)
  const y = useMotionValue(0)
  const rotateX = useTransform(y, [-100, 100], [5, -5])
  const rotateY = useTransform(x, [-100, 100], [-5, 5])

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!cardRef.current) return
    const rect = cardRef.current.getBoundingClientRect()
    const centerX = rect.left + rect.width / 2
    const centerY = rect.top + rect.height / 2
    x.set((e.clientX - centerX) * 0.1)
    y.set((e.clientY - centerY) * 0.1)
  }

  const handleMouseLeave = () => {
    x.set(0)
    y.set(0)
  }

  return (
    <motion.div
      ref={cardRef}
      className={`relative h-full transition-all duration-1000 ${
        isActive ? 'z-20' : 'z-10'
      }`}
      style={{
        rotateX,
        rotateY,
        transformStyle: "preserve-3d",
      }}
      animate={{
        scale: isActive ? 1.05 : 0.95,
        opacity: isActive ? 1 : 0.6,
        y: isActive ? 0 : 20,
      }}
      transition={{
        duration: 0.8,
        ease: [0.19, 1, 0.22, 1]
      }}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      whileHover={{
        scale: isActive ? 1.08 : 1.02,
        transition: { duration: 0.3 }
      }}
    >
      <div className="relative h-full p-12 rounded-3xl bg-black/90 backdrop-blur-xl border border-white/10 overflow-hidden">
        {/* AI background patterns */}
        <AIBackground feature={feature} isActive={isActive} />

        {/* Minimal gradient overlay */}
        <motion.div
          className="absolute inset-0 bg-gradient-to-br from-white/5 to-transparent"
          animate={{
            opacity: isActive ? [0.05, 0.1, 0.05] : 0.02,
          }}
          transition={{
            duration: isActive ? 4 : 2,
            repeat: isActive ? Infinity : 0,
            ease: [0.25, 0.46, 0.45, 0.94]
          }}
        />

        {/* AI-styled icon container */}
        <motion.div
          className="relative w-24 h-24 rounded-2xl bg-white/5 border border-white/20 flex items-center justify-center mb-8 overflow-hidden"
          animate={{
            borderColor: isActive 
              ? ["rgba(255, 255, 255, 0.2)", "rgba(255, 255, 255, 0.6)", "rgba(255, 255, 255, 0.2)"]
              : "rgba(255, 255, 255, 0.1)",
            boxShadow: isActive
              ? ["0 0 20px rgba(255, 255, 255, 0.1)", "0 0 40px rgba(255, 255, 255, 0.3)", "0 0 20px rgba(255, 255, 255, 0.1)"]
              : "0 0 10px rgba(255, 255, 255, 0.05)"
          }}
          transition={{
            duration: isActive ? 4 : 1,
            repeat: isActive ? Infinity : 0,
            ease: [0.25, 0.46, 0.45, 0.94]
          }}
        >
          <motion.div
            className="absolute inset-0 rounded-2xl bg-gradient-to-br from-white/10 to-transparent"
            animate={{
              opacity: isActive ? [0.1, 0.3, 0.1] : 0.05,
            }}
            transition={{
              duration: isActive ? 3 : 1,
              repeat: isActive ? Infinity : 0,
            }}
          />
          
          <motion.div
            animate={{
              scale: isActive ? [1, 1.1, 1] : 1,
              rotate: isActive ? [0, 5, -5, 0] : 0,
            }}
            transition={{
              duration: 6,
              repeat: isActive ? Infinity : 0,
              ease: [0.25, 0.46, 0.45, 0.94]
            }}
          >
            <feature.icon className="text-white relative z-10" size={42} />
          </motion.div>
        </motion.div>

        {/* Enhanced monochromatic typography */}
        <div className="space-y-6 relative z-10">
          <motion.div
            animate={{
              y: isActive ? [0, -2, 0] : 0,
            }}
            transition={{
              duration: 4,
              repeat: isActive ? Infinity : 0,
              ease: [0.25, 0.46, 0.45, 0.94]
            }}
          >
            <motion.h3 
              className="text-4xl font-mono font-bold text-white mb-4 leading-tight tracking-tight"
              animate={{
                textShadow: isActive 
                  ? ["0 0 10px rgba(255, 255, 255, 0.2)", "0 0 20px rgba(255, 255, 255, 0.4)", "0 0 10px rgba(255, 255, 255, 0.2)"]
                  : "0 0 0px transparent"
              }}
              transition={{
                duration: 3,
                repeat: isActive ? Infinity : 0,
                ease: [0.19, 1, 0.22, 1]
              }}
            >
              {feature.title}
            </motion.h3>
            <motion.p 
              className="text-white/70 font-mono text-sm tracking-widest uppercase"
              animate={{
                opacity: isActive ? [0.7, 1, 0.7] : 0.5,
              }}
              transition={{
                duration: 3,
                repeat: isActive ? Infinity : 0,
                ease: [0.25, 0.46, 0.45, 0.94]
              }}
            >
              {feature.subtitle}
            </motion.p>
          </motion.div>
          
          <motion.p 
            className="text-white/80 leading-relaxed text-base font-light"
            animate={{
              opacity: isActive ? [0.8, 0.95, 0.8] : 0.6,
            }}
            transition={{
              duration: 5,
              repeat: isActive ? Infinity : 0,
              ease: [0.25, 0.46, 0.45, 0.94]
            }}
          >
            {feature.description}
          </motion.p>
        </div>

        {/* Minimal active border */}
        <motion.div 
          className="absolute inset-0 rounded-3xl border pointer-events-none"
          animate={{
            borderColor: isActive 
              ? ["rgba(255, 255, 255, 0.2)", "rgba(255, 255, 255, 0.6)", "rgba(255, 255, 255, 0.2)"]
              : "transparent",
            boxShadow: isActive
              ? ["0 0 20px rgba(255, 255, 255, 0.1)", "0 0 40px rgba(255, 255, 255, 0.2)", "0 0 20px rgba(255, 255, 255, 0.1)"]
              : "0 0 0px transparent"
          }}
          transition={{
            duration: isActive ? 4 : 0.5,
            repeat: isActive ? Infinity : 0,
            ease: [0.37, 0, 0.63, 1]
          }}
        />

        {/* AI status indicator */}
        <motion.div
          className="absolute top-6 right-6 flex items-center gap-2"
          animate={{
            opacity: isActive ? 1 : 0.4,
          }}
        >
          <motion.div
            className="w-2 h-2 bg-white border border-white/40"
            animate={{
              scale: isActive ? [1, 1.5, 1] : 1,
              opacity: isActive ? [1, 0.5, 1] : 0.3,
            }}
            transition={{
              duration: 2,
              repeat: isActive ? Infinity : 0,
            }}
          />
          <span className="text-white/60 text-xs font-mono tracking-wider uppercase">
            {isActive ? 'ACTIVE' : 'STANDBY'}
          </span>
        </motion.div>
      </div>
    </motion.div>
  )
}

export default function FeatureSection() {
  const [activeFeature, setActiveFeature] = useState(0)
  const [isPaused, setIsPaused] = useState(false)

  // Auto-rotation effect
  useEffect(() => {
    if (isPaused) return
    
    const interval = setInterval(() => {
      setActiveFeature((prev) => (prev + 1) % features.length)
    }, 6000) // Slower rotation for AI feel

    return () => clearInterval(interval)
  }, [isPaused])

  return (
    <section className="py-32 px-6 relative overflow-hidden bg-black">
      {/* AI-inspired background */}
      <motion.div className="absolute inset-0">
        {/* Minimal grid pattern */}
        <motion.div
          className="absolute inset-0 opacity-5"
          style={{
            backgroundImage: `
              linear-gradient(rgba(255, 255, 255, 0.1) 1px, transparent 1px),
              linear-gradient(90deg, rgba(255, 255, 255, 0.1) 1px, transparent 1px)
            `,
            backgroundSize: '60px 60px',
          }}
          animate={{
            backgroundPosition: ['0px 0px', '60px 60px', '0px 0px'],
          }}
          transition={{
            duration: 30,
            repeat: Infinity,
            ease: [0.25, 0.46, 0.45, 0.94]
          }}
        />

        {/* Floating geometric shapes */}
        {Array.from({ length: 4 }).map((_, i) => (
          <motion.div
            key={i}
            className="absolute w-20 h-20 border border-white/10"
            style={{
              left: `${15 + i * 20}%`,
              top: `${30 + (i % 2) * 30}%`,
              transform: 'rotate(45deg)'
            }}
            animate={{
              rotate: [45, 135, 45],
              opacity: [0.1, 0.3, 0.1],
              scale: [1, 1.2, 1],
            }}
            transition={{
              duration: 15 + i * 3,
              repeat: Infinity,
              ease: [0.25, 0.46, 0.45, 0.94],
              delay: i * 2
            }}
          />
        ))}
      </motion.div>
      
      <motion.div
        className="container mx-auto"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 1 }}
      >
        {/* AI-styled header */}
        <motion.div
          className="text-center mb-16"
          animate={{
            y: [0, -3, 0],
          }}
          transition={{
            duration: 8,
            repeat: Infinity,
            ease: [0.25, 0.46, 0.45, 0.94]
          }}
        >
          {/* HIVE Logo Integration */}
          <motion.div
            className="inline-flex items-center gap-4 mb-8 px-8 py-4 rounded-2xl bg-white/5 border border-white/20 backdrop-blur-xl"
            animate={{
              borderColor: [
                "rgba(255, 255, 255, 0.2)",
                "rgba(255, 255, 255, 0.4)",
                "rgba(255, 255, 255, 0.2)"
              ]
            }}
            transition={{
              duration: 6,
              repeat: Infinity,
              ease: [0.25, 0.46, 0.45, 0.94]
            }}
          >
            <motion.div
              animate={{ 
                rotate: 360,
                scale: [1, 1.1, 1]
              }}
              transition={{ 
                rotate: { duration: 20, repeat: Infinity, ease: "linear" },
                scale: { duration: 4, repeat: Infinity }
              }}
            >
              <Image 
                src="/assets/images/hivelogo.png" 
                alt="HIVE Logo" 
                width={32} 
                height={32}
                className="filter brightness-0 invert"
              />
            </motion.div>
            <div className="h-6 w-px bg-white/30" />
            <span className="text-white/80 font-mono text-sm tracking-widest uppercase">
              Three Core Systems
            </span>
            <motion.div
              animate={{ scale: [1, 1.3, 1] }}
              transition={{ duration: 3, repeat: Infinity }}
            >
              <Activity className="text-white/60" size={20} />
            </motion.div>
          </motion.div>
          
          <motion.h2 
            className="text-6xl md:text-8xl font-mono font-bold text-white mb-8 leading-tight tracking-tighter"
            animate={{
              textShadow: [
                "0 0 20px rgba(255, 255, 255, 0.1)",
                "0 0 40px rgba(255, 255, 255, 0.2)",
                "0 0 20px rgba(255, 255, 255, 0.1)"
              ]
            }}
            transition={{
              duration: 5,
              repeat: Infinity,
              ease: [0.37, 0, 0.63, 1]
            }}
          >
            AI-Native
            <br />
            <span className="text-white/70">Campus Infrastructure</span>
          </motion.h2>
          
          <motion.p 
            className="text-lg md:text-xl text-white/60 max-w-4xl mx-auto leading-relaxed font-light mb-8 font-mono"
            animate={{
              opacity: [0.6, 0.8, 0.6],
            }}
            transition={{
              duration: 6,
              repeat: Infinity,
              ease: [0.37, 0, 0.63, 1]
            }}
          >
            Machine learning systems that adapt, predict, and optimize campus community dynamics in real-time.
          </motion.p>

          {/* Minimalist controls */}
          <motion.div 
            className="flex items-center justify-center gap-6 mb-12"
            animate={{
              y: [0, -2, 0],
            }}
            transition={{
              duration: 4,
              repeat: Infinity,
            }}
          >
            <button
              onClick={() => setIsPaused(!isPaused)}
              className="flex items-center gap-2 px-4 py-2 rounded-lg bg-white/5 border border-white/20 text-white/70 hover:text-white hover:border-white/40 transition-all font-mono text-xs tracking-wider uppercase"
            >
              {isPaused ? '▶ Resume' : '⏸ Pause'} Cycle
            </button>
            <div className="flex gap-3">
              {features.map((_, index) => (
                <button
                  key={index}
                  onClick={() => setActiveFeature(index)}
                  className={`w-2 h-2 border border-white/40 transition-all duration-500 ${
                    index === activeFeature
                      ? 'bg-white scale-150'
                      : 'bg-transparent hover:bg-white/30'
                  }`}
                />
              ))}
            </div>
          </motion.div>
        </motion.div>

        {/* AI feature display */}
        <div className="grid lg:grid-cols-3 gap-8 mb-16">
          {features.map((feature, index) => (
            <FeatureDisplay
              key={feature.title}
              feature={feature}
              isActive={index === activeFeature}
              index={index}
            />
          ))}
        </div>

        {/* Minimal CTA */}
        <motion.div
          className="text-center"
          onMouseEnter={() => setIsPaused(true)}
          onMouseLeave={() => setIsPaused(false)}
        >
          <motion.div
            className="inline-block p-10 rounded-3xl bg-white/5 border border-white/20 backdrop-blur-xl relative overflow-hidden"
            whileHover={{ 
              scale: 1.02,
              borderColor: "rgba(255, 255, 255, 0.4)"
            }}
            transition={{ 
              duration: 0.3 
            }}
          >
            {/* Corner decoration */}
            <motion.div
              className="absolute top-4 right-4 text-white/30"
              animate={{ rotate: 360 }}
              transition={{ duration: 15, repeat: Infinity, ease: "linear" }}
            >
              <Binary size={20} />
            </motion.div>

            <motion.p 
              className="text-white/80 mb-4 text-xl font-light font-mono"
              animate={{
                opacity: [0.8, 1, 0.8]
              }}
              transition={{
                duration: 4,
                repeat: Infinity,
                ease: [0.37, 0, 0.63, 1]
              }}
            >
              Initialize.Campus.Protocol()
            </motion.p>
            <motion.p 
              className="text-2xl font-mono font-bold text-white tracking-tight mb-6"
              animate={{
                textShadow: [
                  "0 0 10px rgba(255, 255, 255, 0.2)",
                  "0 0 20px rgba(255, 255, 255, 0.4)",
                  "0 0 10px rgba(255, 255, 255, 0.2)"
                ]
              }}
              transition={{
                duration: 3,
                repeat: Infinity,
                ease: [0.25, 0.46, 0.45, 0.94]
              }}
            >
              vBETA.deploy() // summer.2025
            </motion.p>

            <motion.div
              className="flex items-center justify-center gap-2 text-white/50"
              animate={{
                x: [0, 3, 0],
              }}
              transition={{
                duration: 3,
                repeat: Infinity,
                ease: [0.25, 0.46, 0.45, 0.94]
              }}
            >
              <span className="text-xs font-mono tracking-wider uppercase">Execute Campus Revolution</span>
              <ChevronRight size={14} />
            </motion.div>
          </motion.div>
        </motion.div>
      </motion.div>
    </section>
  )
} 