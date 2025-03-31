# HIVE UI Theme Documentation

## Overview

HIVE UI implements a sophisticated design system with a dark, premium aesthetic characterized by pure black backgrounds, crisp white text, and gold accents. The theme follows an iOS-inspired design language with a focus on glassmorphism effects, subtle animations, and haptic feedback.

## Color Palette

The color palette is defined in `app_colors.dart` and consists of carefully selected colors for a consistent dark theme with gold accents.

### Primary Colors

- **Black** (`#000000`): The primary background color for the application
- **White** (`#FFFFFF`): Primary text color and secondary button color
- **Gold** (`#FFD700`): Accent color for highlighting, focus states, and branding

### Background Colors

- **Grey600** (`#131313`): Slightly lighter than pure black, used for layered surfaces
- **Grey700** (`#0A0A0A`): Very dark grey, used for subtle differentiation
- **Grey800** (`#080808`): Nearly black, used for cards and elevated surfaces
- **Surface** (`#050505`): Almost pure black, used for main surfaces

### Text Colors

- **TextPrimary** (`#FFFFFF`): Primary text color (white)
- **TextSecondary** (`white70`): Secondary text color for less emphasis
- **TextTertiary** (`white54`): Tertiary text color for even less emphasis
- **TextDisabled** (`white38`): Disabled text color

### Status Colors

- **Error** (`Colors.red`): Used for error states and negative actions
- **Success** (`Colors.green`): Used for success states and positive actions
- **Warning** (`Colors.orange`): Used for warning states and cautionary actions
- **Info** (`#2196F3`): Used for informational states and neutral actions

### Social Proof Colors

- **Attending** (`#00C853`): Green color used for RSVP confirmations
- **FriendsAttending** (`#006AFF`): Blue color used to highlight friend attendance

## Typography

The typography system is defined in `app_theme.dart` and uses Google Fonts for a modern and clean look.

### Font Families

- **Outfit**: Used for headings, titles, and display text
- **Inter**: Used for body text, captions, and UI elements

### Text Styles

#### Display Styles

- **DisplayLarge**: 32px, Outfit, Bold (large headlines)
- **DisplayMedium**: 24px, Outfit, Bold (medium headlines)
- **DisplaySmall**: 20px, Outfit, Bold (small headlines)

#### Heading Styles

- **HeadlineSmall**: 18px, Outfit, SemiBold (section headers)

#### Title Styles

- **TitleMedium**: 16px, Outfit, SemiBold (emphasized text)
- **TitleSmall**: 14px, Outfit, SemiBold (small emphasized text)

#### Body Styles

- **BodyLarge**: 16px, Inter, Medium (primary body text)
- **BodyMedium**: 14px, Inter, Medium (secondary body text)
- **BodySmall**: 12px, Inter, Medium (captions and helpers)

#### Label Styles

- **LabelLarge**: 16px, Inter, SemiBold (button text)
- **LabelMedium**: 14px, Inter, Medium (small button text)
- **LabelSmall**: 12px, Inter, Medium (small labels)

## Spacing

The spacing system uses a consistent scale to create rhythm and hierarchy in the UI.

- **Spacing0**: 0px
- **Spacing2**: 2px
- **Spacing4**: 4px
- **Spacing8**: 8px
- **Spacing12**: 12px
- **Spacing16**: 16px
- **Spacing20**: 20px
- **Spacing24**: 24px
- **Spacing32**: 32px
- **Spacing40**: 40px
- **Spacing48**: 48px
- **Spacing52**: 52px
- **Spacing56**: 56px
- **Spacing64**: 64px

## Border Radius

The border radius system creates a consistent roundness across UI elements.

- **RadiusNone**: 0px
- **RadiusXs**: 4px
- **RadiusSm**: 8px
- **RadiusMd**: 12px
- **RadiusLg**: 16px
- **RadiusXl**: 20px
- **RadiusXxl**: 28px
- **RadiusFull**: 999px (fully rounded)

## Glassmorphism

HIVE UI extensively uses glassmorphism effects for a premium, modern feel. The glassmorphism system is defined in `glassmorphism_guide.dart`.

### Blur Values

- **HeaderBlur**: 20
- **CardBlur**: 15
- **ModalBlur**: 25
- **BottomSheetBlur**: 20
- **DialogBlur**: 20
- **ToastBlur**: 10

### Glass Opacity Values

- **StandardGlassOpacity**: 0.1
- **LightGlassOpacity**: 0.08
- **ModalGlassOpacity**: 0.15
- **HeaderGlassOpacity**: 0.12
- **CardGlassOpacity**: 0.08

### Border Values

- **BorderNone**: 0.0
- **BorderThin**: 1.0
- **BorderStandard**: 1.5
- **BorderThick**: 2.0

## Icons

HIVE UI uses a combination of Material Icons and Hugeicons for a consistent icon language.

### Hugeicons

Defined in `huge_icons.dart`, these are custom icons from the Hugeicons package with a consistent rounded style.

- Basic UI icons: home, message, settings, profile, etc.
- Custom named icons: spaces, groups, business, academic, etc.

### App Icons

Defined in `app_icons.dart`, this centralizes all icon usage across the app.

- Navigation icons: home, back, forward, up, down
- Messaging icons: message, messageSend, messageThread, etc.
- Action icons: close, plusCircle, camera
- Common UI icons: settings, notification, like, etc.

## iOS-Inspired Design

HIVE UI incorporates iOS-inspired design elements defined in `ios_style.dart`.

### iOS-Style Components

- Action sheets
- Context menus
- Bottom sheets
- Modal dialogs
- Navigation bars
- Tab bars

### Animation and Transitions

- Page transitions with spring physics
- Button press animations
- Modal presentation animations
- Shared element transitions

## Standardized Components

The UI library includes standardized components built on top of the theme system:

### Buttons

- Primary buttons: Gold background with black text
- Secondary buttons: Transparent with gold border and text
- Tertiary buttons: Transparent with white border and text
- Text buttons: Text-only buttons without background

### Input Fields

- Text inputs with consistent styling
- Search fields with search icon
- Password fields with visibility toggle
- Textarea fields for multi-line input

### Cards

- Regular cards for content containers
- Social cards for user-generated content
- Profile cards for user information
- Interactive cards with hover/press states

## Usage Guidelines

### Color Usage

- Use black for primary backgrounds
- Use gold sparingly as an accent for important elements
- Use white for primary text and important actions
- Use status colors only for their intended meaning

### Typography Usage

- Use Outfit for headings and important text
- Use Inter for body text and UI elements
- Maintain the type scale for hierarchical clarity
- Avoid using too many different text styles

### Glassmorphism Usage

- Use glassmorphism for elevated UI elements
- Maintain consistency in blur and opacity values
- Combine with subtle borders for better definition
- Avoid overusing glassmorphism which can reduce contrast

### Animation Guidelines

- Keep animations subtle and purposeful
- Use consistent durations (300-400ms standard)
- Add haptic feedback for important interactions
- Ensure animations don't impede usability 