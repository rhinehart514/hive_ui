'use client';

import React from 'react';
import { Card } from '@/components/ui/card';


interface ModularBlockProps {
  // Core module properties
  id?: string;
  variant?: 'compact' | 'standard' | 'expanded' | 'hero';
  
  // Content flexibility
  imageUrl?: string;
  imageAlt?: string;
  title?: string;
  subtitle?: string;
  content?: React.ReactNode;

  
  // Modular positioning
  gridSpan?: 1 | 2 | 3 | 4;
  stackable?: boolean;
  connectable?: boolean;
  
  // Visual treatment
  hasGlow?: boolean;
  borderStyle?: 'none' | 'subtle' | 'accent' | 'live';
  
  // Interaction
  onClick?: () => void;
  onConnect?: (blockId: string) => void;
  isSelected?: boolean;
  isConnected?: boolean;
  
  className?: string;
  children?: React.ReactNode;
}

export function ModularBlock({
  id = `block-${Math.random().toString(36).substr(2, 9)}`,
  variant = 'standard',
  imageUrl,
  imageAlt,
  title,
  subtitle,
  content,

  gridSpan = 1,
  stackable = true,
  connectable = false,
  hasGlow = false,
  borderStyle = 'subtle',
  onClick,
  onConnect,
  isSelected = false,
  isConnected = false,
  className = '',
  children
}: ModularBlockProps) {
  

  
  const getVariantStyles = () => {
    switch (variant) {
      case 'compact':
        return 'h-24 p-3';
      case 'standard':
        return 'h-32 p-4';
      case 'expanded':
        return 'h-48 p-6';
      case 'hero':
        return 'h-64 p-8';
      default:
        return 'h-32 p-4';
    }
  };

  const getBorderStyles = () => {
    switch (borderStyle) {
      case 'none':
        return 'border-transparent';
      case 'subtle':
        return 'border-white/10';
      case 'accent':
        return 'border-brand-gold-500/50';
      case 'live':
        return 'border-brand-gold-500 shadow-[0_0_20px_rgba(231,182,20,0.3)]';
      default:
        return 'border-white/10';
    }
  };

  const moduleClasses = `
    relative overflow-hidden
    bg-surface-1 border rounded-lg
    transition-all duration-standard
    cursor-pointer
    group
    ${getVariantStyles()}
    ${getBorderStyles()}
    ${hasGlow ? 'shadow-lg shadow-brand-gold-500/20' : ''}
    ${isSelected ? 'ring-2 ring-brand-gold-500' : ''}
    ${isConnected ? 'border-brand-gold-400' : ''}
    ${stackable ? 'hover:scale-105 hover:z-10' : ''}
    hover:border-brand-gold-500/30
    col-span-${gridSpan}
    ${className}
  `;

  return (
    <Card 
      className={moduleClasses}
      onClick={onClick}
      data-module-id={id}
    >
      {/* Connection Indicators */}
      {connectable && (
        <div className="absolute top-2 right-2 flex gap-1">
          <div className={`w-2 h-2 rounded-full transition-colors ${
            isConnected ? 'bg-brand-gold-500' : 'bg-white/20'
          }`} />
        </div>
      )}

      {/* Image Section */}
      {imageUrl && (
        <div className={`relative overflow-hidden rounded-md mb-3 ${
          variant === 'compact' ? 'h-12' : variant === 'hero' ? 'h-32' : 'h-16'
        }`}>
          <img 
            src={imageUrl} 
            alt={imageAlt || title || 'Module content'}
            className="w-full h-full object-cover transition-transform duration-standard group-hover:scale-110"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />
          
          {/* Overlay title for image modules */}
          {title && variant !== 'compact' && (
            <div className="absolute bottom-2 left-2 text-white">
              <h3 className="text-sm font-semibold drop-shadow-lg">{title}</h3>
              {subtitle && (
                <p className="text-xs opacity-80 drop-shadow-lg">{subtitle}</p>
              )}
            </div>
          )}
        </div>
      )}

      {/* Content Section */}
      <div className={`${imageUrl ? 'space-y-2' : 'space-y-3'}`}>
        {/* Title/Subtitle for non-image modules */}
        {!imageUrl && title && (
          <div>
            <h3 className={`font-semibold text-text-primary line-clamp-1 ${
              variant === 'compact' ? 'text-sm' : 'text-base'
            }`}>
              {title}
            </h3>
            {subtitle && (
              <p className="text-xs text-text-secondary line-clamp-1">
                {subtitle}
              </p>
            )}
          </div>
        )}

        {/* Custom content */}
        {content && (
          <div className={`text-text-secondary ${
            variant === 'compact' ? 'text-xs' : 'text-sm'
          }`}>
            {content}
          </div>
        )}

        {/* Children content */}
        {children && (
          <div className="flex-1">
            {children}
          </div>
        )}
      </div>

      {/* Modular Grid Indicator */}
      {stackable && (
        <div className="absolute bottom-1 left-1 opacity-0 group-hover:opacity-30 transition-opacity">
          <div className="grid grid-cols-2 gap-px">
            <div className="w-1 h-1 bg-brand-gold-500 rounded-full" />
            <div className="w-1 h-1 bg-brand-gold-500 rounded-full" />
            <div className="w-1 h-1 bg-brand-gold-500 rounded-full" />
            <div className="w-1 h-1 bg-brand-gold-500 rounded-full" />
          </div>
        </div>
      )}
    </Card>
  );
}

