'use client'

import React, { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Input } from './input'
import { Button } from './button'
import { Card, CardContent, CardHeader, CardTitle } from './card'

interface School {
  id: string
  name: string
  shortName: string
  logo: string
  status: 'available' | 'waitlist' | 'coming-soon'
  studentCount?: number
  description?: string
  featured?: boolean
}

const SCHOOLS: School[] = [
  {
    id: 'ub',
    name: 'University at Buffalo',
    shortName: 'UB',
    logo: '🦬',
    status: 'available',
    studentCount: 32000,
    description: 'SUNY flagship campus in Buffalo, NY',
    featured: true
  },
  {
    id: 'cornell',
    name: 'Cornell University',
    shortName: 'Cornell',
    logo: '🌽',
    status: 'waitlist',
    description: 'Ivy League university in Ithaca, NY'
  },
  {
    id: 'syracuse',
    name: 'Syracuse University',
    shortName: 'Syracuse',
    logo: '🍊',
    status: 'waitlist',
    description: 'Private research university in Syracuse, NY'
  },
  {
    id: 'rochester',
    name: 'University of Rochester',
    shortName: 'UR',
    logo: '🌹',
    status: 'coming-soon',
    description: 'Private research university in Rochester, NY'
  }
]

interface SchoolSelectorProps {
  onSelect: (school: School) => void
  selectedSchool?: School | null
}

export function SchoolSelector({ onSelect, selectedSchool }: SchoolSelectorProps) {
  const [searchQuery, setSearchQuery] = useState('')
  const [filteredSchools, setFilteredSchools] = useState(SCHOOLS)
  const [isSearchFocused, setIsSearchFocused] = useState(false)
  const searchInputRef = useRef<HTMLInputElement>(null)

  // Filter schools based on search query
  useEffect(() => {
    if (!searchQuery.trim()) {
      setFilteredSchools(SCHOOLS)
      return
    }

    const filtered = SCHOOLS.filter(school =>
      school.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      school.shortName.toLowerCase().includes(searchQuery.toLowerCase())
    )
    setFilteredSchools(filtered)
  }, [searchQuery])

  // Auto-focus search on mount
  useEffect(() => {
    const timer = setTimeout(() => {
      searchInputRef.current?.focus()
    }, 500)
    return () => clearTimeout(timer)
  }, [])

  const handleSchoolSelect = (school: School) => {
    if (school.status === 'available') {
      onSelect(school)
    }
  }

  return (
    <div className="w-full max-w-2xl mx-auto space-y-6 relative">
      {/* Background ambient lighting */}
      <div className="absolute -top-20 -left-20 w-96 h-96 bg-gradient-radial from-brand-gold-500/8 to-transparent rounded-full blur-3xl pointer-events-none" />
      <div className="absolute -bottom-20 -right-20 w-80 h-80 bg-gradient-radial from-brand-gold-500/5 to-transparent rounded-full blur-3xl pointer-events-none" />
      
      {/* Subtle grid pattern overlay */}
      <div className="absolute inset-0 bg-grid-pattern opacity-30 pointer-events-none" />
      
      {/* Content Container */}
      <div className="relative z-10 space-y-6">
        {/* Header */}
        <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="text-center space-y-4"
      >
        <h1 className="text-display text-high">Choose Your Campus</h1>
        <p className="text-body text-low">
          Select your university to join the HIVE community
        </p>
      </motion.div>

      {/* Search Input */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.1 }}
        className="relative"
      >
        <Input
          ref={searchInputRef}
          placeholder="Search for your university..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          onFocus={() => setIsSearchFocused(true)}
          onBlur={() => setIsSearchFocused(false)}
          icon={
            <motion.span
              animate={{ 
                scale: isSearchFocused ? 1.1 : 1,
                color: isSearchFocused ? 'var(--c-accent)' : 'var(--c-text-low)'
              }}
              transition={{ duration: 0.2 }}
            >
              🔍
            </motion.span>
          }
          className="text-lg"
        />
        
        {/* Search suggestions count */}
        <AnimatePresence>
          {searchQuery && (
            <motion.div
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              className="absolute right-3 top-1/2 transform -translate-y-1/2"
            >
              <span className="text-xs text-subtle bg-surface-2 px-2 py-1 rounded-button">
                {filteredSchools.length} found
              </span>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>

      {/* Featured School (UB) */}
      <AnimatePresence>
        {!searchQuery && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.5, delay: 0.2 }}
          >
            <div className="text-center mb-4">
              <span className="text-sm text-accent font-medium">✨ Featured Campus</span>
            </div>
            {SCHOOLS.filter(school => school.featured).map((school) => (
              <SchoolCard
                key={school.id}
                school={school}
                isSelected={selectedSchool?.id === school.id}
                onSelect={handleSchoolSelect}
                featured
              />
            ))}
          </motion.div>
        )}
      </AnimatePresence>

      {/* School Grid */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.5, delay: 0.3 }}
        className="space-y-3"
      >
        <AnimatePresence mode="popLayout">
          {filteredSchools
            .filter(school => !school.featured || searchQuery)
            .map((school, index) => (
              <motion.div
                key={school.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.95 }}
                transition={{ 
                  duration: 0.3, 
                  delay: searchQuery ? 0 : index * 0.1 
                }}
                layout
              >
                <SchoolCard
                  school={school}
                  isSelected={selectedSchool?.id === school.id}
                  onSelect={handleSchoolSelect}
                />
              </motion.div>
            ))}
        </AnimatePresence>

        {/* No results */}
        <AnimatePresence>
          {searchQuery && filteredSchools.length === 0 && (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              className="text-center py-12"
            >
              <div className="text-4xl mb-4">🔍</div>
              <h3 className="text-lg font-medium text-high mb-2">No schools found</h3>
              <p className="text-low mb-4">
                Can't find your university? We're expanding to new campuses soon.
              </p>
              <Button variant="outline" onClick={() => setSearchQuery('')}>
                View All Schools
              </Button>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
      </div>
    </div>
  )
}

