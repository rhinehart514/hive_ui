# HIVE Component Design Specifications

*Detailed design specifications for building the HIVE design system*

---

## **DESIGN TOKENS FOUNDATION**

### **Color System** 
```css
/* HIVE Surface Hierarchy */
--hive-canvas: #0A0A0A;           /* Pure background */
--hive-surface-1: #131313;        /* Cards, modals */
--hive-surface-2: #1B1B1B;        /* Hover states, inputs */
--hive-surface-3: #262626;        /* Borders, dividers */

/* HIVE Text Hierarchy */
--hive-text-primary: #FFFFFF;     /* Headlines, body */
--hive-text-secondary: #B3B3B3;   /* Metadata, captions */
--hive-text-disabled: #525252;    /* Disabled states */

/* HIVE Sacred Gold */
--hive-gold: #FFD700;             /* Primary actions only */
--hive-gold-hover: #FFED4A;       /* Gold hover state */
--hive-gold-pressed: #E6C200;     /* Gold pressed state */

/* HIVE Semantic Colors */
--hive-success: #10B981;          /* Success actions */
--hive-error: #EF4444;            /* Error states */
--hive-warning: #F59E0B;          /* Warning states */
--hive-info: #3B82F6;             /* Information */
```

### **Spacing Scale** (4pt grid system)
```css
--space-1: 4px;    /* Micro spacing */
--space-2: 8px;    /* Small spacing */
--space-3: 12px;   /* Medium spacing */
--space-4: 16px;   /* Base spacing */
--space-6: 24px;   /* Large spacing */
--space-8: 32px;   /* XL spacing */
--space-12: 48px;  /* XXL spacing */
--space-16: 64px;  /* XXXL spacing */
```

### **Typography Scale**
```css
--text-xs: 12px;   /* Micro text */
--text-sm: 14px;   /* Small text */
--text-base: 16px; /* Body text */
--text-lg: 18px;   /* Large text */
--text-xl: 20px;   /* XL text */
--text-2xl: 24px;  /* Heading */
--text-3xl: 30px;  /* Large heading */
--text-4xl: 36px;  /* Display */
```

### **Border Radius**
```css
--radius-sm: 6px;   /* Small elements */
--radius-md: 8px;   /* Default radius */
--radius-lg: 12px;  /* Cards */
--radius-xl: 16px;  /* Large cards */
--radius-2xl: 20px; /* Modals */
--radius-full: 9999px; /* Pills/circles */
```

---

## **FOUNDATION COMPONENTS**

### **1. HiveButton**

#### **Variants & Specifications**

**Primary Button (Sacred Gold)**
```css
.hive-button-primary {
  background: var(--hive-gold);
  color: #000000;
  border: none;
  border-radius: var(--radius-lg);
  padding: var(--space-3) var(--space-6);
  font-weight: 600;
  font-size: var(--text-base);
  transition: all 150ms ease-out;
  box-shadow: 
    0 1px 2px rgba(0, 0, 0, 0.3),
    0 4px 8px rgba(255, 215, 0, 0.2);
}

.hive-button-primary:hover {
  background: var(--hive-gold-hover);
  transform: translateY(-1px);
  box-shadow: 
    0 2px 4px rgba(0, 0, 0, 0.4),
    0 8px 16px rgba(255, 215, 0, 0.3);
}

.hive-button-primary:active {
  background: var(--hive-gold-pressed);
  transform: scale(0.98);
  box-shadow: 
    0 1px 2px rgba(0, 0, 0, 0.4);
}
```

**Secondary Button (Surface)**
```css
.hive-button-secondary {
  background: var(--hive-surface-1);
  color: var(--hive-text-primary);
  border: 1px solid var(--hive-surface-3);
  border-radius: var(--radius-lg);
  padding: var(--space-3) var(--space-6);
  font-weight: 500;
  font-size: var(--text-base);
  transition: all 150ms ease-out;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
}

.hive-button-secondary:hover {
  background: var(--hive-surface-2);
  border-color: var(--hive-gold);
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}
```

