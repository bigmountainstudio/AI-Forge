---
trigger: always_on
---

# Project Structure

## File Naming
- **Views**: `*View.swift` (e.g., `HomeView.swift`, `SettingsView.swift`)
- **Observables**: `*Observable.swift` (e.g., `HomeObservable.swift`)
- **Modifiers**: `*Modifier.swift` (e.g., `CardStyleModifier.swift`)
- **Data Models**: `*Model.swift` (e.g., `UserModel.swift`)
- **FoundationModels Generables**: `*Generable.swift` (e.g., `RecipeGenerable.swift`)

## File Headers
Always include this header on new files:
```swift
// Copyright ©2026 Big Mountain Studio. All rights reserved. X: @BigMtnStudio
```

# Core Principles

## Preferences
- **Prefer**: Using `condition == false` over `!condition` for clarity.
- **Avoid**: Wrapping conditions in parentheses unless necessary for precedence.
- Use `@Observable` classes for view models
- Prefer dependency injection through initializers or property injection
- Use `@Environment` for shared state across view hierarchies


# Project Structure Patterns

## Recommended Architecture
- Create these folders as needed:
  - `App`: Main app entry point and root views
  - `Views`: Feature-specific views (and their observables) with their view models organized by functionality
  - `Shared`: Reusable components, models, tools, services, and extensions
  - `Resources`: Assets, localization files, and other resources
  - `Supporting Files`: Info.plist, entitlements, etc.

## Example Folder Structure
```
ProjectName/
├── App/
│   └── ProjectNameApp.swift
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
├── Shared/
│   ├── Extensions/
│   ├── Models/
│   ├── Services/
│   └── Tools/
├── Supporting Files/
└── Views/
    ├── Authentication/
    │   └── AuthenticationView.swift
    │   └── AuthenticationObservable.swift
    ├── Home/
    │   ├── HomeView.swift
    │   └── HomeObservable.swift
    └── Settings/
        └── SettingsView.swift
        └── SettingsObservable.swift
```
The view and its observable share the same folder.
