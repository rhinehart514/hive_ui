# HIVE Web Project Setup Guide

_Last Updated: January 2025_  
_Purpose: Complete setup guide for HIVE React/Next.js development_  
_Target: Get Cursor AI assistant up and running quickly_

---

## 🎯 **PROJECT OVERVIEW**

### **Current Architecture**
```
hive_ui/
├── apps/
│   ├── web/           # React/Next.js - PRIMARY FOCUS
│   └── mobile/        # Flutter - DEFERRED
├── memory-bank/       # Product documentation
├── components/        # Shared components (legacy)
└── packages/          # Shared utilities
```

### **Technology Stack**
- **Frontend:** React 18, Next.js 14 (App Router)
- **Styling:** Tailwind CSS with custom HIVE design tokens
- **State:** Zustand (planned) or React Context
- **Database:** Firebase Firestore
- **Authentication:** Firebase Auth
- **Deployment:** Vercel (planned) or Firebase Hosting
- **Testing:** Jest, React Testing Library, Playwright

---

## 🚀 **QUICK START (FOR CURSOR)**

### **1. Environment Setup**
```bash
# Navigate to web app
cd apps/web

# Install dependencies
npm install

# Create environment file
cp .env.example .env.local

# Start development server
npm run dev
```

### **2. Essential Environment Variables**
Create `apps/web/.env.local`:
```env
# Firebase Configuration
NEXT_PUBLIC_FIREBASE_API_KEY=your_api_key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project_id
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
NEXT_PUBLIC_FIREBASE_APP_ID=your_app_id

# Development Settings
NODE_ENV=development
NEXT_PUBLIC_ENV=development
```

### **3. Development Server**
- **Local URL:** http://localhost:3000
- **Hot Reload:** Enabled by default
- **TypeScript:** Strict mode enabled

---

## 📁 **PROJECT STRUCTURE EXPLAINED**

### **Web App Structure (`apps/web/`)**
```
apps/web/
├── app/                    # Next.js App Router
│   ├── (auth)/            # Authentication routes
│   ├── (dashboard)/       # Protected dashboard routes
│   ├── globals.css        # Global styles + Tailwind
│   ├── layout.tsx         # Root layout
│   └── page.tsx           # Home page
├── components/            # React components
│   ├── ui/               # Basic UI components
│   ├── auth/             # Authentication components
│   ├── navigation/       # Navigation components
│   └── patterns/         # Complex patterns
├── lib/                  # Utility libraries
│   ├── firebase.ts       # Firebase configuration
│   ├── utils.ts          # General utilities
│   └── types.ts          # TypeScript types
├── hooks/                # Custom React hooks
├── styles/               # Additional styles
├── public/               # Static assets
└── package.json          # Dependencies
```

### **Key Configuration Files**
- `tailwind.config.js` - HIVE design system configuration
- `next.config.js` - Next.js optimization settings
- `tsconfig.json` - TypeScript strict configuration
- `eslint.config.js` - Code quality rules
- `package.json` - Dependencies and scripts

---

## 🎨 **DESIGN SYSTEM CONFIGURATION**

### **Tailwind CSS Setup**
File: `apps/web/tailwind.config.js`
```javascript
module.exports = {
  content: [
    './app/**/*.{js,ts,jsx,tsx}',
    './components/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        // HIVE Brand Colors
        'hive-black': '#0D0D0D',
        'hive-surface': '#1E1E1E',
        'hive-surface-light': '#2A2A2A',
        'hive-gold': '#FFD700',
        'hive-gold-hover': '#FFDF2B',
        'hive-gold-pressed': '#CCAD00',
        
        // Semantic Colors
        'hive-success': '#8CE563',
        'hive-error': '#FF3B30',
        'hive-warning': '#FF9500',
        'hive-info': '#56CCF2',
      },
      spacing: {
        // 4pt base grid system
        '1': '0.25rem',  // 4px
        '2': '0.5rem',   // 8px
        '3': '0.75rem',  // 12px
        '4': '1rem',     // 16px
        '6': '1.5rem',   // 24px
        '8': '2rem',     // 32px
      },
      borderRadius: {
        // HIVE border radius system
        'hive-button': '24px',
        'hive-card': '20px',
        'hive-input': '12px',
      },
      fontFamily: {
        // Typography system
        'sf-pro': ['SF Pro Display', 'system-ui', 'sans-serif'],
        'sf-text': ['SF Pro Text', 'system-ui', 'sans-serif'],
      },
      fontSize: {
        // HIVE type scale
        'hive-caption': ['14px', { lineHeight: '20px' }],
        'hive-body': ['17px', { lineHeight: '24px' }],
        'hive-subhead': ['22px', { lineHeight: '28px' }],
        'hive-headline': ['28px', { lineHeight: '34px' }],
        'hive-title': ['34px', { lineHeight: '40px' }],
      },
      animation: {
        // Brand-compliant animations
        'fade-in': 'fadeIn 300ms ease-out',
        'slide-up': 'slideUp 400ms cubic-bezier(0.4, 0, 0.2, 1)',
        'zoom-in': 'zoomIn 200ms cubic-bezier(0.4, 0, 1, 1)',
      },
    },
  },
  plugins: [],
}
```

