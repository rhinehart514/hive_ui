# Flutter ScrollView Implementation Checklist

## Quick Pre-Implementation Checks

- [ ] Is this component meant to be used within another scrollable? If yes, return a Sliver widget
- [ ] Does this component handle its own scrolling? If yes, ensure it has definite height constraints
- [ ] Will a FAB be used with this scrollable content? If yes, add at least 80px bottom padding

## During Implementation

- [ ] ✅ Return sliver widgets directly from reusable components
- [ ] ✅ Use SliverPadding with proper edge insets
- [ ] ✅ Define explicit height constraints for any scrollable inside a Column or Row
- [ ] ✅ Use Expanded + SingleChildScrollView pattern when appropriate
- [ ] ✅ Avoid nesting CustomScrollView/ListView widgets
- [ ] ✅ Apply consistent padding across tab views

## Common Error Prevention

- [ ] ❌ NO CustomScrollView inside another CustomScrollView
- [ ] ❌ NO ListView directly in a Column without height constraints
- [ ] ❌ NO unbounded scrollable widgets in flex containers (Row/Column)
- [ ] ❌ NO ScrollView with children that are also ScrollViews

## Testing Checklist

- [ ] Test on different screen sizes
- [ ] Verify scrolling when content is minimal
- [ ] Verify scrolling when content is extensive
- [ ] Check FAB accessibility at all scroll positions
- [ ] Inspect for console warnings about "unbounded height" or "overflow"

> **Remember**: In Flutter, a scrollable widget must have bounded height, either from its parent or through explicit constraints. 