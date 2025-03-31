# HIVE System Documentation

## 1. System Overview

HIVE is a premium social networking platform specifically designed for university students. It serves as a centralized hub for campus life, connecting students with clubs, organizations, events, and each other in a sleek, counter-culture environment outside of official university channels.

### 1.1 Core Purpose

HIVE creates a digital underground for student life with Apple-level polish but a rebellious spirit. The platform empowers students to:

- Discover campus events and activities
- Connect with clubs and organizations
- Build meaningful relationships with peers
- Access exclusive campus resources
- Organize and promote student-led initiatives
- Create a personalized university experience

### 1.2 Guiding Principles

1. **Counter-Culture Premium**: Maintain a high-end aesthetic with counter-culture elements
2. **Student-First**: Design all features with student needs as the primary focus
3. **Frictionless Experience**: Minimize UI friction and maximize intuitive interactions
4. **Exclusive Digital Underground**: Create a premium space outside university oversight
5. **Adaptive Community**: Build features that evolve with student behavior

## 2. Information Architecture

### 2.1 User System

#### 2.1.1 User Tiers
- **Public**: Basic access for non-university emails
- **Verified**: Enhanced access for confirmed university emails (auto-detected)
- **Verified Plus**: Premium tier with exclusive features

#### 2.1.2 Profile Data Structure
- **Core Identity**: Name, username, profile image
- **Academic Info**: Year, field of study, residence
- **Interests**: Selected from categorized options (5-10 required)
- **Activity**: Event history, club memberships, interactions
- **Connections**: Friends, followers, following

### 2.2 Content Organization

#### 2.2.1 Event Hierarchy
- **Event Types**: Club, campus-wide, academic, social
- **Event Status**: Upcoming, ongoing, past
- **Event Visibility**: Public, members-only, invitation-only
- **Event Data**: Date, time, location, description, organizer, attendees

#### 2.2.2 Club/Organization Structure
- **Club Types**: Academic, social, athletic, cultural, professional
- **Membership Levels**: Member, admin, owner
- **Club Data**: Name, description, image, member count, events

#### 2.2.3 Space System
- **Space Types**: Study, social, creative, collaborative
- **Space Features**: Activities, resources, capacity
- **Space Data**: Location, hours, amenities, current users

#### 2.2.4 Feed Content Types
- **Events**: From followed clubs, recommended
- **Activities**: From connected users
- **Announcements**: From followed organizations
- **Content Cards**: Personalized recommendations and tips

## 3. Current Implementation

### 3.1 Completed Features

#### 3.1.1 Authentication Flow ✅
- Landing page with animated slogan
- Email-based sign-in and account creation
- Automatic verification for buffalo.edu emails
- Password reset functionality
- Email persistence between signup and onboarding
- Placeholder authentication (prepared for Firebase integration)

#### 3.1.2 Onboarding Process ✅
- Multi-stage profile completion flow
- Selection of academic information (year, field, residence)
- Interest selection with search functionality (5-10 interests)
- Account tier determination based on email domain
- Club selection and discovery

#### 3.1.3 Main Feed ✅
- Personalized "For You" tab
- HIVELAB content tab
- Infinite scrolling with pagination
- Modern, collapsible header
- Search functionality for events
- Clean UI focused on content

#### 3.1.4 Event System ✅
- Event details view with rich information
- RSVP functionality
- Calendar integration
- Image optimization
- Social sharing

#### 3.1.5 Profile System ✅
- Dynamic profile view
- Activity, Spaces, Events, and Friends tabs
- Profile image management
- Bio and interests display
- Interactive elements

### 3.2 In-Progress Features

#### 3.2.1 Club Management 🔄
- Club profiles and discovery
- Membership functionality
- Club events creation
- Member management

#### 3.2.2 Messaging System 🔄
- Direct messaging between users
- Group chat support
- Media sharing capabilities
- Read receipts and typing indicators

#### 3.2.3 Spaces 🔄
- Space interaction functionality
- Space discovery
- Metrics visualization

### 3.3 Technical Implementation

#### 3.3.1 Architecture
- **Clean Architecture**: Separation of concerns with presentation, domain, and data layers
- **State Management**: Riverpod providers for reactive state handling
- **Navigation**: GoRouter for standardized routing
- **UI Components**: Modular, reusable components following design system
- **Animation**: Consistent animation timings and curves across the app
- **Haptic Feedback**: Contextual haptic responses for interactions

