'use client'

import { motion } from 'framer-motion'
import { useInView } from 'react-intersection-observer'
import { Activity, Database, Network, Cpu, Terminal, Users } from 'lucide-react'

const systemMetrics = [
  {
    metric: "Neural pathways mapping campus social networks in real-time. Predictive analysis identifies community formation patterns.",
    system: "NETWORK_ANALYSIS",
    subsystem: "Social Graph Intelligence",
    status: "ACTIVE"
  },
  {
    metric: "Event prediction algorithms processing 10k+ data points. Behavioral patterns optimize community engagement flows.",
    system: "PREDICTIVE_ENGINE", 
    subsystem: "Event Intelligence",
    status: "LEARNING"
  },
  {
    metric: "Adaptive user interface responds to individual interaction patterns. Machine learning personalizes campus discovery.",
    system: "ADAPTIVE_UI",
    subsystem: "Interface Intelligence", 
    status: "EVOLVING"
  }
]

const dataStreams = [
  { metric: "500k+", label: "Neural connections mapped", icon: Network },
  { metric: "2.3M", label: "Data points processed", icon: Database },
  { metric: "99.7%", label: "System uptime achieved", icon: Activity }
]

export default function SocialProofSection() {
  const [ref, inView] = useInView({
    triggerOnce: true,
    threshold: 0.1
  })

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.3,
        delayChildren: 0.2
      }
    }
  }

  const itemVariants = {
    hidden: { 
      opacity: 0, 
      y: 60,
      scale: 0.9
    },
    visible: { 
      opacity: 1, 
      y: 0,
      scale: 1,
      transition: {
        type: "spring",
        stiffness: 80,
        damping: 15,
        duration: 1
      }
    }
  }

  const systemCardVariants = {
    hidden: { 
      opacity: 0, 
      rotateX: 45,
      x: -40
    },
    visible: { 
      opacity: 1, 
      rotateX: 0,
      x: 0,
      transition: {
        type: "spring",
        stiffness: 100,
        damping: 20,
        duration: 1.2
      }
    }
  }

  const dataFlowVariants = {
    animate: {
      y: [-3, 3, -3],
      rotate: [-1, 1, -1],
      transition: {
        duration: 8,
        repeat: Infinity,
        ease: "easeInOut"
      }
    }
  }

  return (
    <section ref={ref} className="py-32 px-6 relative overflow-hidden bg-black">
      {/* AI Neural Grid Background */}
      <div className="absolute inset-0 opacity-5">
        <div className="absolute inset-0 neural-grid" />
      </div>

      {/* Data Flow Lines */}
      {Array.from({ length: 8 }).map((_, i) => (
        <motion.div
          key={i}
          className="absolute h-px bg-gradient-to-r from-transparent via-white/10 to-transparent"
          style={{
            width: '300px',
            left: `${10 + i * 12}%`,
            top: `${20 + i * 8}%`,
            transform: `rotate(${i * 20}deg)`
          }}
          animate={{
            opacity: [0.1, 0.4, 0.1],
            scaleX: [0.3, 1, 0.3]
          }}
          transition={{
            duration: 6,
            repeat: Infinity,
            delay: i * 1.2,
            ease: [0.25, 0.46, 0.45, 0.94]
          }}
        />
      ))}

      <motion.div
        className="container mx-auto max-w-7xl"
        variants={containerVariants}
        initial="hidden"
        animate={inView ? "visible" : "hidden"}
      >
        {/* System Status Header */}
        <motion.div
          className="text-center mb-20"
          variants={itemVariants}
        >
          <motion.div
            className="inline-flex items-center gap-4 px-8 py-4 rounded-2xl glass-morphism-ai border border-white/20 mb-8"
            variants={dataFlowVariants}
            animate="animate"
          >
            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 8, repeat: Infinity, ease: "linear" }}
            >
              <Activity className="text-white/80" size={20} />
            </motion.div>
            <div className="h-6 w-px bg-white/30" />
            <span className="terminal-text text-white/80">SYSTEM.STATUS: OPERATIONAL</span>
            <motion.div
              animate={{
                scale: [1, 1.3, 1],
                opacity: [0.6, 1, 0.6]
              }}
              transition={{
                duration: 2,
                repeat: Infinity
              }}
              className="w-3 h-3 bg-white rounded-full"
            />
          </motion.div>

          <h2 className="text-5xl md:text-7xl font-mono font-bold text-white mb-8 leading-tight">
            AI Infrastructure
            <br />
            <motion.span 
              className="text-white/70"
              animate={{
                textShadow: [
                  "0 0 20px rgba(255, 255, 255, 0.1)",
                  "0 0 40px rgba(255, 255, 255, 0.3)",
                  "0 0 20px rgba(255, 255, 255, 0.1)"
                ]
              }}
              transition={{
                duration: 4,
                repeat: Infinity,
                ease: [0.37, 0, 0.63, 1]
              }}
            >
              learning.campus()
            </motion.span>
          </h2>

          <p className="text-xl md:text-2xl text-white/60 max-w-3xl mx-auto mono-text">
            Neural networks analyzing behavioral patterns. Machine learning optimizing social connections.
            <br className="hidden md:block" />
            Real-time intelligence powering campus community dynamics.
          </p>
        </motion.div>

        {/* Data Stream Metrics */}
        <motion.div
          className="grid md:grid-cols-3 gap-8 mb-20"
          variants={itemVariants}
        >
          {dataStreams.map((stream, index) => {
            const IconComponent = stream.icon
            return (
              <motion.div
                key={stream.label}
                className="text-center p-8 rounded-3xl glass-morphism-ai border border-white/10"
                variants={itemVariants}
                whileHover={{ 
                  scale: 1.02,
                  boxShadow: "0 0 40px rgba(255, 255, 255, 0.1)"
                }}
                transition={{ type: "spring", stiffness: 200, damping: 15 }}
              >
                <motion.div className="mb-6 flex justify-center">
                  <motion.div
                    animate={{ 
                      rotate: 360,
                      scale: [1, 1.1, 1]
                    }}
                    transition={{
                      rotate: { duration: 10, repeat: Infinity, ease: "linear" },
                      scale: { duration: 3, repeat: Infinity, ease: [0.37, 0, 0.63, 1] }
                    }}
                    className="w-16 h-16 border border-white/30 rounded-lg flex items-center justify-center"
                  >
                    <IconComponent className="text-white/70" size={24} />
                  </motion.div>
                </motion.div>
                
                <motion.div
                  className="text-4xl md:text-5xl font-mono font-bold text-white mb-4"
                  initial={{ scale: 0 }}
                  animate={inView ? { scale: 1 } : { scale: 0 }}
                  transition={{
                    delay: index * 0.3,
                    type: "spring",
                    stiffness: 150,
                    damping: 12
                  }}
                >
                  {stream.metric}
                </motion.div>
                <div className="text-white/60 font-mono text-sm tracking-wide">
                  {stream.label}
                </div>
              </motion.div>
            )
          })}
        </motion.div>

        {/* System Intelligence Cards */}
        <div className="grid md:grid-cols-3 gap-8 mb-20">
          {systemMetrics.map((system, index) => (
            <motion.div
              key={system.system}
              className="group"
              variants={systemCardVariants}
              custom={index}
            >
              <motion.div
                className="h-full p-8 rounded-3xl bg-gradient-to-br from-black to-gray-900 border border-white/10 relative overflow-hidden"
                whileHover={{ 
                  y: -3,
                  boxShadow: "0 20px 50px rgba(255, 255, 255, 0.05)"
                }}
                transition={{ type: "spring", stiffness: 200, damping: 15 }}
              >
                {/* System Icon */}
                <motion.div
                  className="absolute top-6 right-6 text-white/20"
                  animate={{
                    rotate: [0, 90, 180, 270, 360],
                  }}
                  transition={{
                    duration: 12,
                    repeat: Infinity,
                    ease: "linear"
                  }}
                >
                  <Terminal size={24} />
                </motion.div>

                {/* Status Indicator */}
                <motion.div 
                  className="flex items-center gap-3 mb-6"
                  animate={{
                    opacity: [0.7, 1, 0.7]
                  }}
                  transition={{
                    duration: 3,
                    repeat: Infinity,
                    delay: index * 0.5
                  }}
                >
                  <motion.div
                    className="w-3 h-3 bg-white rounded-full"
                    animate={{
                      scale: [1, 1.3, 1],
                      opacity: [0.6, 1, 0.6]
                    }}
                    transition={{
                      duration: 2,
                      repeat: Infinity,
                      delay: index * 0.3
                    }}
                  />
                  <span className="terminal-text text-white/80 text-xs tracking-wider">
                    {system.status}
                  </span>
                </motion.div>

                {/* System Name */}
                <motion.h3 
                  className="font-mono font-bold text-white text-lg mb-2 tracking-wide"
                  animate={{
                    textShadow: [
                      "0 0 10px rgba(255, 255, 255, 0.0)",
                      "0 0 20px rgba(255, 255, 255, 0.1)",
                      "0 0 10px rgba(255, 255, 255, 0.0)"
                    ]
                  }}
                  transition={{
                    duration: 4,
                    repeat: Infinity,
                    delay: index * 1.2
                  }}
                >
                  {system.system}
                </motion.h3>

                {/* Subsystem */}
                <div className="text-white/50 font-mono text-sm mb-4 tracking-wide">
                  {system.subsystem}
                </div>

                {/* System Description */}
                <p className="text-white/70 text-sm leading-relaxed font-mono">
                  {system.metric}
                </p>

                {/* Processing Lines */}
                <motion.div
                  className="absolute bottom-0 left-0 w-full h-px bg-gradient-to-r from-transparent via-white/20 to-transparent"
                  animate={{
                    scaleX: [0, 1, 0],
                    opacity: [0.3, 0.8, 0.3]
                  }}
                  transition={{
                    duration: 3,
                    repeat: Infinity,
                    delay: index * 0.8,
                    ease: [0.25, 0.46, 0.45, 0.94]
                  }}
                />
              </motion.div>
            </motion.div>
          ))}
        </div>

        {/* System Architecture Visualization */}
        <motion.div
          className="text-center"
          variants={itemVariants}
        >
          <motion.div
            className="inline-flex items-center gap-8 p-8 rounded-3xl glass-morphism-ai border border-white/20"
            whileHover={{
              scale: 1.02,
              boxShadow: "0 0 60px rgba(255, 255, 255, 0.1)"
            }}
            transition={{ type: "spring", stiffness: 200, damping: 20 }}
          >
            <motion.div
              className="flex items-center gap-3"
              animate={{
                opacity: [0.6, 1, 0.6]
              }}
              transition={{
                duration: 4,
                repeat: Infinity
              }}
            >
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ duration: 8, repeat: Infinity, ease: "linear" }}
                className="w-8 h-8 border border-white/40 rounded-lg flex items-center justify-center"
              >
                <Cpu className="text-white/70" size={20} />
              </motion.div>
              <span className="terminal-text text-white/80 text-sm">NEURAL.CORE</span>
            </motion.div>

            <motion.div
              className="h-px w-16 bg-gradient-to-r from-white/20 via-white/60 to-white/20"
              animate={{
                scaleX: [0.5, 1, 0.5],
                opacity: [0.3, 0.8, 0.3]
              }}
              transition={{
                duration: 2,
                repeat: Infinity,
                ease: [0.25, 0.46, 0.45, 0.94]
              }}
            />

            <motion.div
              className="flex items-center gap-3"
              animate={{
                opacity: [0.6, 1, 0.6]
              }}
              transition={{
                duration: 4,
                repeat: Infinity,
                delay: 1
              }}
            >
              <motion.div
                animate={{ rotate: -360 }}
                transition={{ duration: 6, repeat: Infinity, ease: "linear" }}
                className="w-8 h-8 border border-white/40 rounded-lg flex items-center justify-center"
              >
                <Users className="text-white/70" size={20} />
              </motion.div>
              <span className="terminal-text text-white/80 text-sm">COMMUNITY.ENGINE</span>
            </motion.div>

            <motion.div
              className="h-px w-16 bg-gradient-to-r from-white/20 via-white/60 to-white/20"
              animate={{
                scaleX: [0.5, 1, 0.5],
                opacity: [0.3, 0.8, 0.3]
              }}
              transition={{
                duration: 2,
                repeat: Infinity,
                delay: 1,
                ease: [0.25, 0.46, 0.45, 0.94]
              }}
            />

            <motion.div
              className="flex items-center gap-3"
              animate={{
                opacity: [0.6, 1, 0.6]
              }}
              transition={{
                duration: 4,
                repeat: Infinity,
                delay: 2
              }}
            >
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ duration: 10, repeat: Infinity, ease: "linear" }}
                className="w-8 h-8 border border-white/40 rounded-lg flex items-center justify-center"
              >
                <Database className="text-white/70" size={20} />
              </motion.div>
              <span className="terminal-text text-white/80 text-sm">DATA.INTELLIGENCE</span>
            </motion.div>
          </motion.div>
        </motion.div>
      </motion.div>
    </section>
  )
} 