**Ghost Button (Minimal)**
```css
.hive-button-ghost {
  background: transparent;
  color: var(--hive-text-secondary);
  border: none;
  border-radius: var(--radius-md);
  padding: var(--space-2) var(--space-4);
  font-weight: 500;
  font-size: var(--text-sm);
  transition: all 150ms ease-out;
}

.hive-button-ghost:hover {
  background: var(--hive-surface-1);
  color: var(--hive-text-primary);
}
```

#### **Size Variants**
```css
/* Small */
.hive-button-sm {
  padding: var(--space-2) var(--space-4);
  font-size: var(--text-sm);
  border-radius: var(--radius-md);
}

/* Default */
.hive-button-default {
  padding: var(--space-3) var(--space-6);
  font-size: var(--text-base);
  border-radius: var(--radius-lg);
}

/* Large */
.hive-button-lg {
  padding: var(--space-4) var(--space-8);
  font-size: var(--text-lg);
  border-radius: var(--radius-xl);
}
```

#### **States**
```css
.hive-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none !important;
}

.hive-button:focus-visible {
  outline: 2px solid var(--hive-gold);
  outline-offset: 2px;
}

.hive-button-loading {
  position: relative;
  color: transparent;
}

.hive-button-loading::after {
  content: '';
  position: absolute;
  top: 50%;
  left: 50%;
  width: 16px;
  height: 16px;
  border: 2px solid currentColor;
  border-right-color: transparent;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  transform: translate(-50%, -50%);
}
```

---

### **2. HiveCard**

#### **Base Card Specifications**
```css
.hive-card {
  background: var(--hive-surface-1);
  border: 1px solid var(--hive-surface-3);
  border-radius: var(--radius-xl);
  padding: var(--space-6);
  transition: all 200ms ease-out;
  box-shadow: 
    0 1px 3px rgba(0, 0, 0, 0.3),
    0 0 0 1px rgba(255, 255, 255, 0.02);
}

.hive-card:hover {
  transform: translateY(-2px);
  box-shadow: 
    0 4px 12px rgba(0, 0, 0, 0.4),
    0 0 0 1px rgba(255, 255, 255, 0.05);
}
```

#### **Card Variants**

**Glass Card**
```css
.hive-card-glass {
  background: rgba(19, 19, 19, 0.8);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow: 
    0 1px 3px rgba(0, 0, 0, 0.3),
    inset 0 1px 0 rgba(255, 255, 255, 0.1);
}
```

**Premium Card (Gold Accent)**
```css
.hive-card-premium {
  border: 1px solid rgba(255, 215, 0, 0.2);
  box-shadow: 
    0 1px 3px rgba(255, 215, 0, 0.1),
    0 4px 12px rgba(0, 0, 0, 0.4);
}

.hive-card-premium:hover {
  box-shadow: 
    0 4px 16px rgba(255, 215, 0, 0.2),
    0 8px 24px rgba(0, 0, 0, 0.5);
}
```

#### **Card Anatomy**
```css
.hive-card-header {
  margin-bottom: var(--space-4);
  padding-bottom: var(--space-4);
  border-bottom: 1px solid var(--hive-surface-3);
}

.hive-card-title {
  font-size: var(--text-xl);
  font-weight: 600;
  color: var(--hive-text-primary);
  margin: 0 0 var(--space-2) 0;
}

.hive-card-description {
  font-size: var(--text-sm);
  color: var(--hive-text-secondary);
  margin: 0;
  line-height: 1.5;
}

.hive-card-content {
  color: var(--hive-text-primary);
  line-height: 1.6;
}

.hive-card-footer {
  margin-top: var(--space-6);
  padding-top: var(--space-4);
  border-top: 1px solid var(--hive-surface-3);
  display: flex;
  gap: var(--space-3);
  align-items: center;
}
```

---

### **3. HiveInput**

#### **Base Input Specifications**
```css
.hive-input {
  width: 100%;
  background: var(--hive-surface-2);
  border: 1px solid var(--hive-surface-3);
  border-radius: var(--radius-lg);
  padding: var(--space-3) var(--space-4);
  font-size: var(--text-base);
  color: var(--hive-text-primary);
  transition: all 150ms ease-out;
  outline: none;
}

.hive-input::placeholder {
  color: var(--hive-text-disabled);
}

.hive-input:focus {
  border-color: var(--hive-gold);
  box-shadow: 
    0 0 0 3px rgba(255, 215, 0, 0.1),
    0 1px 3px rgba(0, 0, 0, 0.2);
}

.hive-input:hover:not(:focus) {
  border-color: var(--hive-surface-3);
  background: var(--hive-surface-1);
}
```

