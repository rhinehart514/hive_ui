# HIVE Form Standards

> "Forms aren't obstacles—they're conversations that guide users toward successful outcomes."

## Core Form Philosophy

Forms in HIVE facilitate structured input while reducing friction and cognitive load. Every form should:

1. **Guide users intuitively** through a clear process
2. **Validate intelligently** with helpful, contextual feedback
3. **Minimize effort** through smart defaults and progressive disclosure
4. **Respond promptly** with appropriate feedback at each step

## Form Components

### Text Inputs

#### BrandedTextField

The primary text input component for HIVE.

##### Specifications:
- **Height**: 56pt standard
- **Radius**: 8pt rounded corners
- **Background**: #222222 (slightly lighter than app background)
- **Border**: None by default; 1px solid #FFD700 when focused
- **States**:
  - **Default**: Standard appearance
  - **Focused**: Gold border highlight
  - **Error**: Red border with error message below
  - **Disabled**: 50% opacity with lighter text
  - **Success**: Optional green check icon (for validated fields)

```dart
// Example implementation
BrandedTextField(
  controller: emailController,
  label: 'Email',
  hint: 'Enter your email address',
  keyboardType: TextInputType.emailAddress,
  textInputAction: TextInputAction.next,
  validator: validateEmail,
  prefix: Icon(Icons.email_outlined),
  onChanged: (value) => validateOnChange(value),
)
```

#### BrandedTextArea

For multi-line text input.

##### Specifications:
- Similar styling to BrandedTextField
- **Min Height**: 100pt
- **Max Height**: Configurable or expands to fit content
- **Max Length**: Optional with character counter

### Selection Inputs

#### HiveDropdown

For selecting from multiple options.

##### Specifications:
- **Height**: Same as BrandedTextField (56pt)
- **Appearance**: Consistent with text inputs
- **Dropdown menu**: Matches HIVE dark theme
- **Animation**: Smooth open/close transition

#### HiveToggleSwitch

For binary choices.

##### Specifications:
- **Track size**: 50pt × 30pt
- **Thumb size**: 26pt diameter
- **Animation**: Smooth slide with subtle bounce
- **States**: On (gold), Off (gray)

#### HiveSegmentedControl

For selecting from 2-5 related options.

##### Specifications:
- **Height**: 36pt
- **Selection indicator**: Animated underline or background
- **Transitions**: Smooth sliding animation

### Date & Time Inputs

#### HiveDatePicker

For selecting dates.

##### Specifications:
- **Display**: Branded TextField with date format
- **Picker**: Dark-themed calendar overlay
- **Animation**: Smooth modal entrance/exit

#### HiveTimePicker

For selecting times.

##### Specifications:
- **Display**: Similar to DatePicker
- **Picker**: iOS-inspired wheel or clock interface
- **Format**: 12h/24h based on device settings

## Form Layout

### Spacing & Alignment

| Element | Specification |
|---------|---------------|
| Between fields | 16pt vertical spacing |
| Field groups | 24pt separation between logical groups |
| Field width | Full width on mobile, appropriate constraints on larger screens |
| Labels | Left-aligned with fields |
| Error messages | Left-aligned under respective fields |

### Responsive Considerations

| Screen Width | Adaptation |
|--------------|------------|
| Mobile (<600px) | Single column, full width |
| Tablet (600-1024px) | Optional two columns for related fields |
| Desktop (>1024px) | Constrained width (max 640px) centered |

## Interaction Standards

### Focus Behavior
- **Tab order**: Logical progression through form
- **Auto-focus**: First field focused on form appearance
- **Next action**: "Next" keyboard key moves to next field

### Validation Timing

| Validation Type | Trigger |
|-----------------|---------|
| Field-level | On blur or on change after first blur |
| Cross-field | On form submission or related field change |
| Server-side | On submission with loading state |

### Error Handling
- **Field errors**: Displayed below respective fields
- **Form-level errors**: Displayed at top or bottom of form
- **Error appearance**: Fade in smoothly, no jarring transitions
- **Error messages**: Human-readable, constructive guidance

### Success Feedback
- **Field success**: Optional checkmark or subtle indication
- **Form success**: Clear submission confirmation
- **Transitions**: Smooth transition to next step or success state

## Implementation Guidelines

1. **Use the form component system** rather than raw inputs
2. **Implement proper validation** at appropriate times
3. **Handle all input states** including loading and errors
4. **Ensure keyboard handling** works correctly across platforms