### **Global Styles**
File: `apps/web/app/globals.css`
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

/* HIVE Brand Base Styles */
@layer base {
  * {
    @apply border-border;
  }
  
  body {
    @apply bg-hive-black text-white font-sf-text;
    @apply text-hive-body;
  }
  
  h1, h2, h3, h4, h5, h6 {
    @apply font-sf-pro font-medium;
  }
}

/* HIVE Component Classes */
@layer components {
  .hive-card {
    @apply bg-gradient-to-br from-hive-surface to-hive-surface-light;
    @apply rounded-hive-card p-4;
    @apply border border-white/5;
  }
  
  .hive-button-primary {
    @apply bg-hive-gold text-black font-semibold;
    @apply rounded-hive-button px-6 py-2;
    @apply hover:bg-hive-gold-hover active:bg-hive-gold-pressed;
    @apply transition-colors duration-150;
  }
  
  .hive-button-secondary {
    @apply bg-transparent text-white border border-white/10;
    @apply rounded-hive-button px-6 py-2;
    @apply hover:border-white/20 active:bg-white/5;
    @apply transition-all duration-150;
  }
  
  .hive-input {
    @apply bg-white/5 border border-white/10 rounded-hive-input;
    @apply px-4 py-3 text-white placeholder:text-white/50;
    @apply focus:border-hive-gold focus:outline-none;
    @apply transition-colors duration-150;
  }
}

/* HIVE Animations */
@layer utilities {
  @keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
  }
  
  @keyframes slideUp {
    from { 
      opacity: 0; 
      transform: translateY(12px); 
    }
    to { 
      opacity: 1; 
      transform: translateY(0); 
    }
  }
  
  @keyframes zoomIn {
    from { 
      opacity: 0; 
      transform: scale(0.8); 
    }
    to { 
      opacity: 1; 
      transform: scale(1); 
    }
  }
}
```

---

## 🔧 **DEVELOPMENT COMMANDS**

### **Primary Commands**
```bash
# Development
npm run dev              # Start dev server (localhost:3000)
npm run build           # Production build
npm run start           # Start production server
npm run lint            # ESLint check
npm run type-check      # TypeScript check

# Testing
npm run test            # Run Jest tests
npm run test:watch      # Jest in watch mode
npm run test:e2e        # Playwright E2E tests
npm run test:coverage   # Test coverage report

# Quality
npm run format          # Prettier formatting
npm run analyze         # Bundle analysis
npm run lighthouse      # Performance audit
```

### **Component Development**
```bash
# Generate new component
npm run generate:component ComponentName

# Generate new page
npm run generate:page page-name

# Storybook (if configured)
npm run storybook
```

---

## 🔥 **FIREBASE SETUP**

### **1. Firebase Project Creation**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize project (from apps/web/)
firebase init
```

### **2. Firebase Configuration**
File: `apps/web/lib/firebase.ts`
```typescript
import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'
import { getStorage } from 'firebase/storage'

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
}

const app = initializeApp(firebaseConfig)

export const auth = getAuth(app)
export const db = getFirestore(app)
export const storage = getStorage(app)
export default app
```

