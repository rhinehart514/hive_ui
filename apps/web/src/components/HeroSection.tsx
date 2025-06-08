'use client'

import { motion } from 'framer-motion'
import { useEffect, useState } from 'react'
import { Calendar, Users, MapPin, Zap, CheckCircle, ArrowDown } from 'lucide-react'
import Image from 'next/image'

const campusFeatures = ['coordination', 'community', 'connection', 'collaboration']

export default function HeroSection() {
  const [currentFeatureIndex, setCurrentFeatureIndex] = useState(0)

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentFeatureIndex((prev) => (prev + 1) % campusFeatures.length)
    }, 3000)

    return () => clearInterval(interval)
  }, [])

  const handleGetStarted = () => {
    console.log('🎯 Get Started - Campus Coordination')
    window.location.href = '/register'
  }

  const handleLearnMore = () => {
    console.log('📚 Learn More - Campus Features')
    document.getElementById('features')?.scrollIntoView({ 
      behavior: 'smooth',
      block: 'start' 
    })
  }

  return (
    <section
      className="relative min-h-screen flex items-center justify-center px-6 overflow-hidden"
      style={{ background: '#0D0D0D' }}
    >
      {/* Living Background */}
      <motion.div 
        className="absolute inset-0"
        animate={{
          background: [
            "radial-gradient(circle at 20% 30%, rgba(255,215,0,0.03) 0%, transparent 70%)",
            "radial-gradient(circle at 80% 70%, rgba(255,215,0,0.02) 0%, transparent 70%)",
            "radial-gradient(circle at 50% 10%, rgba(255,215,0,0.04) 0%, transparent 70%)",
            "radial-gradient(circle at 30% 90%, rgba(255,215,0,0.02) 0%, transparent 70%)",
            "radial-gradient(circle at 20% 30%, rgba(255,215,0,0.03) 0%, transparent 70%)"
          ],
        }}
        transition={{
          duration: 20,
          repeat: Infinity,
          ease: [0.4, 0, 0.2, 1]
        }}
      />

      {/* Subtle floating elements */}
      <motion.div
        className="absolute top-20 left-20 w-12 h-12 hive-surface"
        style={{ borderRadius: '20px' }}
        animate={{
          y: [-10, 10, -10],
          rotate: [0, 180, 360],
          scale: [1, 1.05, 1]
        }}
        transition={{
          duration: 12,
          repeat: Infinity,
          ease: [0.4, 0, 0.2, 1]
        }}
      />
      <motion.div
        className="absolute top-32 right-32 w-8 h-8 border border-white/10"
        style={{ borderRadius: '20px' }}
        animate={{
          y: [15, -15, 15],
          x: [10, -10, 10],
          opacity: [0.3, 0.6, 0.3]
        }}
        transition={{
          duration: 8,
          repeat: Infinity,
          ease: [0.4, 0, 0.2, 1]
        }}
      />
      <motion.div
        className="absolute bottom-40 left-32 w-16 h-16 border border-white/10 rounded-full"
        animate={{
          scale: [1, 1.1, 1],
          opacity: [0.2, 0.4, 0.2]
        }}
        transition={{
          duration: 10,
          repeat: Infinity,
          ease: [0.4, 0, 0.2, 1]
        }}
      />

      {/* Main Content */}
      <div className="relative z-10 text-center max-w-6xl mx-auto">
        {/* Campus Status Badge */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="inline-flex items-center gap-3 mb-8 px-6 py-3 hive-glass"
        >
          <div className="relative">
            <Image 
              src="/images/hivelogo.png" 
              alt="HIVE" 
              width={24} 
              height={24}
              className="campus-energy"
            />
          </div>
          <div className="h-4 w-px bg-white/20" />
          <motion.div
            animate={{
              scale: [1, 1.2, 1],
              opacity: [0.6, 1, 0.6]
            }}
            transition={{
              duration: 2,
              repeat: Infinity
            }}
            className="w-2 h-2 bg-green-400 rounded-full"
          />
          <span className="hive-body text-white/80 text-sm">
            University at Buffalo • Live
          </span>
        </motion.div>

        {/* Main Headline */}
        <motion.h1
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.4 }}
          className="hive-headline text-6xl md:text-8xl text-white mb-6 leading-tight"
        >
          Campus life
          <br />
          <motion.span 
            className="hive-text-secondary"
            animate={{
              opacity: [0.7, 1, 0.7]
            }}
            transition={{
              duration: 3,
              repeat: Infinity,
              ease: [0.4, 0, 0.2, 1]
            }}
          >
            that actually works
          </motion.span>
        </motion.h1>

        {/* Feature Rotator */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.6 }}
          className="mb-8 h-16 flex items-center justify-center"
        >
          <div className="relative text-2xl md:text-3xl">
            <span className="hive-body hive-text-secondary mr-3">Built for</span>
            <motion.span
              key={currentFeatureIndex}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.5 }}
              className="inline-block hive-subhead hive-accent font-medium"
            >
              {campusFeatures[currentFeatureIndex]}
            </motion.span>
          </div>
        </motion.div>

        {/* Description */}
        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.8 }}
          className="hive-body hive-text-secondary mb-12 max-w-3xl mx-auto"
        >
          HIVE connects students through better coordination tools. Join Spaces, discover events, 
          and build the campus community you want to be part of.
        </motion.p>

        {/* Action Buttons */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 1.0 }}
          className="flex flex-col sm:flex-row gap-4 justify-center items-center mb-16"
        >
          <motion.button
            onClick={handleGetStarted}
            className="hive-button-primary px-8 py-3 text-white font-medium subtle-animation"
            whileHover={{ 
              scale: 1.02,
              y: -1
            }}
            whileTap={{ scale: 0.98 }}
          >
            <span className="flex items-center gap-2">
              <Zap size={18} />
              Get Started
            </span>
          </motion.button>

          <motion.button
            onClick={handleLearnMore}
            className="hive-button-secondary px-8 py-3 text-white font-medium subtle-animation"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            <span className="flex items-center gap-2">
              <ArrowDown size={18} />
              Learn More
            </span>
          </motion.button>
        </motion.div>

        {/* Campus Features */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 1.2 }}
          className="flex items-center justify-center gap-8 hive-text-tertiary hive-caption"
        >
          <motion.div 
            className="flex items-center gap-2"
            animate={{
              opacity: [0.5, 0.8, 0.5]
            }}
            transition={{
              duration: 3,
              repeat: Infinity,
              delay: 0
            }}
          >
            <Users size={16} />
            <span>Spaces</span>
          </motion.div>
          <div className="w-px h-4 bg-white/20" />
          <motion.div 
            className="flex items-center gap-2"
            animate={{
              opacity: [0.5, 0.8, 0.5]
            }}
            transition={{
              duration: 3,
              repeat: Infinity,
              delay: 1
            }}
          >
            <Calendar size={16} />
            <span>Events</span>
          </motion.div>
          <div className="w-px h-4 bg-white/20" />
          <motion.div 
            className="flex items-center gap-2"
            animate={{
              opacity: [0.5, 0.8, 0.5]
            }}
            transition={{
              duration: 3,
              repeat: Infinity,
              delay: 2
            }}
          >
            <MapPin size={16} />
            <span>Campus</span>
          </motion.div>
        </motion.div>

        {/* Launch Timeline */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 1.4 }}
          className="mt-16 p-6 hive-glass max-w-xl mx-auto"
        >
          <motion.div
            className="flex items-center justify-center gap-3 mb-3"
            animate={{
              opacity: [0.7, 1, 0.7]
            }}
            transition={{
              duration: 4,
              repeat: Infinity
            }}
          >
            <CheckCircle size={16} className="hive-accent" />
            <span className="hive-caption hive-text-secondary">
              vBETA Launch
            </span>
          </motion.div>
          <h3 className="hive-subhead text-white mb-2">
            Summer 2025
          </h3>
          <p className="hive-caption hive-text-tertiary">
            Building the future of campus coordination at UB
          </p>
        </motion.div>
      </div>

      {/* Scroll Indicator */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.6, delay: 1.6 }}
        className="absolute bottom-8 left-1/2 transform -translate-x-1/2"
      >
        <motion.div
          animate={{
            y: [0, 8, 0],
            opacity: [0.4, 0.8, 0.4]
          }}
          transition={{
            duration: 2,
            repeat: Infinity,
            ease: [0.4, 0, 0.2, 1]
          }}
        >
          <div className="w-6 h-10 border border-white/20 rounded-full flex justify-center">
            <motion.div
              className="w-1 h-3 bg-white/40 rounded-full mt-2"
              animate={{
                y: [0, 12, 0]
              }}
              transition={{
                duration: 2,
                repeat: Infinity,
                ease: [0.4, 0, 0.2, 1]
              }}
            />
          </div>
        </motion.div>
      </motion.div>
    </section>
  )
} 

