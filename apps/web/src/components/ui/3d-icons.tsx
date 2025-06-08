'use client';

import React from 'react';

interface Icon3DProps {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
  glowIntensity?: 'none' | 'subtle' | 'medium' | 'strong';
}

const sizeClasses = {
  sm: 'w-6 h-6',
  md: 'w-8 h-8', 
  lg: 'w-12 h-12',
  xl: 'w-16 h-16'
};

const glowClasses = {
  none: '',
  subtle: 'drop-shadow-[0_0_8px_rgba(231,182,20,0.2)]',
  medium: 'drop-shadow-[0_0_16px_rgba(231,182,20,0.4)]',
  strong: 'drop-shadow-[0_0_24px_rgba(231,182,20,0.6)]'
};

// 3D Cube Icon
export function CubeIcon({ size = 'md', className = '', glowIntensity = 'none' }: Icon3DProps) {
  return (
    <div className={`${sizeClasses[size]} ${glowClasses[glowIntensity]} ${className}`}>
      <svg viewBox="0 0 64 64" className="w-full h-full">
        <defs>
          <linearGradient id="cubeTop" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#FFD700" />
            <stop offset="100%" stopColor="#E7B614" />
          </linearGradient>
          <linearGradient id="cubeLeft" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#CBA60D" />
            <stop offset="100%" stopColor="#B8950A" />
          </linearGradient>
          <linearGradient id="cubeRight" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#B8950A" />
            <stop offset="100%" stopColor="#A68408" />
          </linearGradient>
        </defs>
        {/* Top face */}
        <path d="M32 8 L52 18 L32 28 L12 18 Z" fill="url(#cubeTop)" />
        {/* Left face */}
        <path d="M12 18 L32 28 L32 48 L12 38 Z" fill="url(#cubeLeft)" />
        {/* Right face */}
        <path d="M32 28 L52 18 L52 38 L32 48 Z" fill="url(#cubeRight)" />
      </svg>
    </div>
  );
}

// 3D Sphere Icon
export function SphereIcon({ size = 'md', className = '', glowIntensity = 'none' }: Icon3DProps) {
  return (
    <div className={`${sizeClasses[size]} ${glowClasses[glowIntensity]} ${className}`}>
      <svg viewBox="0 0 64 64" className="w-full h-full">
        <defs>
          <radialGradient id="sphereGradient" cx="30%" cy="30%">
            <stop offset="0%" stopColor="#FFD700" />
            <stop offset="70%" stopColor="#E7B614" />
            <stop offset="100%" stopColor="#B8950A" />
          </radialGradient>
        </defs>
        <circle cx="32" cy="32" r="24" fill="url(#sphereGradient)" />
        <ellipse cx="28" cy="26" rx="8" ry="6" fill="rgba(255,255,255,0.3)" />
      </svg>
    </div>
  );
}

// 3D Diamond Icon
export function DiamondIcon({ size = 'md', className = '', glowIntensity = 'none' }: Icon3DProps) {
  return (
    <div className={`${sizeClasses[size]} ${glowClasses[glowIntensity]} ${className}`}>
      <svg viewBox="0 0 64 64" className="w-full h-full">
        <defs>
          <linearGradient id="diamondTop" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#FFD700" />
            <stop offset="100%" stopColor="#E7B614" />
          </linearGradient>
          <linearGradient id="diamondLeft" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#E7B614" />
            <stop offset="100%" stopColor="#CBA60D" />
          </linearGradient>
          <linearGradient id="diamondRight" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#CBA60D" />
            <stop offset="100%" stopColor="#B8950A" />
          </linearGradient>
        </defs>
        {/* Top facets */}
        <path d="M32 8 L48 24 L32 32 L16 24 Z" fill="url(#diamondTop)" />
        {/* Left facets */}
        <path d="M16 24 L32 32 L32 56 L16 40 Z" fill="url(#diamondLeft)" />
        {/* Right facets */}
        <path d="M32 32 L48 24 L48 40 L32 56 Z" fill="url(#diamondRight)" />
      </svg>
    </div>
  );
}