// Modular Grid Container
interface ModularGridProps {
  children: React.ReactNode;
  cols?: 2 | 3 | 4 | 6;
  gap?: 'tight' | 'normal' | 'loose';
  className?: string;
}

export function ModularGrid({ 
  children, 
  cols = 4, 
  gap = 'normal',
  className = '' 
}: ModularGridProps) {
  const gapClasses = {
    tight: 'gap-2',
    normal: 'gap-4',
    loose: 'gap-6'
  };

  return (
    <div className={`
      grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-${cols}
      ${gapClasses[gap]}
      w-full
      ${className}
    `}>
      {children}
    </div>
  );
}

// Showcase with real modular feel
export function ModularBlockShowcase() {
  return (
    <div className="space-y-8 p-6 bg-surface-0 min-h-screen">
      <div className="text-center space-y-2 mb-8">
        <h1 className="text-h1 font-bold text-text-primary">Modular Infrastructure</h1>
        <p className="text-body text-text-secondary">True building blocks that snap together</p>
      </div>

      {/* Hero Section */}
      <ModularGrid cols={3} gap="normal">
        <ModularBlock
          variant="hero"
          gridSpan={2}
          title="CS Study Hub"
          subtitle="Active community • 234 members"
          borderStyle="live"
          hasGlow
          connectable
          isConnected
        />
        
        <ModularBlock
          variant="expanded"
          title="Live Events"
          content={
            <div className="space-y-2">
              <div className="text-xs text-brand-gold-500">• Hackathon starts in 2h</div>
              <div className="text-xs text-text-secondary">• Study session at 7pm</div>
              <div className="text-xs text-text-secondary">• Career fair tomorrow</div>
            </div>
          }
          borderStyle="accent"
        />
      </ModularGrid>

      {/* Tool Modules */}
      <ModularGrid cols={4} gap="normal">
        <ModularBlock
          variant="standard"
          title="Quick Poll"
          subtitle="142 uses"
          stackable
          connectable
        />
        
        <ModularBlock
          variant="standard"
          title="Study Tracker"
          subtitle="89 uses"
          stackable
          connectable
        />
        
        <ModularBlock
          variant="standard"
          title="Anonymous Q&A"
          content={<div className="text-xs">Safe space for questions</div>}
          borderStyle="subtle"
          stackable
        />
        
        <ModularBlock
          variant="standard"
          title="RSVP Manager"
          content={<div className="text-xs">Event coordination</div>}
          borderStyle="subtle"
          stackable
        />
      </ModularGrid>

      {/* Compact Info Modules */}
      <ModularGrid cols={6} gap="tight">
        <ModularBlock
          variant="compact"
          title="24"
          subtitle="Tools created"
          borderStyle="accent"
        />
        
        <ModularBlock
          variant="compact"
          title="156"
          subtitle="Active users"
          borderStyle="none"
        />
        
        <ModularBlock
          variant="compact"
          title="8"
          subtitle="Spaces joined"
          borderStyle="none"
        />
        
        <ModularBlock
          variant="compact"
          imageUrl="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face"
          title="Sarah"
          borderStyle="subtle"
        />
        
        <ModularBlock
          variant="compact"
          imageUrl="https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop&crop=face"
          title="Mike"
          borderStyle="subtle"
        />
        
        <ModularBlock
          variant="compact"
          title="+ 45"
          subtitle="more"
          borderStyle="subtle"
        />
      </ModularGrid>
    </div>
  );
} 