interface SchoolCardProps {
  school: School
  isSelected: boolean
  onSelect: (school: School) => void
  featured?: boolean
}

function SchoolCard({ school, isSelected, onSelect, featured = false }: SchoolCardProps) {
  const [isHovered, setIsHovered] = useState(false)

  const getStatusConfig = (status: School['status']) => {
    switch (status) {
      case 'available':
        return {
          badge: '🟢 Available Now',
          badgeColor: 'text-success',
          actionText: 'Join HIVE',
          actionVariant: 'primary' as const,
          disabled: false
        }
      case 'waitlist':
        return {
          badge: '⏳ Join Waitlist',
          badgeColor: 'text-warning',
          actionText: 'Join Waitlist',
          actionVariant: 'outline' as const,
          disabled: false
        }
      case 'coming-soon':
        return {
          badge: '🚧 Coming Soon',
          badgeColor: 'text-subtle',
          actionText: 'Notify Me',
          actionVariant: 'ghost' as const,
          disabled: true
        }
    }
  }

  const statusConfig = getStatusConfig(school.status)

  return (
    <motion.div
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
      onHoverStart={() => setIsHovered(true)}
      onHoverEnd={() => setIsHovered(false)}
    >
      <Card
        variant={isSelected ? 'interactive' : 'default'}
        glow={isSelected}
        className={`cursor-pointer transition-all duration-200 ${
          featured ? 'border-accent/30 bg-gradient-card' : ''
        } ${
          isSelected ? 'border-accent shadow-glow-gold' : ''
        }`}
        onClick={() => onSelect(school)}
      >
        <CardHeader className="pb-4">
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-4">
              {/* School Logo */}
              <motion.div
                animate={{ 
                  scale: isHovered ? 1.1 : 1,
                  rotate: isHovered ? 5 : 0
                }}
                transition={{ duration: 0.2 }}
                className="text-4xl"
              >
                {school.logo}
              </motion.div>
              
              <div>
                <CardTitle className="text-xl text-high flex items-center gap-2">
                  {school.name}
                  {featured && (
                    <motion.span
                      animate={{ scale: [1, 1.2, 1] }}
                      transition={{ duration: 2, repeat: Infinity }}
                      className="text-accent"
                    >
                      ⭐
                    </motion.span>
                  )}
                </CardTitle>
                <p className="text-sm text-low mt-1">{school.description}</p>
                {school.studentCount && (
                  <p className="text-xs text-subtle mt-1">
                    {school.studentCount.toLocaleString()} students
                  </p>
                )}
              </div>
            </div>

            {/* Status Badge */}
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.2 }}
              className={`text-xs font-medium px-2 py-1 rounded-button bg-surface-2 ${statusConfig.badgeColor}`}
            >
              {statusConfig.badge}
            </motion.div>
          </div>
        </CardHeader>

        <CardContent className="pt-0">
          <div className="flex items-center justify-between">
            {/* Selection Indicator */}
            <AnimatePresence>
              {isSelected && (
                <motion.div
                  initial={{ opacity: 0, scale: 0 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0 }}
                  className="flex items-center gap-2 text-accent"
                >
                  <motion.span
                    animate={{ rotate: 360 }}
                    transition={{ duration: 0.5 }}
                  >
                    ✓
                  </motion.span>
                  <span className="text-sm font-medium">Selected</span>
                </motion.div>
              )}
            </AnimatePresence>

            {/* Action Button */}
            <motion.div
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              <Button
                variant={statusConfig.actionVariant}
                size="sm"
                disabled={statusConfig.disabled}
                glow={school.status === 'available' && isHovered}
                onClick={(e) => {
                  e.stopPropagation()
                  onSelect(school)
                }}
              >
                {statusConfig.actionText}
              </Button>
            </motion.div>
          </div>
        </CardContent>
      </Card>
    </motion.div>
  )
} 