// 3D Cylinder Icon  
export function CylinderIcon({ size = 'md', className = '', glowIntensity = 'none' }: Icon3DProps) {
  return (
    <div className={`${sizeClasses[size]} ${glowClasses[glowIntensity]} ${className}`}>
      <svg viewBox="0 0 64 64" className="w-full h-full">
        <defs>
          <linearGradient id="cylinderSide" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor="#B8950A" />
            <stop offset="50%" stopColor="#E7B614" />
            <stop offset="100%" stopColor="#B8950A" />
          </linearGradient>
          <radialGradient id="cylinderTop" cx="50%" cy="50%">
            <stop offset="0%" stopColor="#FFD700" />
            <stop offset="100%" stopColor="#E7B614" />
          </radialGradient>
        </defs>
        {/* Side */}
        <rect x="16" y="16" width="32" height="32" fill="url(#cylinderSide)" />
        {/* Top ellipse */}
        <ellipse cx="32" cy="16" rx="16" ry="6" fill="url(#cylinderTop)" />
        {/* Bottom ellipse */}
        <ellipse cx="32" cy="48" rx="16" ry="6" fill="url(#cylinderSide)" />
      </svg>
    </div>
  );
}

// 3D Network Node Icon
export function NetworkIcon({ size = 'md', className = '', glowIntensity = 'none' }: Icon3DProps) {
  return (
    <div className={`${sizeClasses[size]} ${glowClasses[glowIntensity]} ${className}`}>
      <svg viewBox="0 0 64 64" className="w-full h-full">
        <defs>
          <radialGradient id="nodeGradient" cx="30%" cy="30%">
            <stop offset="0%" stopColor="#FFD700" />
            <stop offset="100%" stopColor="#CBA60D" />
          </radialGradient>
        </defs>
        {/* Connection lines with glow */}
        <line x1="32" y1="32" x2="12" y2="12" stroke="#E7B614" strokeWidth="2" opacity="0.8" />
        <line x1="32" y1="32" x2="52" y2="12" stroke="#E7B614" strokeWidth="2" opacity="0.8" />
        <line x1="32" y1="32" x2="12" y2="52" stroke="#E7B614" strokeWidth="2" opacity="0.8" />
        <line x1="32" y1="32" x2="52" y2="52" stroke="#E7B614" strokeWidth="2" opacity="0.8" />
        
        {/* Nodes */}
        <circle cx="12" cy="12" r="4" fill="url(#nodeGradient)" />
        <circle cx="52" cy="12" r="4" fill="url(#nodeGradient)" />
        <circle cx="12" cy="52" r="4" fill="url(#nodeGradient)" />
        <circle cx="52" cy="52" r="4" fill="url(#nodeGradient)" />
        
        {/* Center node */}
        <circle cx="32" cy="32" r="8" fill="url(#nodeGradient)" />
        <circle cx="28" cy="28" r="3" fill="rgba(255,255,255,0.4)" />
      </svg>
    </div>
  );
}

// 3D Stack Icon
export function StackIcon({ size = 'md', className = '', glowIntensity = 'none' }: Icon3DProps) {
  return (
    <div className={`${sizeClasses[size]} ${glowClasses[glowIntensity]} ${className}`}>
      <svg viewBox="0 0 64 64" className="w-full h-full">
        <defs>
          <linearGradient id="layer1" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#FFD700" />
            <stop offset="100%" stopColor="#E7B614" />
          </linearGradient>
          <linearGradient id="layer2" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#E7B614" />
            <stop offset="100%" stopColor="#CBA60D" />
          </linearGradient>
          <linearGradient id="layer3" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#CBA60D" />
            <stop offset="100%" stopColor="#B8950A" />
          </linearGradient>
        </defs>
        {/* Bottom layer */}
        <ellipse cx="32" cy="48" rx="20" ry="8" fill="url(#layer3)" />
        <rect x="12" y="40" width="40" height="8" fill="url(#layer3)" />
        <ellipse cx="32" cy="40" rx="20" ry="8" fill="url(#layer2)" />
        
        {/* Middle layer */}
        <ellipse cx="32" cy="36" rx="16" ry="6" fill="url(#layer2)" />
        <rect x="16" y="30" width="32" height="6" fill="url(#layer2)" />
        <ellipse cx="32" cy="30" rx="16" ry="6" fill="url(#layer1)" />
        
        {/* Top layer */}
        <ellipse cx="32" cy="26" rx="12" ry="4" fill="url(#layer1)" />
        <rect x="20" y="22" width="24" height="4" fill="url(#layer1)" />
        <ellipse cx="32" cy="22" rx="12" ry="4" fill="#FFD700" />
      </svg>
    </div>
  );
} 