#### 3.3.2 Brand Aesthetic Implementation
- **Color Scheme**: Pure black backgrounds (#000000) with gold accents (#FFD700)
- **Typography**: Clean, minimal typography with strategic emphasis
- **Styling Contexts**:
  - Standard: Apple-inspired premium feel (default)
  - Rebellion: Counter-culture enhanced for new features
  - Secret: Hidden/experimental features styling
- **Glassmorphism**: Frosted glass effects for cards, dialogs, and headers
- **Animation**: Purpose-driven animation with consistent timing (400ms standard)

## 4. User Flows

### 4.1 New User Experience
1. **Landing Page**: Users see the HIVE logo with animated slogan
2. **Account Creation**: Email and password entry with buffalo.edu verification
3. **Onboarding**:
   - Profile information entry (name, academic info)
   - Interest selection (minimum 5, maximum 10)
   - Account tier determination
   - Optional club selection
4. **Feed Introduction**: First view of personalized feed
5. **Discovery Phase**: Exploring events and spaces

### 4.2 Returning User Experience
1. **Sign In**: Email/password or Google authentication
2. **Feed View**: Personalized feed with relevant events
3. **Engagement**: RSVP to events, interact with content
4. **Profile**: View and manage personal profile
5. **Navigation**: Move between feed, spaces, messaging, and profile

### 4.3 Event Discovery and RSVP
1. **Feed Browsing**: Scroll through personalized events
2. **Event Selection**: Tap on interesting event
3. **Details View**: View comprehensive event information
4. **RSVP Process**: Mark attendance and add to calendar
5. **Sharing**: Share event with friends or social media

## 5. Technical Architecture

### 5.1 Code Organization

```
lib/
  ├── components/      # Reusable UI components
  ├── docs/            # Documentation and guides
  ├── extensions/      # Extension methods
  ├── features/        # Feature-specific modules
  ├── models/          # Data models
  ├── pages/           # Main screens
  ├── providers/       # Riverpod state providers
  ├── services/        # Business logic services
  ├── theme/           # App theme and styling
  ├── tools/           # Utility tools
  ├── utils/           # Helper functions
  └── widgets/         # Basic UI building blocks
```

### 5.2 State Management

HIVE implements Riverpod for state management with these patterns:

- **StateProvider**: Simple, single-value state
- **StateNotifierProvider**: Complex state with operations
- **FutureProvider**: Async data loading with error handling
- **AsyncValue**: Standardized loading/error/data states

### 5.3 UI Component System

The app implements a cohesive component system with:

- **HiveButton**: Standardized buttons with contextual styling
- **HiveCard**: Consistent card components with glassmorphism
- **FeedComponents**: Specialized components for feed display
- **ProfileWidgets**: Profile-specific UI elements
- **AnimatedComponents**: Components with built-in animations

## 6. Development Status and Roadmap

### 6.1 Completed Milestones
- ✅ Authentication UI and flow
- ✅ User onboarding process
- ✅ Main feed with personalization
- ✅ Event details and RSVP functionality
- ✅ Profile system implementation
- ✅ Brand aesthetic foundation

### 6.2 Current Development Focus
- 🔄 Club management system
- 🔄 Refactoring large files (onboarding_profile.dart, main_feed.dart)
- 🔄 Standardizing card components
- 🔄 Implementing consistent error handling

### 6.3 Upcoming Features
1. **RSS Integration**: Connect RSS service to event display
2. **Club Creation Flow**: Complete with member management
3. **Messaging Enhancement**: Chat functionality with media sharing
4. **Profile Completion**: Add activity history and achievements
5. **Spaces Implementation**: Complete space interaction functionality

### 6.4 Technical Debt and Refactoring
1. Breaking down large files:
   - onboarding_profile.dart (3279 lines)
   - club_profile_page.dart (1543 lines)
   - main_feed.dart (1208 lines)
   - spaces.dart (902 lines)
2. Standardizing component usage
3. Implementing consistent error handling
4. Optimizing image loading and caching

## 7. Design Philosophy

### 7.1 Counter-Culture Premium Aesthetic

HIVE's distinctive "Counter-Culture Premium" aesthetic combines:

1. **Premium Minimalism**:
   - Deep black canvas (#000000)
   - Purposeful whitespace
   - Refined animations (400ms standard)
   - Haptic integration
   - 30px rounded corners for primary elements

2. **Strategic Rebellion**:
   - Gold accent color (#FFD700)
   - Context-driven styling
   - Unveiling interactions
   - Sharp-edge variants for rebellion contexts

3. **Digital Underground**:
   - Student-owned visual language
   - Feature discovery through exploration
   - Confident transitions
   - Community-focused visual elements

### 7.2 Contextual Design System

HIVE implements three style contexts:

1. **Standard Style**:
   - Pure black backgrounds
   - White text with gold accents
   - 30px rounded corners
   - Standard animation (400ms)
   - Subtle glassmorphism

2. **Rebellion Style**:
   - Pure black backgrounds
   - Enhanced gold accents
   - Sharp corners (0px radius)
   - Quicker animation (250-300ms)
   - Enhanced glassmorphism

3. **Secret Style**:
   - Pure black backgrounds
   - Maximum gold highlights
   - Mix of sharp and minimal rounding
   - Dramatic animation (200-400ms)
   - Maximum glassmorphism

## 8. Future Considerations

### 8.1 Scalability Planning
- Firebase integration for authentication and real-time data
- Backend API development for club and event management
- Analytics implementation for feature optimization
- Performance optimizations for larger user base

### 8.2 Feature Expansion Ideas
- Event ticketing and payment integration
- Enhanced media sharing in messaging
- Study group formation and management
- Campus resource booking system
- Academic calendar integration
- Campus map with real-time information

### 8.3 Technical Evolution
- Component library extraction for reusability
- Automated testing implementation
- CI/CD pipeline setup
- Performance monitoring and optimization
- Accessibility improvements

## 9. Conclusion

HIVE represents a sophisticated platform for enhancing university student life through a premium digital experience. With its counter-culture aesthetic, clean architecture, and student-centered design, the app creates a unique space for campus community building. The current implementation provides a solid foundation, while the roadmap addresses remaining features and technical optimizations needed for a complete, production-ready application. 

## Core Systems

- User authentication and profile management
- Club spaces and discovery
- Event calendar and RSVP system
- Messaging and communications
- Activity and social feeds 