import React from 'react';
import { Card } from '@/components/ui/card';


interface ModularBlockProps {
  // Core module properties
  id?: string;
  variant?: 'compact' | 'standard' | 'expanded' | 'hero';
  
  // Content flexibility
  imageUrl?: string;
  imageAlt?: string;
  title?: string;
  subtitle?: string;
  content?: React.ReactNode;

  
  // Modular positioning
  gridSpan?: 1 | 2 | 3 | 4;
  stackable?: boolean;
  connectable?: boolean;
  
  // Visual treatment
  hasGlow?: boolean;
  borderStyle?: 'none' | 'subtle' | 'accent' | 'live';
  
  // Interaction
  onClick?: () => void;
  onConnect?: (blockId: string) => void;
  isSelected?: boolean;
  isConnected?: boolean;
  
  className?: string;
  children?: React.ReactNode;
}

export function ModularBlock({
  id = `block-${Math.random().toString(36).substr(2, 9)}`,
  variant = 'standard',
  imageUrl,
  imageAlt,
  title,
  subtitle,
  content,

  gridSpan = 1,
  stackable = true,
  connectable = false,
  hasGlow = false,
  borderStyle = 'subtle',
  onClick,
  onConnect,
  isSelected = false,
  isConnected = false,
  className = '',
  children
}: ModularBlockProps) {
  

  
  const getVariantStyles = () => {
    switch (variant) {
      case 'compact':
        return 'h-24 p-3';
      case 'standard':
        return 'h-32 p-4';
      case 'expanded':
        return 'h-48 p-6';
      case 'hero':
        return 'h-64 p-8';
      default:
        return 'h-32 p-4';
    }
  };

  const getBorderStyles = () => {
    switch (borderStyle) {
      case 'none':
        return 'border-transparent';
      case 'subtle':
        return 'border-white/10';
      case 'accent':
        return 'border-brand-gold-500/50';
      case 'live':
        return 'border-brand-gold-500 shadow-[0_0_20px_rgba(231,182,20,0.3)]';
      default:
        return 'border-white/10';
    }
  };

  const moduleClasses = `
    relative overflow-hidden
    bg-surface-1 border rounded-lg
    transition-all duration-standard
    cursor-pointer
    group
    ${getVariantStyles()}
    ${getBorderStyles()}
    ${hasGlow ? 'shadow-lg shadow-brand-gold-500/20' : ''}
    ${isSelected ? 'ring-2 ring-brand-gold-500' : ''}
    ${isConnected ? 'border-brand-gold-400' : ''}
    ${stackable ? 'hover:scale-105 hover:z-10' : ''}
    hover:border-brand-gold-500/30
    col-span-${gridSpan}
    ${className}
  `;

  return (
    <Card 
      className={moduleClasses}
      onClick={onClick}
      data-module-id={id}
    >
      {/* Connection Indicators */}
      {connectable && (
        <div className="absolute top-2 right-2 flex gap-1">
          <div className={`w-2 h-2 rounded-full transition-colors ${
            isConnected ? 'bg-brand-gold-500' : 'bg-white/20'
          }`} />
        </div>
      )}

      {/* Image Section */}
      {imageUrl && (
        <div className={`relative overflow-hidden rounded-md mb-3 ${
          variant === 'compact' ? 'h-12' : variant === 'hero' ? 'h-32' : 'h-16'
        }`}>
          <img 
            src={imageUrl} 
            alt={imageAlt || title || 'Module content'}
            className="w-full h-full object-cover transition-transform duration-standard group-hover:scale-110"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />
          
          {/* Overlay title for image modules */}
          {title && variant !== 'compact' && (
            <div className="absolute bottom-2 left-2 text-white">
              <h3 className="text-sm font-semibold drop-shadow-lg">{title}</h3>
              {subtitle && (
                <p className="text-xs opacity-80 drop-shadow-lg">{subtitle}</p>
              )}
            </div>
          )}
        </div>
      )}

      {/* Content Section */}
      <div className={`${imageUrl ? 'space-y-2' : 'space-y-3'}`}>
        {/* Title/Subtitle for non-image modules */}
        {!imageUrl && title && (
          <div>
            <h3 className={`font-semibold text-text-primary line-clamp-1 ${
              variant === 'compact' ? 'text-sm' : 'text-base'
            }`}>
              {title}
            </h3>
            {subtitle && (
              <p className="text-xs text-text-secondary line-clamp-1">
                {subtitle}
              </p>
            )}
          </div>
        )}

        {/* Custom content */}
        {content && (
          <div className={`text-text-secondary ${
            variant === 'compact' ? 'text-xs' : 'text-sm'
          }`}>
            {content}
          </div>
        )}

        {/* Children content */}
        {children && (
          <div className="flex-1">
            {children}
          </div>
        )}
      </div>

      {/* Modular Grid Indicator */}
      {stackable && (
        <div className="absolute bottom-1 left-1 opacity-0 group-hover:opacity-30 transition-opacity">
          <div className="grid grid-cols-2 gap-px">
            <div className="w-1 h-1 bg-brand-gold-500 rounded-full" />
            <div className="w-1 h-1 bg-brand-gold-500 rounded-full" />
            <div className="w-1 h-1 bg-brand-gold-500 rounded-full" />
            <div className="w-1 h-1 bg-brand-gold-500 rounded-full" />
          </div>
        </div>
      )}
    </Card>
  );
}