import React from 'react';

interface Icon3DProps {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
  glowIntensity?: 'none' | 'subtle' | 'medium' | 'strong';
}

const sizeClasses = {
  sm: 'w-6 h-6',
  md: 'w-8 h-8', 
  lg: 'w-12 h-12',
  xl: 'w-16 h-16'
};

const glowClasses = {
  none: '',
  subtle: 'drop-shadow-[0_0_8px_rgba(231,182,20,0.2)]',
  medium: 'drop-shadow-[0_0_16px_rgba(231,182,20,0.4)]',
  strong: 'drop-shadow-[0_0_24px_rgba(231,182,20,0.6)]'
};

// 3D Cube Icon
export function CubeIcon({ size = 'md', className = '', glowIntensity = 'none' }: Icon3DProps) {
  return (
    <div className={`${sizeClasses[size]} ${glowClasses[glowIntensity]} ${className}`}>
      <svg viewBox="0 0 64 64" className="w-full h-full">
        <defs>
          <linearGradient id="cubeTop" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#FFD700" />
            <stop offset="100%" stopColor="#E7B614" />
          </linearGradient>
          <linearGradient id="cubeLeft" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#CBA60D" />
            <stop offset="100%" stopColor="#B8950A" />
          </linearGradient>
          <linearGradient id="cubeRight" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#B8950A" />
            <stop offset="100%" stopColor="#A68408" />
          </linearGradient>
        </defs>
        {/* Top face */}
        <path d="M32 8 L52 18 L32 28 L12 18 Z" fill="url(#cubeTop)" />
        {/* Left face */}
        <path d="M12 18 L32 28 L32 48 L12 38 Z" fill="url(#cubeLeft)" />
        {/* Right face */}
        <path d="M32 28 L52 18 L52 38 L32 48 Z" fill="url(#cubeRight)" />
      </svg>
    </div>
  );
}

// 3D Sphere Icon
export function SphereIcon({ size = 'md', className = '', glowIntensity = 'none' }: Icon3DProps) {
  return (
    <div className={`${sizeClasses[size]} ${glowClasses[glowIntensity]} ${className}`}>
      <svg viewBox="0 0 64 64" className="w-full h-full">
        <defs>
          <radialGradient id="sphereGradient" cx="30%" cy="30%">
            <stop offset="0%" stopColor="#FFD700" />
            <stop offset="70%" stopColor="#E7B614" />
            <stop offset="100%" stopColor="#B8950A" />
          </radialGradient>
        </defs>
        <circle cx="32" cy="32" r="24" fill="url(#sphereGradient)" />
        <ellipse cx="28" cy="26" rx="8" ry="6" fill="rgba(255,255,255,0.3)" />
      </svg>
    </div>
  );
}

// 3D Diamond Icon
export function DiamondIcon({ size = 'md', className = '', glowIntensity = 'none' }: Icon3DProps) {
  return (
    <div className={`${sizeClasses[size]} ${glowClasses[glowIntensity]} ${className}`}>
      <svg viewBox="0 0 64 64" className="w-full h-full">
        <defs>
          <linearGradient id="diamondTop" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#FFD700" />
            <stop offset="100%" stopColor="#E7B614" />
          </linearGradient>
          <linearGradient id="diamondLeft" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#E7B614" />
            <stop offset="100%" stopColor="#CBA60D" />
          </linearGradient>
          <linearGradient id="diamondRight" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#CBA60D" />
            <stop offset="100%" stopColor="#B8950A" />
          </linearGradient>
        </defs>
        {/* Top facets */}
        <path d="M32 8 L48 24 L32 32 L16 24 Z" fill="url(#diamondTop)" />
        {/* Left facets */}
        <path d="M16 24 L32 32 L32 56 L16 40 Z" fill="url(#diamondLeft)" />
        {/* Right facets */}
        <path d="M32 32 L48 24 L48 40 L32 56 Z" fill="url(#diamondRight)" />
      </svg>
    </div>
  );
}