#### **Input States**
```css
.hive-input-error {
  border-color: var(--hive-error);
  box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.1);
}

.hive-input-success {
  border-color: var(--hive-success);
  box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1);
}

.hive-input:disabled {
  background: var(--hive-surface-3);
  color: var(--hive-text-disabled);
  cursor: not-allowed;
}
```

#### **Floating Label Pattern**
```css
.hive-input-group {
  position: relative;
}

.hive-input-label {
  position: absolute;
  left: var(--space-4);
  top: var(--space-3);
  font-size: var(--text-base);
  color: var(--hive-text-disabled);
  transition: all 150ms ease-out;
  pointer-events: none;
  background: var(--hive-surface-2);
  padding: 0 var(--space-1);
}

.hive-input:focus + .hive-input-label,
.hive-input:not(:placeholder-shown) + .hive-input-label {
  top: -8px;
  font-size: var(--text-xs);
  color: var(--hive-gold);
}
```

---

### **4. HiveModal**

#### **Modal Specifications**
```css
.hive-modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(10, 10, 10, 0.8);
  backdrop-filter: blur(8px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  animation: modal-fade-in 200ms ease-out;
}

.hive-modal {
  background: var(--hive-surface-1);
  border: 1px solid var(--hive-surface-3);
  border-radius: var(--radius-2xl);
  padding: var(--space-8);
  max-width: 500px;
  width: calc(100% - var(--space-8));
  max-height: calc(100vh - var(--space-8));
  overflow-y: auto;
  box-shadow: 
    0 10px 25px rgba(0, 0, 0, 0.5),
    0 0 0 1px rgba(255, 255, 255, 0.05);
  animation: modal-zoom-in 200ms ease-out;
}

@keyframes modal-fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes modal-zoom-in {
  from { 
    opacity: 0; 
    transform: scale(0.95) translateY(-10px);
  }
  to { 
    opacity: 1; 
    transform: scale(1) translateY(0);
  }
}
```

---

## **CAMPUS-SPECIFIC COMPONENTS**

### **5. SpacePreview Card**

#### **Design Specifications**
```css
.hive-space-preview {
  position: relative;
  background: var(--hive-surface-1);
  border: 1px solid var(--hive-surface-3);
  border-radius: var(--radius-xl);
  padding: var(--space-6);
  transition: all 200ms ease-out;
  cursor: pointer;
  overflow: hidden;
}

.hive-space-preview:hover {
  transform: translateY(-2px);
  border-color: rgba(255, 215, 0, 0.3);
  box-shadow: 
    0 4px 12px rgba(0, 0, 0, 0.4),
    0 0 0 1px rgba(255, 215, 0, 0.1);
}

.hive-space-preview-header {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin-bottom: var(--space-4);
}

.hive-space-avatar {
  width: 48px;
  height: 48px;
  border-radius: var(--radius-lg);
  background: linear-gradient(135deg, var(--hive-gold), #FFB800);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  color: #000;
}

.hive-space-info h3 {
  font-size: var(--text-lg);
  font-weight: 600;
  color: var(--hive-text-primary);
  margin: 0 0 var(--space-1) 0;
}

.hive-space-info p {
  font-size: var(--text-sm);
  color: var(--hive-text-secondary);
  margin: 0;
}

.hive-space-members {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-top: var(--space-4);
  font-size: var(--text-sm);
  color: var(--hive-text-secondary);
}

.hive-space-members-count {
  color: var(--hive-gold);
  font-weight: 600;
}
```

### **6. EventCard**

