# HIVE UI - Club Space Design System

This document outlines the design system for Club Spaces within the HIVE UI platform. It includes guidelines, component descriptions, and integration instructions to maintain consistency across the application.

## Card-Style Drop-Down Header

The new Club Space design features a card-style drop-down header that serves as the primary identity element for clubs and organizations. This header has been standardized into a reusable component `ClubHeaderCard`.

### Design Characteristics

- **Depth and Elevation**: The card uses subtle shadows and borders to create a "dropping down" appearance that elevates it from the content below
- **Glassmorphism Effects**: Utilizes semi-transparent backgrounds with subtle blur effects
- **Gold Accents**: Maintains the HIVE brand aesthetic with gold accent elements
- **Consistent Typography**: Uses the Outfit font family with standardized weights and sizes
- **Responsive Layout**: Adapts to different screen sizes while maintaining visual hierarchy

### Components

1. **ClubHeaderCard**
   - Located at: `lib/features/clubs/presentation/components/club_header_component.dart`
   - A complete header card with club information, stats, and action buttons
   - Supports both Club and Space data models
   - Includes callbacks for interactions (follow, message, etc.)

## Implementation Guide

### Using the ClubHeaderCard Component

```dart
ClubHeaderCard(
  club: clubObject,  // The club to display (or use space)
  isFollowing: false,  // Whether the user is following this club
  followerCount: 125,  // Number of followers
  eventCount: 3,  // Number of events
  mediaCount: 24,  // Number of media items
  chatUnlocked: true,  // Whether chat is available
  onFollowPressed: () {
    // Handle follow button press
  },
  onMessagePressed: () {
    // Handle message button press
  },
  onChatLockedMessage: () {
    // Show message when chat is locked
  },
)
```

### Integration Points

To maintain consistency across the platform, the ClubHeaderCard should be integrated at these key points:

1. **Club Space Page**: Main detail view for clubs
2. **Organization Profiles**: For university organizations
3. **Club Preview Screens**: When viewing club details before joining
4. **Club Management Screens**: For club administrators

### Style Guidelines

When integrating the Club Space design elements, adhere to these guidelines:

1. **Colors**
   - Use the provided `AppColors` class for consistency
   - Main background: `AppColors.black`
   - Card background: `Colors.grey[900]!.withOpacity(0.3)`
   - Accent color: `AppColors.gold`

2. **Spacing**
   - Maintain consistent padding of 16-20px around card edges
   - Use 8-12px spacing between internal elements
   - Allow breathing room with 24px margin below the header

3. **Typography**
   - Club name: 22px, weight 600
   - Description: 14px, weight 400, 0.7 opacity
   - Stats: 18px (value), 12px (label)
   - Button text: 15px, weight 600

4. **Iconography**
   - Club icon: 34px, centered in 64x64px container
   - Use outlined variants for secondary icons
   - Gold coloring for primary icons, white with reduced opacity for secondary

## Tile Design System

The Club Space uses a modular tile-based layout below the header. These tiles follow a consistent design language:

### Tile Characteristics

- Rounded corners (16px radius)
- Semi-transparent backgrounds with subtle borders
- Consistent header style with icon + title
- Clear call-to-action indicators
- Touch feedback with haptics

### Common Tile Types

1. **Events Tile**
   - Shows upcoming event preview
   - "View All Events" action button

2. **Pinned Message Tile**
   - Displays important announcements
   - Gold accent for the pin icon

3. **Live Chat Tile**
   - Shows recent messages or locked state
   - Clear unlock requirements when locked

4. **Gallery Tile**
   - Image previews or locked state
   - Clear unlock requirements when locked

5. **External Links Tile**
   - Social media and website links
   - Interactive buttons with proper padding

6. **About Tile**
   - Key information about the club
   - Contact and meeting details

### Layout Guidelines

- Use responsive grid layouts (StaggeredGrid)
- Adjust column count based on screen size
- Consistent spacing between tiles (8px)
- Priority ordering: Events > Pinned > Chat > Gallery > Links > About

## Animation Guidelines

For a polished user experience, animations should be consistent:

- Use staggered animations for grid items
- Standard duration: 400ms
- Use curves: Ease or easeOutQuart for most animations
- Include haptic feedback for important interactions

## Accessibility Considerations

- Maintain readable contrast ratios
- Include text scaling support
- Ensure interactive elements have sufficient touch targets (48px minimum)
- Add semantics labels for screen readers

## Future Enhancements

Planned enhancements for the Club Space design system:

1. Enhanced dark mode optimization
2. Additional tile types for specialized club content
3. Advanced animation transitions between states
4. Analytics integration for engagement tracking
5. Extended theming options for club customization

## Getting Help

For questions about implementing this design system, contact the HIVE UI design team or refer to the example implementations in the codebase. 