// 3D Cylinder Icon  
export function CylinderIcon({ size = 'md', className = '', glowIntensity = 'none' }: Icon3DProps) {
  return (
    <div className={`${sizeClasses[size]} ${glowClasses[glowIntensity]} ${className}`}>
      <svg viewBox="0 0 64 64" className="w-full h-full">
        <defs>
          <linearGradient id="cylinderSide" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor="#B8950A" />
            <stop offset="50%" stopColor="#E7B614" />
            <stop offset="100%" stopColor="#B8950A" />
          </linearGradient>
          <radialGradient id="cylinderTop" cx="50%" cy="50%">
            <stop offset="0%" stopColor="#FFD700" />
            <stop offset="100%" stopColor="#E7B614" />
          </radialGradient>
        </defs>
        {/* Side */}
        <rect x="16" y="16" width="32" height="32" fill="url(#cylinderSide)" />
        {/* Top ellipse */}
        <ellipse cx="32" cy="16" rx="16" ry="6" fill="url(#cylinderTop)" />
        {/* Bottom ellipse */}
        <ellipse cx="32" cy="48" rx="16" ry="6" fill="url(#cylinderSide)" />
      </svg>
    </div>
  );
}

// 3D Network Node Icon
export function NetworkIcon({ size = 'md', className = '', glowIntensity = 'none' }: Icon3DProps) {
  return (
    <div className={`${sizeClasses[size]} ${glowClasses[glowIntensity]} ${className}`}>
      <svg viewBox="0 0 64 64" className="w-full h-full">
        <defs>
          <radialGradient id="nodeGradient" cx="30%" cy="30%">
            <stop offset="0%" stopColor="#FFD700" />
            <stop offset="100%" stopColor="#CBA60D" />
          </radialGradient>
        </defs>
        {/* Connection lines with glow */}
        <line x1="32" y1="32" x2="12" y2="12" stroke="#E7B614" strokeWidth="2" opacity="0.8" />
        <line x1="32" y1="32" x2="52" y2="12" stroke="#E7B614" strokeWidth="2" opacity="0.8" />
        <line x1="32" y1="32" x2="12" y2="52" stroke="#E7B614" strokeWidth="2" opacity="0.8" />
        <line x1="32" y1="32" x2="52" y2="52" stroke="#E7B614" strokeWidth="2" opacity="0.8" />
        
        {/* Nodes */}
        <circle cx="12" cy="12" r="4" fill="url(#nodeGradient)" />
        <circle cx="52" cy="12" r="4" fill="url(#nodeGradient)" />
        <circle cx="12" cy="52" r="4" fill="url(#nodeGradient)" />
        <circle cx="52" cy="52" r="4" fill="url(#nodeGradient)" />
        
        {/* Center node */}
        <circle cx="32" cy="32" r="8" fill="url(#nodeGradient)" />
        <circle cx="28" cy="28" r="3" fill="rgba(255,255,255,0.4)" />
      </svg>
    </div>
  );
}

// 3D Stack Icon
export function StackIcon({ size = 'md', className = '', glowIntensity = 'none' }: Icon3DProps) {
  return (
    <div className={`${sizeClasses[size]} ${glowClasses[glowIntensity]} ${className}`}>
      <svg viewBox="0 0 64 64" className="w-full h-full">
        <defs>
          <linearGradient id="layer1" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#FFD700" />
            <stop offset="100%" stopColor="#E7B614" />
          </linearGradient>
          <linearGradient id="layer2" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#E7B614" />
            <stop offset="100%" stopColor="#CBA60D" />
          </linearGradient>
          <linearGradient id="layer3" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#CBA60D" />
            <stop offset="100%" stopColor="#B8950A" />
          </linearGradient>
        </defs>
        {/* Bottom layer */}
        <ellipse cx="32" cy="48" rx="20" ry="8" fill="url(#layer3)" />
        <rect x="12" y="40" width="40" height="8" fill="url(#layer3)" />
        <ellipse cx="32" cy="40" rx="20" ry="8" fill="url(#layer2)" />
        
        {/* Middle layer */}
        <ellipse cx="32" cy="36" rx="16" ry="6" fill="url(#layer2)" />
        <rect x="16" y="30" width="32" height="6" fill="url(#layer2)" />
        <ellipse cx="32" cy="30" rx="16" ry="6" fill="url(#layer1)" />
        
        {/* Top layer */}
        <ellipse cx="32" cy="26" rx="12" ry="4" fill="url(#layer1)" />
        <rect x="20" y="22" width="24" height="4" fill="url(#layer1)" />
        <ellipse cx="32" cy="22" rx="12" ry="4" fill="#FFD700" />
      </svg>
    </div>
  );
} 
 