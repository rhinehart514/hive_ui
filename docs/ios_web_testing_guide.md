# iOS Visual Testing on Web - Quick Start Guide

This guide explains how to use the cross-platform visual testing tools we've implemented to ensure consistent visual appearance between iOS and web versions of HIVE UI.

## Prerequisites

- Flutter SDK (latest stable version)
- Access to both iOS devices/simulators and a web browser
- Required packages (see pubspec.yaml)

## Running Visual Tests

### Step 1: Capture iOS Baseline

First, capture the baseline screenshots from iOS:

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=test/visual_comparison_test.dart \
  -d <ios-device-id>
```

This will generate baseline screenshots for all core UI components in the temporary directory.

### Step 2: Capture Web Renders

Next, capture the same components on web:

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=test/visual_comparison_test.dart \
  -d web-server
```

### Step 3: Review Comparison Results

The test will automatically compare iOS and web renders and generate diff images for components that differ by more than 5%.

Check the console output for:
- Paths to generated images
- Percentage differences for each component
- Locations of difference visualizations

## Manual Browser Testing

For ad-hoc testing of iOS visuals on web:

1. Launch the app in web mode:
   ```bash
   flutter run -d chrome
   ```

2. Open Chrome DevTools (F12)
3. Toggle device toolbar (Ctrl+Shift+M)
4. Select an iOS device preset (e.g., iPhone 13)
5. Verify visual appearance matches iOS design specifications

## Common Issues and Solutions

### Font Rendering Differences

- Inter font may render differently across platforms
- Solution: Use platform-specific font weights or custom font rendering

### Blur Effects

- Glass/blur effects often vary between platforms
- Solution: Platform-specific blur implementations in `PlatformAwareWidget`

### Color Inconsistencies

- Colors may appear slightly different due to rendering engines
- Solution: Use platform color correction or slight adjustments

## Scheduled Testing

Incorporate visual testing into your workflow:

- Run tests after significant UI changes
- Include in CI/CD pipeline for automated verification
- Schedule bi-weekly visual consistency audits

## Further Reading

For more detailed information on cross-platform visual testing, see:
- [Cross-Platform Visual Testing Guide](cross_platform_visual_testing.md)
- [HIVE Core Design Principles](cursor_rules/01-core-design-principles.mdc)
- [Component Styling Guide](cursor_rules/02-component-styling.mdc) 