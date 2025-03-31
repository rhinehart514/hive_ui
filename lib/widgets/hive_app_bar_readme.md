# HiveAppBar Component

A consistent app bar component for the HIVE UI platform that provides a unified experience across iOS and Android. This component supports various features like scrolling behavior, search expansion, tab bar integration, and follows the HIVE UI glassmorphic design aesthetic.

## Features

- **Consistent styling** with platform's glassmorphic design
- **Multiple app bar styles** (standard, tabs, search, tabs with search, transparent)
- **Scroll-aware behavior** that animates based on scroll position
- **Search functionality** with expandable search field
- **Tab integration** for multi-tab interfaces
- **Adaptive height** based on content (subtitle, tabs, search)
- **Mobile-responsive design** works across iOS and Android

## Usage

Import the component:

```dart
import 'package:hive_ui/widgets/hive_app_bar.dart';
```

### Basic Usage

```dart
Scaffold(
  appBar: HiveAppBar(
    title: 'My Profile',
    showBackButton: true,
  ),
  body: ...
)
```

### With Subtitle

```dart
HiveAppBar(
  title: 'Spaces',
  subtitle: 'Discover communities',
  showBackButton: false,
)
```

### With Tabs

```dart
HiveAppBar(
  title: 'Events',
  style: HiveAppBarStyle.withTabs,
  tabBar: TabBar(
    controller: _tabController,
    labelColor: AppColors.gold,
    unselectedLabelColor: AppColors.textTertiary,
    indicatorColor: AppColors.gold,
    tabs: const [
      Tab(text: 'Upcoming'),
      Tab(text: 'Past'),
      Tab(text: 'My Events'),
    ],
  ),
)
```

### With Search

```dart
HiveAppBar(
  title: 'Discover',
  style: HiveAppBarStyle.withSearch,
  showSearchButton: true,
  searchController: _searchController,
  searchFocusNode: _searchFocusNode,
  onSearchChanged: (query) {
    // Handle search query
  },
)
```

### With Tabs and Search

```dart
HiveAppBar(
  title: 'Explore',
  style: HiveAppBarStyle.withTabsAndSearch,
  showSearchButton: true,
  searchController: _searchController,
  searchFocusNode: _searchFocusNode,
  onSearchChanged: (query) {
    // Handle search query
  },
  tabBar: TabBar(
    labelColor: AppColors.gold,
    unselectedLabelColor: AppColors.textTertiary,
    indicatorColor: AppColors.gold,
    tabs: const [
      Tab(text: 'For You'),
      Tab(text: 'Following'),
      Tab(text: 'Popular'),
    ],
  ),
)
```

### Scrollable App Bar

```dart
// Create a ScrollController
final ScrollController _scrollController = ScrollController();

// Use it in both the HiveAppBar and your scrollable widget
Scaffold(
  appBar: HiveAppBar(
    title: 'Feed',
    scrollable: true,
    scrollController: _scrollController,
  ),
  body: ListView.builder(
    controller: _scrollController,
    // ...
  ),
)
```

### Transparent App Bar

```dart
HiveAppBar(
  title: 'Photo View',
  style: HiveAppBarStyle.transparent,
  showBottomBorder: false,
)
```

## Properties

| Property | Type | Description |
|---|---|---|
| `title` | `String` | Main title of the app bar |
| `subtitle` | `String?` | Optional subtitle displayed below the title |
| `style` | `HiveAppBarStyle` | App bar style variant (standard, withTabs, withSearch, withTabsAndSearch, transparent) |
| `tabBar` | `TabBar?` | TabBar to display below the title |
| `showBackButton` | `bool` | Whether to show a back button |
| `onBackPressed` | `VoidCallback?` | Custom back button callback |
| `actions` | `List<Widget>?` | Actions to display on the right side |
| `leading` | `Widget?` | Leading widget to replace the back button |
| `scrollable` | `bool` | Whether to respond to scroll events |
| `scrollController` | `ScrollController?` | Controller to sync with scrollable content |
| `showBottomBorder` | `bool` | Whether to show a bottom border |
| `titleStyle` | `TextStyle?` | Custom title style |
| `iconColor` | `Color?` | Custom icon color |
| `backgroundColor` | `Color?` | Custom background color |
| `useGlassmorphism` | `bool` | Whether to apply glassmorphism effect |
| `showSearchButton` | `bool` | Whether to show a search button |
| `onSearchPressed` | `VoidCallback?` | Callback when search button is pressed |
| `searchController` | `TextEditingController?` | Controller for the search field |
| `searchFocusNode` | `FocusNode?` | Focus node for the search field |
| `onSearchChanged` | `ValueChanged<String>?` | Callback when search query changes |
| `onSearchClosed` | `VoidCallback?` | Callback when search is closed |

## Best Practices

1. **Use the appropriate style** for your screen's needs:
   - `standard` for basic navigation
   - `withTabs` for multi-tab interfaces
   - `withSearch` for screens that need search
   - `withTabsAndSearch` for complex navigation with search
   - `transparent` for immersive content views

2. **Link scroll controller** when using scrollable app bars:
   - Always use the same `ScrollController` for both the app bar and your scrollable content
   - This ensures proper synchronization of scroll events

3. **Handle search states properly**:
   - Provide both `searchController` and `searchFocusNode` for best experience
   - Always implement `onSearchChanged` to react to search queries
   - Consider managing search state at a higher level (e.g., using Riverpod)

4. **Optimize for mobile**:
   - Test on both iOS and Android to ensure proper behavior
   - Consider device-specific adjustments if needed

5. **Follow HIVE UI design language**:
   - Use the gold accent color for active elements
   - Maintain the dark theme with minimal light elements
   - Use proper text styling consistent with the rest of the app

## Example Implementation

See `hive_app_bar_usage_example.dart` for comprehensive examples of using the HiveAppBar component in various scenarios. 