#### **Design Specifications**
```css
.hive-event-card {
  background: var(--hive-surface-1);
  border: 1px solid var(--hive-surface-3);
  border-radius: var(--radius-xl);
  overflow: hidden;
  transition: all 200ms ease-out;
}

.hive-event-card:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
}

.hive-event-live {
  border-left: 4px solid var(--hive-gold);
  animation: pulse-glow 2s ease-in-out infinite alternate;
}

@keyframes pulse-glow {
  from { box-shadow: 0 0 5px rgba(255, 215, 0, 0.3); }
  to { box-shadow: 0 0 15px rgba(255, 215, 0, 0.5); }
}

.hive-event-header {
  padding: var(--space-6);
  border-bottom: 1px solid var(--hive-surface-3);
}

.hive-event-time {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  color: var(--hive-text-secondary);
  margin-bottom: var(--space-2);
}

.hive-event-live-badge {
  background: var(--hive-gold);
  color: #000;
  padding: var(--space-1) var(--space-2);
  border-radius: var(--radius-full);
  font-size: var(--text-xs);
  font-weight: 600;
  text-transform: uppercase;
}

.hive-event-title {
  font-size: var(--text-xl);
  font-weight: 600;
  color: var(--hive-text-primary);
  margin: 0 0 var(--space-2) 0;
}

.hive-event-location {
  font-size: var(--text-sm);
  color: var(--hive-text-secondary);
  margin: 0;
}

.hive-event-footer {
  padding: var(--space-4) var(--space-6);
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.hive-event-rsvp {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
}

.hive-event-rsvp-count {
  color: var(--hive-gold);
  font-weight: 600;
}
```

---

## **ANIMATION SPECIFICATIONS**

### **Easing Functions**
```css
:root {
  --ease-out-quad: cubic-bezier(0.25, 0.46, 0.45, 0.94);
  --ease-out-quart: cubic-bezier(0.165, 0.84, 0.44, 1);
  --ease-spring: cubic-bezier(0.68, -0.55, 0.265, 1.55);
  --ease-smooth: cubic-bezier(0.4, 0, 0.2, 1);
}
```

### **Standard Durations**
```css
:root {
  --duration-fast: 150ms;     /* Button presses, hovers */
  --duration-normal: 200ms;   /* Card animations */
  --duration-slow: 300ms;     /* Modal entrances */
  --duration-slower: 400ms;   /* Page transitions */
}
```

### **Loading States**
```css
@keyframes skeleton-loading {
  0% { background-position: -200px 0; }
  100% { background-position: calc(200px + 100%) 0; }
}

.hive-skeleton {
  background: linear-gradient(
    90deg,
    var(--hive-surface-2) 0px,
    var(--hive-surface-3) 40px,
    var(--hive-surface-2) 80px
  );
  background-size: 200px 100%;
  animation: skeleton-loading 1.5s infinite linear;
}
```

---

## **RESPONSIVE SPECIFICATIONS**

### **Breakpoints**
```css
:root {
  --breakpoint-sm: 640px;
  --breakpoint-md: 768px;
  --breakpoint-lg: 1024px;
  --breakpoint-xl: 1280px;
}
```

### **Mobile-First Adjustments**
```css
/* Touch targets */
@media (max-width: 640px) {
  .hive-button {
    min-height: 44px;
    padding: var(--space-3) var(--space-4);
  }
  
  .hive-card {
    padding: var(--space-4);
  }
  
  .hive-modal {
    margin: var(--space-4);
    border-radius: var(--radius-xl);
  }
}
```

---

## **ACCESSIBILITY SPECIFICATIONS**

### **Focus Management**
```css
.hive-focus-ring {
  outline: 2px solid var(--hive-gold);
  outline-offset: 2px;
  border-radius: var(--radius-sm);
}

/* Hide outline for mouse users */
.js-focus-visible :focus:not(.focus-visible) {
  outline: none;
}
```

### **Reduced Motion**
```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## **IMPLEMENTATION PRIORITY**

### **Phase 1: Foundation (Week 1)**
1. Design tokens setup
2. HiveButton (all variants)
3. HiveCard (base + glass)
4. HiveInput (base + states)

### **Phase 2: Campus Components (Week 2)**
1. SpacePreview card
2. EventCard
3. HiveModal
4. Loading states

### **Phase 3: Polish & Performance (Week 3)**
1. Animation refinements
2. Accessibility improvements
3. Mobile optimizations
4. Documentation

---

*This specification document provides the exact implementation details needed to build a performant, accessible, and distinctly HIVE-branded design system.* 