### **3. Firestore Security Rules**
File: `firestore.rules`
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Spaces are readable by all authenticated users
    match /spaces/{spaceId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && isSpaceBuilder(spaceId);
    }
    
    // Events are readable by all authenticated users
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && isEventCreator();
    }
    
    // Helper functions
    function isSpaceBuilder(spaceId) {
      return exists(/databases/$(database)/documents/spaces/$(spaceId)/builders/$(request.auth.uid));
    }
    
    function isEventCreator() {
      return resource.data.createdBy == request.auth.uid;
    }
  }
}
```

---

## 🧪 **TESTING SETUP**

### **Jest Configuration**
File: `apps/web/jest.config.js`
```javascript
const nextJest = require('next/jest')

const createJestConfig = nextJest({
  dir: './',
})

const customJestConfig = {
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  testEnvironment: 'jest-environment-jsdom',
  collectCoverageFrom: [
    'components/**/*.{js,jsx,ts,tsx}',
    'app/**/*.{js,jsx,ts,tsx}',
    'lib/**/*.{js,jsx,ts,tsx}',
    '!**/*.d.ts',
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
}

module.exports = createJestConfig(customJestConfig)
```

### **Playwright E2E Configuration**
File: `apps/web/playwright.config.ts`
```typescript
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
})
```

---

## 📱 **RESPONSIVE DESIGN SYSTEM**

### **Breakpoints**
```javascript
// Tailwind breakpoints for HIVE
const breakpoints = {
  sm: '640px',   // Mobile landscape
  md: '768px',   // Tablet
  lg: '1024px',  // Desktop
  xl: '1280px',  // Large desktop
  '2xl': '1536px' // Extra large
}
```

### **Component Responsive Patterns**
```tsx
// Navigation example
<nav className="
  flex flex-col md:flex-row 
  items-start md:items-center 
  gap-4 md:gap-8
  p-4 md:p-6
">
  {/* Mobile: Vertical stack, Desktop: Horizontal row */}
</nav>

// Card grid example
<div className="
  grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 
  gap-4 md:gap-6 
  p-4 md:p-8
">
  {/* Responsive grid */}
</div>
```

---

## 🚀 **DEPLOYMENT SETUP**

### **Vercel Deployment (Recommended)**
1. Connect GitHub repository to Vercel
2. Set environment variables in Vercel dashboard
3. Deploy automatically on push to main

### **Firebase Hosting (Alternative)**
```bash
# Build for production
npm run build

# Deploy to Firebase
firebase deploy --only hosting
```

### **Environment Variables for Production**
```env
# Production Firebase config
NEXT_PUBLIC_FIREBASE_API_KEY=prod_api_key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=hive-prod.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=hive-prod
# ... other production values

# Production settings
NODE_ENV=production
NEXT_PUBLIC_ENV=production
NEXT_PUBLIC_APP_URL=https://hive.university
```

---

## 🔍 **DEBUGGING & DEVELOPMENT TOOLS**

### **React Developer Tools**
- Install React DevTools browser extension
- Access component tree and state inspection

### **Firebase Emulator Suite**
```bash
# Start emulators for local development
firebase emulators:start

# Emulator UI: http://localhost:4000
# Auth Emulator: http://localhost:9099
# Firestore Emulator: http://localhost:8080
```

### **Performance Monitoring**
```bash
# Lighthouse audit
npm run lighthouse

# Bundle analyzer
npm run analyze

# Performance profiling in dev mode
npm run dev -- --experimental-profiling
```

---

## 📚 **KEY RESOURCES FOR CURSOR**

### **Documentation Links**
- [HIVE Brand Aesthetic Guidelines](./brand_aesthetic.md)
- [HIVE UI/UX Implementation Rules](./ui_ux_guidelines.md)
- [HIVE Master Checklist](./hive_web_master_checklist.md)
- [Product Context & Features](./app_completion_master_plan.md)

### **Component Examples**
All existing components are in `apps/web/components/ui/` for reference

### **Development Workflow**
1. **Check master checklist** for current priorities
2. **Follow brand aesthetic** guidelines strictly
3. **Test responsively** (320px to 1920px)
4. **Validate accessibility** (keyboard nav, screen reader)
5. **Performance check** (Lighthouse >90)

---

**READY FOR DEVELOPMENT** 🚀

This setup guide provides everything needed for Cursor to begin implementing HIVE components and features according to our web-first strategy. 