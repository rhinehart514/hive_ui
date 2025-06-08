# HIVE Space Customization Guidelines

> "Give users control, not chaos—curated freedom creates cohesive experiences."

## Core Customization Philosophy

HIVE's Space customization follows a curated approach that balances owner expression with platform coherence. We provide:

1. **Safe, controlled customization** that maintains HIVE's premium aesthetic
2. **Modular, structured options** rather than free-form editing
3. **Guardrails, not walls** to ensure consistent experience
4. **Expression within brand parameters** to maintain visual harmony

## Visual Identity Customization

### Header Image

| Parameter | Specification | Implementation |
|-----------|---------------|----------------|
| Aspect ratio | Fixed 4:1 | Enforce during upload with cropping tool |
| Resolution | Minimum 1200×300px | Auto-reject if below threshold |
| File size | Maximum 2MB | Compress larger images |
| Content | No offensive content | Moderation queue for review |
| Treatment | Auto-applied tone filter | Match HIVE dark aesthetic |

```dart
// Example header image implementation
ClipRRect(
  borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
  child: AspectRatio(
    aspectRatio: 4 / 1,
    child: Image.network(
      space.headerImageUrl,
      fit: BoxFit.cover,
      frameBuilder: (_, child, frame, __) {
        return frame == null
            ? ShimmerLoadingEffect()
            : ColorFiltered(
                colorFilter: ColorFilter.matrix(HiveFilters.darkTone),
                child: child,
              );
      },
    ),
  ),
)
```

### Space Icon

| Option | Implementation |
|--------|----------------|
| Curated icon set | Select from 50+ pre-approved icons |
| AI-generated | Style-locked frame (HIVE aesthetic) |
| No custom uploads | Prevents inconsistent branding |

### Color Accent Theme

| Feature | Implementation |
|---------|----------------|
| Theme selection | Limited to 4-6 pre-approved palettes |
| No custom hex codes | Ensures color harmony with app |
| Accent application | System controls where accent appears |

## Structural Layout Customization

### Pinned Content

| Feature | Implementation |
|---------|----------------|
| Pin count | Maximum 3 pins per Space |
| Content types | Events, Drops, or Rituals |
| Duration | Optional expiration date |
| Position | Fixed at top of Space feed |

### Featured Section

| Feature | Implementation |
|---------|----------------|
| Toggle | Enable/disable Featured row |
| Content control | Space owner selects featured content |
| Fallback | Algorithmic selection if not curated |
| Layout | Horizontal scrolling cards |

```dart
// Example featured section implementation
if (space.hasFeaturedSection) {
  SectionTitle(title: 'Featured'),
  SizedBox(
    height: 200,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: space.featuredContent.length,
      itemBuilder: (context, index) {
        return FeaturedContentCard(
          content: space.featuredContent[index],
        );
      },
    ),
  ),
}
```

### Custom Sections

| Section Type | Content |
|--------------|---------|
| About Us | Rich text description |
| Meet the Board | Leader profiles |
| FAQs | Q&A format |
| Custom | Title + structured content |

All sections follow strict UI modules with no custom HTML/Markdown.

## Narrative Control

### Welcome Message

| Parameter | Specification |
|-----------|---------------|
| Character limit | 500 characters maximum |
| Format | WYSIWYG editor with limited styling |
| Display | Shown to new joiners or first-time visitors |
| Tone guidance | System suggests positive, inclusive language |

### Description/Bio

| Parameter | Specification |
|-----------|---------------|
| Character limit | Up to 500 characters |
| Format | Plain text with emoji support |
| Styling | Light application of system text styles |

### Social Links

| Parameter | Specification |
|-----------|---------------|
| Limit | Maximum 3 external links |
| Display | Auto-favicon, soft-colored icons only |
| Sanitization | No raw URL display, proper formatting |
| Validation | Link validity checked before saving |

## Prohibited Customizations

The following customizations are explicitly NOT allowed to maintain platform integrity:

| Prohibited | Rationale |
|------------|-----------|
| Font changes | Breaks typographic hierarchy |
| Free-form color codes | Damages color harmony |
| Uploadable backgrounds | Disrupts visual consistency |
| Unbounded layout builders | Creates inconsistent UX |
| Non-structured embeds | Security and layout risks |

## Implementation Process

### Admin Flow

1. Space settings → Customize Space
2. Modular options presented by category
3. Live preview of changes
4. Submit for moderation if needed
5. Publish changes when approved

### Technical Implementation

* Use reactive preview rendering
* Implement proper validation at each step
* Cache customization data for quick loading
* Ensure backward compatibility for older app versions

```dart
// Example Space customization view model
class SpaceCustomizationViewModel extends StateNotifier<SpaceCustomizationState> {
  SpaceCustomizationViewModel(this._repository) : super(SpaceCustomizationState.initial());
  
  final SpaceRepository _repository;
  
  Future<void> updateHeaderImage(File image) async {
    // Validate image
    if (!_isValidHeaderImage(image)) {
      state = state.copyWith(error: 'Image does not meet requirements');
      return;
    }
    
    // Process image with HIVE filter
    final processedImage = await _processWithHiveFilter(image);
    
    // Update state with preview
    state = state.copyWith(
      headerImagePreview: processedImage,
      hasUnsavedChanges: true,
    );
  }
  
  // Additional methods for other customization options...
  
  Future<void> saveChanges() async {
    state = state.copyWith(isSaving: true);
    
    try {
      await _repository.updateSpaceCustomization(
        spaceId: state.spaceId,
        customization: state.toCustomizationModel(),
      );
      
      state = state.copyWith(
        isSaving: false,
        hasUnsavedChanges: false,
        isSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save customization: ${e.toString()}',
      );
    }
  }
}
```

## Moderation Guidelines

All customizations are subject to HIVE community guidelines:

1. **Automatic checks** filter obvious violations
2. **Human review** for edge cases
3. **Appeal process** for rejected customizations
4. **Periodic review** of published Spaces

## Accessibility Requirements

* All custom content must maintain 4.5:1 contrast ratio
* Alternative text required for all custom images
* No rapid flashing content or animations
* Structure must support screen readers

## Technical Constraints

* Customizations stored as structured JSON
* Rendering logic centralized for consistency
* Space theme presets defined in code, not database
* Version control for backward compatibility

## User Experience Guidelines

* Every customization option needs clear explanation
* Provide visual examples of good practices
* Show live preview before applying changes
* Gentle guardrails rather than hard blocks
* Highlight recommended configurations

---

Remember: The goal of Space customization is to foster identity and ownership while maintaining a consistent, premium HIVE experience. Customization should never come at the expense of usability, performance, or brand cohesion. 