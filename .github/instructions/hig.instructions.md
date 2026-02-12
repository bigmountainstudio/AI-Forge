---
name: Human interface Guidelines instructions
description: "Instructions for user interface and user experience for Apple platforms."

# Copilot
applyTo: "**/*View.swift"

---

# Apple Human Interface Guidelines - SwiftUI Style Guide

## Core Design Principles

### Hierarchy
- Establish clear visual hierarchy through size, weight, color, and spacing
- Place important elements near top and leading edge (respects RTL)
- Use alignment to communicate organization and make content scannable

### Consistency
- Adopt platform conventions for familiar interactions
- Maintain consistent spacing, alignment, and visual patterns
- Use system-defined components and behaviors when possible

### Adaptability  
- Support Dynamic Type and text size changes
- Design for both portrait and landscape orientations
- Test layouts at multiple window sizes and device sizes
- Respect safe areas and avoid system features (Dynamic Island, camera housing)

## Typography

### Font Styles
- **System Font**: SF Pro (iOS/iPadOS/macOS), use via `.font(.body)`, `.font(.title)`, etc.
- **macOS Alternative**: SF Pro or NY (serif) for specific use cases
- **Text Styles**: Use built-in text styles (largeTitle, title, title2, title3, headline, body, callout, subheadline, footnote, caption)
- **Weights**: Prefer Regular, Medium, Semibold, Bold; avoid Ultralight, Thin, Light

### Size Requirements
**iOS/iPadOS Minimum Sizes:**
- Default minimum: 17pt
- Absolute minimum: 11pt  
- Prefer larger sizes (up to 200% increase) for legibility

**macOS Minimum Sizes:**
- Default minimum: 13pt
- Absolute minimum: 10pt
- Note: macOS does NOT support Dynamic Type

### Dynamic Type
- **iOS/iPadOS**: Always support Dynamic Type using SwiftUI text styles
- **macOS**: Does not support Dynamic Type; use fixed text sizes
- Test at largest accessibility sizes (iOS/iPadOS: AX1-AX5)
- Avoid truncating text; use multiple lines when needed
- Adjust layouts for large text (stack vertically if needed)
- Keep hierarchy clear at all text sizes

### Best Practices
- Use system text styles for automatic Dynamic Type support
- Limit typeface variety (typically 2-3 maximum)
- Ensure sufficient contrast (minimum 4.5:1 for body text, 3:1 for large/bold)

## Layout

### Spacing & Margins
- **Standard padding**: Use system-defined spacing (`.padding()`)
- **Between controls**: ~12pt for bezeled elements, ~24pt for non-bezeled
- **Edge-to-edge content**: Extend backgrounds to screen edges
- **Reading order**: Top-to-bottom, leading-to-trailing (RTL-aware)

### Safe Areas
- **Respect safe areas** for device features (notch, Dynamic Island, rounded corners)
- Use `.safeAreaInset()` or `.ignoresSafeArea()` intentionally
- iOS safe area insets: 60pt top/bottom, 80pt sides (varies by device)

### Grids & Alignment
- Align related elements to create visual relationships
- Use consistent column widths and row heights
- Maintain uniform spacing between grid items

### Adaptability
- Design for smallest supported size first
- Support device rotation (portrait/landscape)
- Test resizable windows on iPad
- Use size classes to adapt layouts:
  - Compact width: iPhone portrait, iPad split view
  - Regular width: iPad, iPhone landscape (Plus/Max models)

## Accessibility

### Vision
- **Minimum contrast**: 4.5:1 for text <18pt, 3:1 for ≥18pt or bold text
- **Color usage**: Never rely on color alone; add shapes, labels, or icons
- **System colors**: Use semantic system colors that adapt to appearance modes
- Support VoiceOver with proper labels and hints

### Touch Targets
**Minimum Interactive Sizes:**
- iOS/iPadOS: 44x44 pt recommended, 28x28 pt minimum
- macOS: 28x28 pt recommended, 20x20 pt minimum
- **Spacing**: 12pt padding around bezeled controls, 24pt around non-bezeled

### Motor
- Support simple, single-finger gestures
- Provide button alternatives to complex gestures
- Support Full Keyboard Access
- Avoid time-limited interactions

### Cognitive
- Keep actions simple and intuitive
- Minimize auto-dismissing views
- Support Reduce Motion (avoid excessive animations)
- Provide clear, consistent navigation

## Color

### System Colors
- **Prefer system colors**: `.red`, `.blue`, `.green`, `.orange`, etc.
- **Semantic colors**: 
  - Backgrounds: `.background`, `.secondaryBackground`, `.tertiaryBackground`
  - Labels: `.primary`, `.secondary`, `.tertiary`, `.quaternary`
  - Fills: `.fill`, `.secondaryFill`, `.tertiaryFill`
