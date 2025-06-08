'use client'

import { useState } from 'react'
import { SchoolSelector } from '@/components/ui/school-selector'
import { Button } from '@hive/ui-core'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

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

export default function ComponentsPage() {
  const [selectedSchool, setSelectedSchool] = useState<School | null>(null)

  const handleSchoolSelect = (school: School) => {
    setSelectedSchool(school)
  }

  const resetSelection = () => {
    setSelectedSchool(null)
  }

  return (
    <div className="min-h-screen bg-surface-0 bg-noise relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-dots-pattern opacity-20" />
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-gradient-radial from-[#FFD700]/3 to-transparent rounded-full blur-3xl" />
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-gradient-radial from-[#FFD700]/2 to-transparent rounded-full blur-3xl" />
      
      <div className="relative z-10 p-8">
        <div className="max-w-6xl mx-auto space-y-12">
        
        {/* Header */}
        <div className="text-center space-y-4">
          <h1 className="text-hero text-high">Advanced Components</h1>
          <p className="text-body-lg text-low max-w-2xl mx-auto">
            Interactive components with micro-animations, smart behaviors, and premium UX patterns.
          </p>
        </div>

        {/* School Selector Demo */}
        <section className="space-y-8">
          <div className="text-center space-y-4">
            <h2 className="text-display text-high">School Selector Component</h2>
            <p className="text-body text-low max-w-3xl mx-auto">
              Advanced authentication component featuring University at Buffalo focus, 
              real-time search, micro-animations, and smart interaction patterns.
            </p>
          </div>

          {/* Live Demo */}
          <Card variant="elevated" className="p-8">
            <CardHeader className="text-center pb-8">
              <CardTitle className="text-2xl">🎓 Live Demo</CardTitle>
              <CardDescription>
                Try the interactive school selection with all advanced features
              </CardDescription>
            </CardHeader>
            <CardContent>
              <SchoolSelector 
                onSelect={handleSchoolSelect}
                selectedSchool={selectedSchool}
              />
              
              {/* Selection Status */}
              {selectedSchool && (
                <div className="mt-8 p-6 bg-surface-2 rounded-card border border-accent/20">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                      <span className="text-3xl">{selectedSchool.logo}</span>
                      <div>
                        <h3 className="text-lg font-semibold text-high">
                          {selectedSchool.name} Selected!
                        </h3>
                        <p className="text-sm text-low">
                          Ready to join the HIVE community
                        </p>
                      </div>
                    </div>
                    <Button variant="outline" onClick={resetSelection}>
                      Change School
                    </Button>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Features Breakdown */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  🎬 Micro-Animations
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="text-sm space-y-2">
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-accent rounded-full"></div>
                    <span className="text-low">Staggered card entrance</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-accent rounded-full"></div>
                    <span className="text-low">Hover scale & rotate effects</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-accent rounded-full"></div>
                    <span className="text-low">Search icon color transitions</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-accent rounded-full"></div>
                    <span className="text-low">Selection checkmark rotation</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-accent rounded-full"></div>
                    <span className="text-low">Featured star pulsing</span>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  🧠 Smart Interactions
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="text-sm space-y-2">
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-success rounded-full"></div>
                    <span className="text-low">Auto-focus search input</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-success rounded-full"></div>
                    <span className="text-low">Real-time search filtering</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-success rounded-full"></div>
                    <span className="text-low">Dynamic results counter</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-success rounded-full"></div>
                    <span className="text-low">Status-based interactions</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-success rounded-full"></div>
                    <span className="text-low">Featured school priority</span>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  🎨 Design System
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="text-sm space-y-2">
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-info rounded-full"></div>
                    <span className="text-low">Modular card variants</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-info rounded-full"></div>
                    <span className="text-low">Consistent border radius</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-info rounded-full"></div>
                    <span className="text-low">Strategic gold accents</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-info rounded-full"></div>
                    <span className="text-low">Semantic color coding</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-info rounded-full"></div>
                    <span className="text-low">Typography hierarchy</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Technical Implementation */}
          <Card>
            <CardHeader>
              <CardTitle className="text-xl">🛠️ Technical Implementation</CardTitle>
              <CardDescription>
                Built with Framer Motion, TypeScript, and our modular design system
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                <div>
                  <h4 className="text-lg font-semibold text-high mb-3">Animation Framework</h4>
                  <div className="bg-surface-2 rounded-card p-4 font-mono text-sm text-code">
                    <div>// Framer Motion micro-animations</div>
                    <div className="text-accent">motion.div</div>
                    <div>  whileHover=&#123;&#123; scale: 1.02 &#125;&#125;</div>
                    <div>  whileTap=&#123;&#123; scale: 0.98 &#125;&#125;</div>
                    <div>  initial=&#123;&#123; opacity: 0, y: 20 &#125;&#125;</div>
                    <div>  animate=&#123;&#123; opacity: 1, y: 0 &#125;&#125;</div>
                  </div>
                </div>
                
                <div>
                  <h4 className="text-lg font-semibold text-high mb-3">Smart State Management</h4>
                  <div className="bg-surface-2 rounded-card p-4 font-mono text-sm text-code">
                    <div>// Real-time search filtering</div>
                    <div className="text-accent">useEffect</div>
                    <div>  &#40;&#40;&#41; =&gt; &#123;</div>
                    <div>    const filtered = schools.filter&#40;school =&gt;</div>
                    <div>      school.name.includes&#40;searchQuery&#41;</div>
                    <div>    &#41;</div>
                    <div>  &#125;, &#91;searchQuery&#93;&#41;</div>
                  </div>
                </div>
              </div>

              <div>
                <h4 className="text-lg font-semibold text-high mb-3">Key Features</h4>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                  <div className="bg-surface-1 rounded-card p-4 text-center">
                    <div className="text-2xl mb-2">⚡</div>
                    <div className="text-sm font-medium text-high">Auto-Focus</div>
                    <div className="text-xs text-low">Search input</div>
                  </div>
                  <div className="bg-surface-1 rounded-card p-4 text-center">
                    <div className="text-2xl mb-2">🔍</div>
                    <div className="text-sm font-medium text-high">Live Search</div>
                    <div className="text-xs text-low">Real-time filtering</div>
                  </div>
                  <div className="bg-surface-1 rounded-card p-4 text-center">
                    <div className="text-2xl mb-2">✨</div>
                    <div className="text-sm font-medium text-high">UB Featured</div>
                    <div className="text-xs text-low">Priority placement</div>
                  </div>
                  <div className="bg-surface-1 rounded-card p-4 text-center">
                    <div className="text-2xl mb-2">🎯</div>
                    <div className="text-sm font-medium text-high">Status Logic</div>
                    <div className="text-xs text-low">Smart interactions</div>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </section>

        </div>
      </div>
    </div>
  )
} 