# HiveAppBar Integration Guide

This guide explains how to integrate the new `HiveAppBar` component throughout the HIVE platform to ensure consistent UI and user experience across all screens.

## Table of Contents

1. [Why Use HiveAppBar](#why-use-hiveappbar)
2. [Basic Integration Steps](#basic-integration-steps)
3. [Integration Patterns by Screen Type](#integration-patterns-by-screen-type)
4. [Migration Checklist](#migration-checklist)
5. [Handling Special Cases](#handling-special-cases)
6. [Troubleshooting](#troubleshooting)

## Why Use HiveAppBar

The `HiveAppBar` component provides several benefits:

- **Consistent UX**: Same behavior and appearance across all screens
- **Glassmorphic design**: Follows HIVE's premium design aesthetic
- **Adaptive layout**: Works properly on iOS and Android
- **Scroll behavior**: Consistent animation when scrolling
- **Integrated search**: Built-in search functionality
- **Tab support**: Easy integration with tab-based navigation

## Basic Integration Steps

### 1. Add Import

```dart
import 'package:hive_ui/widgets/hive_app_bar.dart';
```

### 2. Replace Existing App Bar

Replace this:

```dart
appBar: AppBar(
  title: Text('Screen Title'),
  // Other properties...
),
```

With this:

```dart
appBar: HiveAppBar(
  title: 'Screen Title',
  // Other properties as needed...
),
```

### 3. Check for Required Dependencies

The `HiveAppBar` uses `AppColors` from the theme, so make sure to add:

```dart
import 'package:hive_ui/theme/app_colors.dart';
```

## Integration Patterns by Screen Type

### Standard Screens

For basic screens with just a title and back button:

```dart
appBar: HiveAppBar(
  title: 'Settings',
  showBackButton: true,
),
```

### Screens with Custom Actions

```dart
appBar: HiveAppBar(
  title: 'Group Members',
  actions: [
    IconButton(
      icon: const Icon(Icons.person_add, color: AppColors.textPrimary),
      onPressed: () {
        // Add member action
      },
    ),
  ],
),
```

### Screens with Tabs

```dart
appBar: HiveAppBar(
  title: 'Events',
  style: HiveAppBarStyle.withTabs,
  tabBar: TabBar(
    controller: _tabController,
    labelColor: AppColors.gold,
    unselectedLabelColor: AppColors.textTertiary,
    indicatorColor: AppColors.gold,
    indicatorWeight: 3,
    indicatorSize: TabBarIndicatorSize.label,
    tabs: const [
      Tab(text: 'Upcoming'),
      Tab(text: 'Past'),
      Tab(text: 'My Events'),
    ],
  ),
),
```

### Screens with Search

```dart
appBar: HiveAppBar(
  title: 'Discover',
  style: HiveAppBarStyle.withSearch,
  showSearchButton: true,
  searchController: _searchController,
  searchFocusNode: _searchFocusNode,
  onSearchChanged: (query) {
    // Handle search
    performSearch(query);
  },
),
```

### Screens with Both Tabs and Search

These are typically complex screens like Spaces or Feed:

```dart
appBar: HiveAppBar(
  title: 'Spaces',
  style: HiveAppBarStyle.withTabsAndSearch,
  showSearchButton: true,
  searchController: _searchController,
  searchFocusNode: _searchFocusNode,
  onSearchChanged: (query) {
    // Handle search
    ref.read(spaceSearchQueryProvider.notifier).state = query;
  },
  onSearchClosed: () {
    // Handle search closed
    ref.read(spaceSearchQueryProvider.notifier).state = '';
  },
  tabBar: TabBar(
    controller: _tabController,
    labelColor: AppColors.gold,
    unselectedLabelColor: AppColors.textTertiary,
    indicatorColor: AppColors.gold,
    tabs: const [
      Tab(text: 'Explore'),
      Tab(text: 'My Spaces'),
    ],
  ),
),
```

### Scrollable Screens

For screens where the app bar should respond to scrolling:

```dart
// Create a single scroll controller for both the app bar and content
final ScrollController _scrollController = ScrollController();

// Use it in both places
appBar: HiveAppBar(
  title: 'Feed',
  scrollable: true,
  scrollController: _scrollController,
),
body: ListView.builder(
  controller: _scrollController,
  // ...
),
```

### Transparent App Bar for Media Screens

For image viewers, video screens, or other media-focused screens:

```dart
appBar: HiveAppBar(
  title: 'Photo',
  style: HiveAppBarStyle.transparent,
  showBottomBorder: false,
),
```

## Migration Checklist

When integrating HiveAppBar into an existing screen, check for:

- [x] Title text style conversion
- [x] Back button functionality preservation
- [x] Action buttons conversion
- [x] Tab bar integration if present
- [x] Search functionality integration if present
- [x] Scroll behavior coordination if needed
- [x] Special backgroundColor or other custom styling

## Handling Special Cases

### Custom Title Widgets

If you need a custom title widget instead of just text:

```dart
appBar: AppBar(
  title: Row(
    children: [
      Icon(Icons.star, color: AppColors.gold),
      Text('VIP Access'),
    ],
  ),
)
```

Replace with:

```dart
appBar: HiveAppBar(
  title: 'VIP Access',
  leading: Icon(Icons.star, color: AppColors.gold),
),
```

Or for more complex cases, use a custom `leading` widget.

### Dynamic Titles

If your title changes based on state:

```dart
appBar: HiveAppBar(
  title: _isEditMode ? 'Edit Profile' : 'Profile',
),
```

### Bottom Sheets and Dialogs

For modal screens, use the transparent style:

```dart
appBar: HiveAppBar(
  title: 'Select Option',
  style: HiveAppBarStyle.transparent,
  showBottomBorder: false,
),
```

## Troubleshooting

### 1. Wrong Import Path

If you see an error about `HiveAppBar` not being found, check your import path:

```dart
import 'package:hive_ui/widgets/hive_app_bar.dart';
```

### 2. Missing Style Enum

If you see an error about `HiveAppBarStyle` not being defined, make sure you're importing the correct file and not using a local copy.

### 3. Search Not Working

Ensure you're providing all required search-related props:

```dart
searchController: _searchController,  // Required
searchFocusNode: _searchFocusNode,    // Required
onSearchChanged: _handleSearch,       // Required
showSearchButton: true,               // Required
```

### 4. Scroll Animation Issues

If scroll animation doesn't work:
- Ensure you're using the same `ScrollController` for both the app bar and the scrollable content
- Set `scrollable: true` on the HiveAppBar

### 5. Incorrect Styles on iOS/Android

The HiveAppBar should look consistent on both platforms. If there are discrepancies:
- Check if you're setting platform-specific styles elsewhere
- Ensure your theme is properly applied 