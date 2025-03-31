# Flutter ScrollView Rules to Prevent Layout Issues

## 1. Nested ScrollView Prevention

- **NEVER** nest a `CustomScrollView` inside another scrollable widget
- **ALWAYS** return direct sliver widgets from reusable components rather than wrapping them in `CustomScrollView` 
- When creating custom components with grids/lists, make them return slivers directly
- Use `SliverToBoxAdapter` to adapt non-sliver widgets to a parent `CustomScrollView`

## 2. Layout Height Constraints

- Explicitly constrain the height of any scrollable widget inside another container
- **AVOID** placing a `ListView` directly inside a `Column` without a defined height
- For scrollable content inside another container, use `Expanded(child: SingleChildScrollView(...))` pattern
- When using `TabBarView` with scrolling content, ensure each tab's layout uses proper constraints
- **VERIFY** all scrollable containers have bounded height either through parent constraints or explicit sizing

## 3. FAB and Bottom Navigation Spacing

- **ALWAYS** add minimum 80px bottom padding to scrollable content when using a FAB
- For screens with bottom navigation, ensure bottom padding accommodates both the navigation bar and any FABs
- Use `SliverPadding` with proper padding values for sliver-based scroll views
- Test the layout with and without the keyboard visible to ensure proper spacing

## 4. Component Structure Best Practices

- Reusable grid/list components should:
  - Return Sliver widgets directly rather than complete scroll views
  - Accept and apply external constraints properly
  - Use animation limiters and optimizations to prevent jank
  - Clearly document whether they are to be used inside a `CustomScrollView` or standalone

## 5. Testing Verification Checklist

Before submitting changes to scrollable layouts:
- [ ] Test the layout with different screen sizes/orientations
- [ ] Verify the layout works with both small and large data sets
- [ ] Check the Flutter console for "unbounded height" or "overflow" warnings
- [ ] Ensure the FAB remains accessible when scrolling to the bottom of content
- [ ] Verify tab transitions maintain proper layout and don't trigger rebuilds
- [ ] Test touch interactions to ensure hitboxes aren't overlapping incorrectly 