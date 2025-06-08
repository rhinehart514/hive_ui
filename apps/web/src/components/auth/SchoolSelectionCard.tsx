'use client';

import React from 'react';

interface SchoolSelectionCardProps {
  schoolName: string;
  location: string;
  status: string;
  isAvailable: boolean;
  onClick: () => void;
  schoolId?: string;
}

// School-specific color palettes mixed with HIVE aesthetic
const schoolThemes = {
  ub: {
    primary: '#005BBB', // UB Royal Blue
    secondary: '#FFFFFF', // UB White
    gradient: 'from-[#005BBB]/20 via-[#FFD700]/10 to-[#005BBB]/5',
    borderGlow: 'hover:shadow-[0_0_30px_rgba(0,91,187,0.3)]',
    accentGlow: 'shadow-[0_0_20px_rgba(0,91,187,0.2)]',
    pulseColor: 'rgba(0, 91, 187, 0.4)',
    shimmer: 'from-[#005BBB]/30 via-[#FFD700]/40 to-[#005BBB]/30'
  },
  default: {
    primary: '#FFD700',
    secondary: '#FFFFFF',
    gradient: 'from-[#FFD700]/15 via-[#FFD700]/5 to-transparent',
    borderGlow: 'hover:shadow-[0_0_30px_rgba(255,215,0,0.3)]',
    accentGlow: 'shadow-[0_0_20px_rgba(255,215,0,0.2)]',
    pulseColor: 'rgba(255, 215, 0, 0.4)',
    shimmer: 'from-[#FFD700]/30 via-[#FFD700]/50 to-[#FFD700]/30'
  }
};

export function SchoolSelectionCard({
  schoolName,
  location,
  status,
  isAvailable,
  onClick,
  schoolId = 'default'
}: SchoolSelectionCardProps) {
  const [isEmerging, setIsEmerging] = React.useState(false);
  const [showParticles, setShowParticles] = React.useState(false);
  const theme = schoolThemes[schoolId as keyof typeof schoolThemes] || schoolThemes.default;
  
  const handleClick = () => {
    if (!isAvailable) return;
    
    // Trigger emergence animation
    setIsEmerging(true);
    setShowParticles(true);
    
    // Clear particles after animation
    setTimeout(() => setShowParticles(false), 1200);
    
    // Delay the actual navigation to let animation play
    setTimeout(() => {
      onClick();
    }, 400);
  };
  
  return (
    <div 
      className={`
        group relative overflow-hidden rounded-[24px] p-8 mb-6 cursor-pointer
        transition-all duration-500 ease-out
        ${isEmerging ? 'emerge-animation' : ''}
        ${isAvailable 
          ? `hive-surface hover:scale-[1.02] ${theme.borderGlow}` 
          : 'hive-surface opacity-60'
        }
      `}
      onClick={handleClick}
      style={{
        background: isAvailable 
          ? `linear-gradient(135deg, rgba(30, 30, 30, 0.95) 0%, rgba(42, 42, 42, 0.95) 100%)`
          : undefined
      }}
    >
      {/* Animated school color gradient overlay */}
      {isAvailable && (
        <div 
          className={`absolute inset-0 bg-gradient-to-br ${theme.gradient} opacity-0 group-hover:opacity-100 transition-all duration-700 rounded-[24px]`}
        />
      )}
      
      {/* Subtle motion effect */}
      {isAvailable && (
        <div 
          className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-all duration-1000"
          style={{
            background: `radial-gradient(circle at var(--mouse-x, 50%) var(--mouse-y, 50%), ${theme.pulseColor} 0%, transparent 50%)`
          }}
        />
      )}
      
      {/* Emergence particles */}
      {showParticles && (
        <div className="emerge-particles">
          {Array.from({ length: 8 }).map((_, i) => (
            <div
              key={i}
              className="emerge-particle"
              style={{
                left: `${20 + Math.random() * 60}%`,
                top: `${20 + Math.random() * 60}%`,
                animationDelay: `${i * 0.1}s`,
                background: i % 2 === 0 ? theme.primary : '#FFD700'
              }}
            />
          ))}
        </div>
      )}
      
      {/* Content */}
      <div className="relative z-10">
        {/* School Info Section */}
        <div className="flex items-start justify-between mb-6">
          <div className="flex-1">
            {/* School Logo/Icon Area */}
            <div className="flex items-center mb-4">
              <div 
                className={`w-12 h-12 rounded-xl flex items-center justify-center mr-4 transition-all duration-300 ${isAvailable ? theme.accentGlow : ''}`}
                style={{
                  background: isAvailable 
                    ? `linear-gradient(135deg, ${theme.primary}20, ${theme.primary}10)`
                    : 'rgba(42, 42, 42, 0.5)',
                  border: `1px solid ${theme.primary}40`
                }}
              >
                {schoolId === 'ub' ? (
                  // UB specific icon
                  <div className="text-[#005BBB] font-black text-lg">UB</div>
                ) : (
                  // Generic university icon
                  <svg className="w-6 h-6 text-[#FFD700]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1" />
                  </svg>
                )}
              </div>
              
              <div className="flex-1">
                <h3 className="text-2xl font-bold text-white leading-tight tracking-tight mb-2">
                  {schoolName}
                </h3>
                <p className="text-white/70 text-base flex items-center font-light tracking-wide">
                  <svg className="w-4 h-4 mr-2 text-[#FFD700]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                  {location}
                </p>
              </div>
            </div>
          </div>
        </div>
        
        {/* Status and Action Section */}
        <div className="flex items-center justify-between">
          <div 
            className={`
              inline-flex items-center px-6 py-3 rounded-full text-sm font-semibold tracking-wide
              transition-all duration-300
              ${isAvailable 
                ? `text-white border-2 ${theme.accentGlow}` 
                : 'bg-gray-800/50 text-gray-400 border border-gray-600'
              }
            `}
            style={{
              background: isAvailable 
                ? `linear-gradient(135deg, ${theme.primary}30, ${theme.primary}15)`
                : undefined,
              borderColor: isAvailable ? `${theme.primary}60` : undefined
            }}
          >
            {status}
          </div>
          
          {isAvailable && (
            <div className="flex items-center text-[#FFD700] text-base font-semibold tracking-wide group-hover:translate-x-1 transition-transform duration-300">
              Get Started
              <svg className="w-5 h-5 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </div>
          )}
        </div>
      </div>
      
      {/* Shimmer effect on hover */}
      {isAvailable && (
        <div 
          className={`absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-700`}
          style={{
            background: `linear-gradient(45deg, transparent 30%, ${theme.pulseColor} 50%, transparent 70%)`,
            transform: 'translateX(-100%)',
            animation: 'shimmer 2s ease-in-out infinite'
          }}
        />
      )}
    </div>
  );
}

