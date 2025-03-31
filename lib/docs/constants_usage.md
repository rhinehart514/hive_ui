# HIVE UI Constants

This document outlines how constants are used throughout the application to ensure consistency.

## Interest Options

The interests list is centralized in `lib/constants/interest_options.dart`. This enables consistent interest options across different features of the application.

### Example Usage

```dart
import 'package:hive_ui/constants/interest_options.dart';

// Get the full list of interests
final interests = InterestOptions.options;

// Use in widgets
Wrap(
  children: InterestOptions.options.map((interest) {
    return Chip(
      label: Text(interest),
      // ... additional styling
    );
  }).toList(),
)
```

## Year Options

The academic year options are centralized in `lib/constants/year_options.dart`. This ensures consistent year options across the app.

```dart
import 'package:hive_ui/constants/year_options.dart';

// Get the full list of year options
final years = YearOptions.options;
```

## Major Options

The majors/fields of study are centralized in `lib/constants/major_options.dart`. This maintains consistency between onboarding and profile editing.

```dart
import 'package:hive_ui/constants/major_options.dart';

// Get the full list of major options
final majors = MajorOptions.options;
```

## Residence Options

Residence options are centralized in `lib/constants/residence_options.dart`.

```dart
import 'package:hive_ui/constants/residence_options.dart';

// Get the full list of residence options
final residences = ResidenceOptions.options;
```

### Benefits of Centralization

1. **Consistency** - Ensures the same options are available everywhere
2. **Maintainability** - Updates to option lists only need to happen in one place
3. **Reduced Duplication** - Prevents multiple copies of the same data

### Key Components Using Shared Constants

- **OnboardingProfilePage** - Uses all shared constants for user onboarding
- **InlineProfileEditor** - Uses shared constants for profile editing
- **InterestSelector Component** - Reusable component for interest selection

### Adding New Options

When adding new options to any of these lists, always update the central constants files rather than adding them to individual components.

## Other Shared Constants

In addition to the predefined options lists, other constants that should be shared across the application should follow the same pattern:

1. Create a dedicated class in the `lib/constants/` directory
2. Use static const fields for the values
3. Add a private constructor to prevent instantiation
4. Import and use throughout the application 