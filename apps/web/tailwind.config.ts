import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: ["class"],
  content: [
    "./pages/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./app/**/*.{ts,tsx}",
    "./src/**/*.{ts,tsx}",
  ],
  prefix: "",
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        // Surface hierarchy
        'surface-0': 'var(--c-surface-0)',
        'surface-1': 'var(--c-surface-1)', 
        'surface-2': 'var(--c-surface-2)',
        'surface-3': 'var(--c-surface-3)',
        
        // Signal Gold system
        'accent': {
          DEFAULT: 'var(--c-accent)',
          hover: 'var(--c-accent-hover)',
          pressed: 'var(--c-accent-pressed)',
          glow: 'var(--c-accent-glow)',
        },
        
        // Text hierarchy
        'text': {
          high: 'var(--c-text-high)',
          mid: 'var(--c-text-mid)',
          low: 'var(--c-text-low)',
          subtle: 'var(--c-text-subtle)',
        },
        
        // Borders
        border: {
          DEFAULT: 'var(--c-border)',
          subtle: 'var(--c-border-subtle)',
          accent: 'var(--c-border-accent)',
        },
        
        // Semantic colors
        success: 'var(--success)',
        error: 'var(--error)',
        warning: 'var(--warning)',
        info: 'var(--info)',
        
        // Legacy aliases for compatibility
        background: 'var(--background)',
        surface: 'var(--surface)',
        'surface-elevated': 'var(--surface-elevated)',
        'text-primary': 'var(--text-primary)',
        'text-secondary': 'var(--text-secondary)', 
        'text-tertiary': 'var(--text-tertiary)',
      },
      
      // Modular border radius system
      borderRadius: {
        'input': 'var(--r-input)',     // 6px - text fields, dropdowns
        'button': 'var(--r-button)',   // 10px - buttons, pills, tags
        'card': 'var(--r-card)',       // 12px - cards, modals, panels
        'modal': 'var(--r-modal)',     // 16px - large modals, sheets
        
        // Legacy aliases
        'sm': 'var(--radius-sm)',
        'md': 'var(--radius-md)', 
        'lg': 'var(--radius-lg)',
        'xl': 'var(--radius-xl)',
        'full': 'var(--radius-full)',
      },
      
      // Typography scale
      fontSize: {
        'xs': 'var(--font-size-xs)',
        'sm': 'var(--font-size-sm)',
        'base': 'var(--font-size-base)',
        'lg': 'var(--font-size-lg)',
        'xl': 'var(--font-size-xl)',
        '2xl': 'var(--font-size-2xl)',
        '3xl': 'var(--font-size-3xl)',
        '4xl': 'var(--font-size-4xl)',
        '5xl': 'var(--font-size-5xl)',
      },
      
      // Font families
      fontFamily: {
        'display': ['General Sans Variable', 'General Sans', 'system-ui', 'sans-serif'],
        'body': ['Inter Variable', 'Inter', 'system-ui', 'sans-serif'],
        'mono': ['JetBrains Mono Variable', 'JetBrains Mono', 'Fira Code', 'monospace'],
        'sans': ['Inter Variable', 'Inter', 'system-ui', 'sans-serif'],
      },
      
      // Spacing scale (4px base)
      spacing: {
        '1': 'var(--space-1)',
        '2': 'var(--space-2)',
        '3': 'var(--space-3)',
        '4': 'var(--space-4)',
        '5': 'var(--space-5)',
        '6': 'var(--space-6)',
        '8': 'var(--space-8)',
        '10': 'var(--space-10)',
        '12': 'var(--space-12)',
        '16': 'var(--space-16)',
      },
      
      // Animation timing
      transitionDuration: {
        'instant': 'var(--motion-instant)',
        'fast': 'var(--motion-fast)',
        'normal': 'var(--motion-normal)',
        'slow': 'var(--motion-slow)',
      },
      
      // Box shadows with AI-platform feel
      boxShadow: {
        'card': 'var(--shadow-card)',
        'card-hover': 'var(--shadow-card-hover)',
        'modal': 'var(--shadow-modal)',
        'glow-gold': 'var(--shadow-glow-gold)',
        'focus-ring': 'var(--shadow-focus-ring)',
      },
      
      // Background gradients
      backgroundImage: {
        'gradient-surface': 'var(--gradient-surface)',
        'gradient-card': 'var(--gradient-card)',
        'gradient-gold': 'var(--gradient-gold)',
        'gradient-glass': 'var(--gradient-glass)',
      },
      
      // Backdrop filters for glassmorphism
      backdropBlur: {
        'glass': 'var(--glass-blur)',
      },
      
      // Animation keyframes
      keyframes: {
        "fade-in": {
          "0%": { opacity: "0" },
          "100%": { opacity: "1" },
        },
        "slide-up": {
          "0%": { 
            opacity: "0", 
            transform: "translateY(12px)" 
          },
          "100%": { 
            opacity: "1", 
            transform: "translateY(0)" 
          },
        },
        "scale-in": {
          "0%": { 
            opacity: "0", 
            transform: "scale(0.95)" 
          },
          "100%": { 
            opacity: "1", 
            transform: "scale(1)" 
          },
        },
        "pulse-gold": {
          "0%, 100%": { opacity: "1" },
          "50%": { opacity: "0.7" },
        },
        "shimmer": {
          "0%": { backgroundPosition: "-200% 0" },
          "100%": { backgroundPosition: "200% 0" },
        }
      },
      animation: {
        "fade-in": "fade-in var(--motion-normal) ease-out",
        "slide-up": "slide-up var(--motion-normal) ease-out", 
        "scale-in": "scale-in var(--motion-fast) ease-out",
        "pulse-gold": "pulse-gold 2s infinite",
        "shimmer": "shimmer 2s linear infinite",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
} satisfies Config;

export default config; 