### Form State Management

```dart
// Example form state handling
class ProfileFormState extends StateNotifier<ProfileFormData> {
  ProfileFormState(this._repository) : super(ProfileFormData.initial());
  
  final ProfileRepository _repository;
  
  // Field validation logic
  void validateName(String value) {
    if (value.isEmpty) {
      state = state.copyWith(nameError: 'Name is required');
    } else if (value.length < 2) {
      state = state.copyWith(nameError: 'Name is too short');
    } else {
      state = state.copyWith(
        nameError: null,
        name: value,
      );
    }
  }
  
  // Form submission logic
  Future<void> submit() async {
    if (!_isFormValid()) {
      state = state.copyWith(showAllErrors: true);
      return;
    }
    
    state = state.copyWith(isSubmitting: true);
    
    try {
      await _repository.updateProfile(state.toProfileModel());
      state = state.copyWith(
        isSubmitting: false,
        isSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        formError: 'Failed to update profile: ${e.toString()}',
      );
    }
  }
  
  bool _isFormValid() {
    return state.nameError == null && 
           state.bioError == null &&
           state.name.isNotEmpty;
  }
}
```

## Form Patterns

### Login/Registration

- **Email validation**: Real-time format checking
- **Password strength**: Visual indicator with requirements
- **Progressive disclosure**: Show additional fields only when needed
- **Remember me**: Toggle with clear labeling
- **Social options**: Clearly separated alternative login methods

### Profile/Settings Forms

- **Autosave**: Consider automatic saving of settings changes
- **Revert option**: Allow canceling changes
- **Field organization**: Group related settings
- **Preview**: Show visual preview of changes when applicable

### Search/Filter Forms

- **Instant results**: Update as user types/selects
- **Clear all**: Easy way to reset filters
- **Recent searches**: Show recent/saved searches when relevant
- **Suggestions**: Provide smart suggestions based on input

## Decision Matrix: Form Component Selection

| Input Type | Component | Notes |
|------------|-----------|-------|
| Short text | BrandedTextField | Standard single-line input |
| Long text | BrandedTextArea | Multi-line with resize |
| Email | BrandedTextField | With email keyboard and validation |
| Password | BrandedTextField | With secure entry and strength indicator |
| Selection (few) | HiveSegmentedControl | For related, visible options |
| Selection (many) | HiveDropdown | For longer option lists |
| Binary choice | HiveToggleSwitch | For yes/no, on/off choices |
| Date | HiveDatePicker | With formatted display |
| Time | HiveTimePicker | With appropriate locale format |
| Multiple selection | HiveMultiSelect or Checkboxes | For multi-select lists |

## Accessibility Requirements

- **Labels**: All inputs must have proper labels (not just placeholders)
- **Error announcements**: Screen readers must announce errors
- **Focus indicators**: Clear visual focus state for keyboard users
- **Field instructions**: Helper text for complex inputs
- **Required fields**: Clearly marked with non-color indicators
- **Large touch targets**: All interactive elements minimum 44×44pt

## Performance Considerations

- **Debounce validation**: For expensive validations
- **Lazy loading**: For forms with many fields
- **Optimistic UI**: Update UI before server confirmation when appropriate
- **Persistence**: Save form state to prevent data loss

## Form Submission

### Form Actions

| Action | Placement |
|--------|-----------|
| Primary submit | Bottom right or full-width button |
| Secondary actions | Less prominent, adjacent to primary |
| Cancel/Back | Top left or below primary action |

### Loading States

- **Button loading**: Replace text with spinner, maintain size
- **Form disable**: Prevent further input during submission
- **Progress indication**: For multi-step or lengthy processes

### Submission Feedback

- **Success**: Clear confirmation with next steps
- **Partial success**: Indicate what succeeded and what failed
- **Failure**: Clear error with recovery options

## Edge Cases

- **Network failure**: Preserve form data, allow retry
- **Session timeout**: Warn before expiry, preserve data if possible
- **Validation conflicts**: Clear hierarchy for competing errors
- **Unsaved changes**: Confirm before discarding
- **Autocomplete interaction**: Test with browser/OS autocomplete

---

For implementation help, see the following references:
- [BrandedTextField Implementation](mdc:lib/core/widgets/branded_text_field.dart)
- [Form Validation Examples](mdc:lib/docs/examples/form_validation_examples.dart)
- [Accessibility Guidelines](mdc:lib/docs/accessibility_guidelines.md) 