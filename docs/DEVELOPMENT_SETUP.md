# HIVE Development Setup Guide

## 🏗️ Hybrid Platform Architecture

**HIVE uses a hybrid approach for optimal platform experience:**

### **Web Platform: React/Next.js**
- **Location:** `./landing-page/`
- **Tech Stack:** Next.js 14, React 18, TypeScript, Tailwind CSS
- **Purpose:** Primary web experience, Builder tools (HiveLAB), admin interfaces

### **Mobile Platform: Flutter**
- **Location:** `./` (root directory)
- **Tech Stack:** Flutter, Dart, Riverpod, Clean Architecture
- **Purpose:** Native iOS/Android apps, mobile-optimized experiences

### **Shared Backend: Firebase**
- **Services:** Auth, Firestore, Functions, Storage, Hosting
- **Data:** Shared across web and mobile platforms
- **Real-time:** Cross-platform synchronization

---

## 🚀 Development Commands

### **Web Development (React)**
```bash
# Navigate to web directory
cd landing-page

# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

### **Mobile Development (Flutter)**
```bash
# Install dependencies
flutter pub get

# Run on iOS simulator
flutter run -d ios

# Run on Android emulator
flutter run -d android

# Build for production
flutter build apk --release
flutter build ios --release
```

### **Backend Development (Firebase)**
```bash
# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy functions
firebase deploy --only functions

# Deploy Firestore rules
firebase deploy --only firestore:rules
```

---

## 🎨 Design System Integration

### **Web Components (React)**
- **Location:** `./landing-page/components/design/`
- **Implementation:** React components with Tailwind CSS
- **Tokens:** CSS custom properties following HIVE design system

### **Mobile Components (Flutter)**
- **Location:** `./lib/core/design/`
- **Implementation:** Flutter widgets with HIVE theme
- **Tokens:** Dart constants and theme data

### **Cross-Platform Consistency**
- Shared design tokens ensure visual consistency
- Component APIs mirror each other where possible
- Brand guidelines followed on both platforms

---

## 🔄 Development Workflow

### **Feature Development**
1. **Design System:** Build components in both React and Flutter
2. **Backend:** Implement Firebase functions and data models
3. **Web:** Implement React components and pages
4. **Mobile:** Implement Flutter widgets and screens
5. **Integration:** Test cross-platform data synchronization

### **Builder Tools (Web-Only)**
- **HiveLAB:** React-based tool composer interface
- **Admin:** Web-only administration interfaces
- **Analytics:** Web-based Builder dashboards and metrics

### **Mobile-Optimized Features**
- **Profile:** Mobile-first personal productivity
- **Spaces:** Touch-optimized community interaction
- **Events:** Mobile calendar integration and notifications

---

## 📱 Platform-Specific Features

### **Web Advantages**
- Rich tool creation interfaces (HiveLAB)
- Complex data visualization and analytics
- Keyboard-optimized workflows
- Large screen space utilization

### **Mobile Advantages**
- Native haptic feedback and gestures
- Push notifications and calendar integration
- Location-aware features
- Camera and file system access

### **Shared Features**
- User authentication and profiles
- Space discovery and joining
- Event browsing and RSVPs
- Real-time chat and coordination

---

This hybrid approach ensures HIVE delivers optimal experiences on each platform while maintaining shared data and brand consistency. 