// Modular Grid Container
interface ModularGridProps {
  children: React.ReactNode;
  cols?: 2 | 3 | 4 | 6;
  gap?: 'tight' | 'normal' | 'loose';
  className?: string;
}

export function ModularGrid({ 
  children, 
  cols = 4, 
  gap = 'normal',
  className = '' 
}: ModularGridProps) {
  const gapClasses = {
    tight: 'gap-2',
    normal: 'gap-4',
    loose: 'gap-6'
  };

  return (
    <div className={`
      grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-${cols}
      ${gapClasses[gap]}
      w-full
      ${className}
    `}>
      {children}
    </div>
  );
}

// Showcase with real modular feel
export function ModularBlockShowcase() {
  return (
    <div className="space-y-8 p-6 bg-surface-0 min-h-screen">
      <div className="text-center space-y-2 mb-8">
        <h1 className="text-h1 font-bold text-text-primary">Modular Infrastructure</h1>
        <p className="text-body text-text-secondary">True building blocks that snap together</p>
      </div>

      {/* Hero Section */}
      <ModularGrid cols={3} gap="normal">
        <ModularBlock
          variant="hero"
          gridSpan={2}
          title="CS Study Hub"
          subtitle="Active community • 234 members"
          borderStyle="live"
          hasGlow
          connectable
          isConnected
        />
        
        <ModularBlock
          variant="expanded"
          title="Live Events"
          content={
            <div className="space-y-2">
              <div className="text-xs text-brand-gold-500">• Hackathon starts in 2h</div>
              <div className="text-xs text-text-secondary">• Study session at 7pm</div>
              <div className="text-xs text-text-secondary">• Career fair tomorrow</div>
            </div>
          }
          borderStyle="accent"
        />
      </ModularGrid>

      {/* Tool Modules */}
      <ModularGrid cols={4} gap="normal">
        <ModularBlock
          variant="standard"
          title="Quick Poll"
          subtitle="142 uses"
          stackable
          connectable
        />
        
        <ModularBlock
          variant="standard"
          title="Study Tracker"
          subtitle="89 uses"
          stackable
          connectable
        />
        
        <ModularBlock
          variant="standard"
          title="Anonymous Q&A"
          content={<div className="text-xs">Safe space for questions</div>}
          borderStyle="subtle"
          stackable
        />
        
        <ModularBlock
          variant="standard"
          title="RSVP Manager"
          content={<div className="text-xs">Event coordination</div>}
          borderStyle="subtle"
          stackable
        />
      </ModularGrid>

      {/* Compact Info Modules */}
      <ModularGrid cols={6} gap="tight">
        <ModularBlock
          variant="compact"
          title="24"
          subtitle="Tools created"
          borderStyle="accent"
        />
        
        <ModularBlock
          variant="compact"
          title="156"
          subtitle="Active users"
          borderStyle="none"
        />
        
        <ModularBlock
          variant="compact"
          title="8"
          subtitle="Spaces joined"
          borderStyle="none"
        />
        
        <ModularBlock
          variant="compact"
          imageUrl="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face"
          title="Sarah"
          borderStyle="subtle"
        />
        
        <ModularBlock
          variant="compact"
          imageUrl="https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop&crop=face"
          title="Mike"
          borderStyle="subtle"
        />
        
        <ModularBlock
          variant="compact"
          title="+ 45"
          subtitle="more"
          borderStyle="subtle"
        />
      </ModularGrid>
    </div>
  );
} 
 