- System colors automatically adapt to Dark Mode and accessibility settings

### Color Usage
- Use color consistently (don't reuse colors for different meanings)
- Test in both Light and Dark Mode
- Test with Increase Contrast enabled
- Avoid similar colors for adjacent interactive elements
- Consider colorblind users (add non-color indicators)

### Liquid Glass (iOS 18+)
- Liquid Glass background is typically clear, showing content behind it
- Apply color sparingly (primarily for primary actions)
- Use app accent color for prominent buttons (Done, primary CTAs)
- Avoid coloring multiple controls in the same area

## Components

### Buttons
- Use `.buttonStyle(.bordered)` for secondary actions
- Use `.buttonStyle(.borderedProminent)` for primary actions
- Full-width buttons should respect margins (not edge-to-edge)
- Minimum touch target: 44x44 pt

### Lists & Tables
- Use system grouping styles (`.listStyle(.insetGrouped)` or `.plain`)
- Background hierarchy: primary → secondary → tertiary
- Support swipe actions when appropriate

### Navigation
- Use NavigationStack for hierarchical navigation
- TabView for top-level navigation (3-5 tabs recommended)
- Provide clear, concise navigation titles

### Text Fields
- Use clear placeholder text
- Show error states clearly (not just color)
- Support keyboard navigation

## Platform-Specific (iOS/iPadOS)

### iOS
- Support portrait and landscape orientations
- Hide status bar only when it adds value (fullscreen media/games)
- Respect Dynamic Island area
- Test on multiple device sizes

### iPadOS  
- Support window resizing (minimum to maximum)
- Consider sidebar/tab bar convertible navigation
- Test at 1/2, 1/3, 2/3 screen splits
- Smooth transitions between size classes

## Platform-Specific (macOS)

### Layout Differences
- Content can be placed closer to edges than iOS (less aggressive padding)
- Avoid placing controls or critical info at bottom of window
- Don't display content within camera housing area at top edge
- Windows have title bars and standard macOS controls

### Interaction Styles
- Mouse and trackpad primary input (vs touch on iOS)
- Hover states provide important visual feedback
- Keyboard navigation and accessibility shortcuts are essential
- Right-click context menus are standard

### Controls & Components
- Use system-provided buttons and controls that match macOS appearance
- Sidebars typically appear on trailing (right) side in macOS
- Full Keyboard Access is important for macOS users
- Consider app accent colors and sidebar icon colors

### Text & Typography
- No Dynamic Type support; use fixed font sizes
- Minimum body text: 13pt
- Use system text styles for consistency (though no auto-scaling)
- Test readability with various color schemes and lighting

## Testing Checklist

**Universal (iOS/iPadOS/macOS):**
- [ ] Works in both Light and Dark Mode
- [ ] Works with Increase Contrast enabled
- [ ] Color contrast meets 4.5:1 (or 3:1 for large/bold)
- [ ] Doesn't rely solely on color for information
- [ ] Respects safe areas/platform conventions
- [ ] VoiceOver labels are clear and descriptive
- [ ] Reduce Motion is respected (if using animations)

**iOS/iPadOS Specific:**
- [ ] Supports Dynamic Type (test at AX1-AX5 sizes)
- [ ] Touch targets meet 44x44 pt minimum
- [ ] Supports both portrait and landscape (iOS)

**macOS Specific:**
- [ ] Touch targets meet 28x28 pt minimum
- [ ] Keyboard navigation works throughout
- [ ] Hover states provide feedback
- [ ] Content doesn't extend into restricted areas

## SwiftUI Implementation

### Use System Components
```swift
// Typography
Text("Headline").font(.headline)
Text("Body").font(.body)

// Colors  
Color.blue // system color
Color(.systemBackground) // semantic background

// Spacing
.padding() // standard padding
.padding(.horizontal, 16) // custom

// Accessibility
.accessibilityLabel("Description")
.accessibilityHint("Tap to perform action")

// Dynamic Type
.dynamicTypeSize(.large...DynamicTypeSize.accessibility3)
```

### Avoid
- Hard-coded sizes that don't scale - Use `@ScaledMetric` for custom sizes
- Fixed colors without dark mode variants
- Ignoring safe areas without intention
- Custom gestures without button alternatives
- Text truncation in scrollable areas
- Touch targets smaller than 28x28 pt

## Resources
- [Apple HIG](https://developer.apple.com/design/human-interface-guidelines)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [Apple Design Resources](https://developer.apple.com/design/resources/)
