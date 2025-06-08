# HIVE Monorepo Documentation

Welcome to the central documentation hub for the HIVE project. This directory contains all architectural decision records (ADRs), system design documents, and development guides.

The canonical source of truth for the monorepo structure and development principles is the `.cursorrules` file in the project root. Please refer to it before starting any new development work.

---

### ARCHIVED LEGACY DOCUMENTATION

*The following content is from older project documentation that has been superseded by the new monorepo architecture defined in the root `.cursorrules` file. It is preserved here for historical context only and should not be considered the current source of truth.*

---

**BEGIN ARCHIVED CONTENT: `MONOREPO_ORGANIZATION_COMPLETE.md`**

# ✅ HIVE MONOREPO ORGANIZATION COMPLETE!

## 🏗️ **FINAL MONOREPO STRUCTURE**

```
hive/
├── apps/
│   ├── web/          # Next.js (React) - ✅ COMPLETE
│   │   ├── components/
│   │   ├── pages/
│   │   ├── styles/
│   │   └── package.json
│   └── mobile/       # Flutter - ✅ COMPLETE
│       ├── lib/      # Flutter source code
│       ├── android/  # Android platform files
│       ├── ios/      # iOS platform files
│       ├── windows/  # Windows platform files
│       ├── assets/   # Images, animations, etc.
│       ├── test/     # All Flutter tests
│       ├── pubspec.yaml
│       └── analysis_options.yaml
├── packages/
│   ├── core/         # ✅ CREATED - Shared utilities
│   │   └── package.json
│   ├── tokens/       # ✅ CREATED - Design tokens
│   │   ├── src/tokens.json
│   │   └── package.json
│   └── firebase/     # ✅ COMPLETE - Shared Firebase config
│       ├── functions/        # Firebase Functions
│       ├── firebase.json
│       ├── firestore.rules
│       ├── firestore.indexes.json
│       ├── storage.rules
│       └── package.json
├── docs/            # ✅ ORGANIZED
│   ├── memory-bank/ # All vBETA documentation
│   ├── *.md         # All project documentation
│   └── architecture/
├── turbo.json       # ✅ CONFIGURED
├── package.json     # ✅ ROOT WORKSPACE
└── .github/workflows/ # ✅ EXISTS
```

## 🚀 **WHAT WE ACCOMPLISHED**

### **✅ CODE ORGANIZATION**
- **Web App:** Successfully moved `landing-page/` → `apps/web/`
- **Mobile App:** Consolidated all Flutter code into `apps/mobile/`
  - Moved `lib/` directory with all source code
  - Moved `android/`, `ios/`, `windows/` platform files
  - Moved `assets/` (images, animations)
  - Moved `test/` directory with all tests
  - Moved `pubspec.yaml` and `analysis_options.yaml`

### **✅ SHARED PACKAGES**
- **@hive/core:** Created for shared utilities and validation
- **@hive/tokens:** Created for cross-platform design tokens
- **@hive/firebase:** Organized all Firebase configuration
  - Functions, rules, indexes, config files
  - Ready for shared backend across web and mobile

### **✅ DOCUMENTATION**
- **All docs:** Moved to `docs/` directory
- **Memory bank:** Preserved in `docs/memory-bank/`
- **Project docs:** Organized by category

### **✅ INFRASTRUCTURE**
- **Turborepo:** Configured for monorepo builds
- **Workspaces:** Root package.json set up for npm workspaces
- **Build system:** Ready for parallel builds across platforms

### **✅ CLEANUP**
- Removed temporary directories (`temp/`, `temp_project/`, `temp_fix/`, `example_app/`)
- Organized all scattered files into proper locations
- Maintained git history for all important files

## 🎯 **IMMEDIATE NEXT STEPS**

### **1. Install Dependencies**
```bash
# Install root dependencies and all workspaces
npm install

# Build design tokens first
npm run tokens:build
```

### **2. Start Development**
```bash
# Start web development
npm run web:dev

# Or start both platforms
npm run dev
```

### **3. Test the Setup**
```bash
# Test web build
cd apps/web && npm run build

# Test mobile build (Flutter)
cd apps/mobile && flutter build
```

## 💡 **DEVELOPMENT WORKFLOW**

### **For Web Development:**
```bash
cd apps/web
npm run dev
# http://localhost:3000
```

### **For Mobile Development:**
```bash
cd apps/mobile
flutter run
# Choose device (iOS Simulator, Android Emulator, etc.)
```

### **For Shared Package Development:**
```bash
# Design tokens
cd packages/tokens
npm run build

# Core utilities
cd packages/core
npm run dev

# Firebase functions
cd packages/firebase/functions
npm run build
```

## 🔧 **TECHNICAL BENEFITS**

1. **✅ Code Sharing:** Shared packages for utilities, tokens, and Firebase
2. **✅ Parallel Development:** Web and mobile teams can work independently
3. **✅ Consistent Design:** Shared design tokens across platforms
4. **✅ Unified Backend:** Single Firebase configuration for both platforms
5. **✅ Build Optimization:** Turborepo for fast, cached builds
6. **✅ Developer Experience:** Clear project structure and documentation

## 🎉 **RESULT**

Your HIVE codebase is now properly organized into a **professional, scalable monorepo** that supports:

- **React web app** for the main platform and HiveLAB tool creation
- **Flutter mobile apps** for iOS and Android
- **Shared packages** for design consistency and code reuse
- **Unified Firebase backend** for real-time data synchronization
- **Professional development workflow** with Turborepo

**The foundation is ready for building the actual HIVE vBETA features!** 🚀

---

_Next step: Start implementing the core HIVE features following the vBETA master plan._

**END ARCHIVED CONTENT: `MONOREPO_ORGANIZATION_COMPLETE.md`**