export function WaitlistCard({ onClick }: { onClick: () => void }) {
  return (
    <div 
      className="
        group relative overflow-hidden rounded-[24px] p-8 cursor-pointer
        hive-surface
        border-2 border-dashed border-white/20
        transition-all duration-500 ease-out
        hover:border-[#FFD700]/50 hover:shadow-[0_0_30px_rgba(255,215,0,0.15)]
      "
      onClick={onClick}
    >
      {/* Subtle animated background */}
      <div className="absolute inset-0 bg-gradient-to-br from-[#FFD700]/5 via-transparent to-[#FFD700]/5 opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
      
      <div className="relative z-10 text-center">
        <div className="w-16 h-16 mx-auto mb-6 rounded-full bg-gradient-to-br from-gray-800 to-gray-700 border border-white/10 flex items-center justify-center group-hover:shadow-[0_0_20px_rgba(255,215,0,0.2)] transition-all duration-300">
          <svg className="w-8 h-8 text-[#FFD700]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
          </svg>
        </div>
        
        <h3 className="text-xl font-bold text-white mb-3 tracking-tight">
          My school isn't listed
        </h3>
        
        <p className="text-white/70 text-base mb-6 font-light tracking-wide">
          Join the waitlist for your campus
        </p>
        
        <div className="inline-flex items-center text-[#FFD700] text-base font-semibold tracking-wide group-hover:translate-x-1 transition-transform duration-300">
          Join Waitlist
          <svg className="w-5 h-5 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
          </svg>
        </div>
      </div>
    </div>
  );
}

// Add shimmer animation to global styles
const shimmerStyles = `
  @keyframes shimmer {
    0% { transform: translateX(-100%); }
    100% { transform: translateX(100%); }
  }
`;

// Inject styles if not already present
if (typeof document !== 'undefined' && !document.getElementById('shimmer-styles')) {
  const style = document.createElement('style');
  style.id = 'shimmer-styles';
  style.textContent = shimmerStyles;
  document.head.appendChild(style);
} 