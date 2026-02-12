---
name: SwiftUI Views Instructions
description: "Instructions for keeping SwiftUI views current, avoiding deprecations, and following the view and observable pattern."

# Copilot
applyTo: "**/*View.swift"

---

## Always Use Latest SwiftUI Practices
- Prioritize iOS 26+ APIs and patterns when available
- Use `@Observable` macro instead of `ObservableObject` for new code
- Prefer `@State` and `@Bindable` over legacy property wrappers when possible
- Implement SwiftData instead of Core Data for new projects
- Use new navigation APIs (`NavigationStack`, `NavigationSplitView`) over the deprecated `NavigationView`

## Avoid Deprecated APIs
- **Avoid**: `NavigationView`, `@StateObject`
- **Prefer**: `NavigationStack`/`NavigationSplitView`, `@State` with `@Observable`.
- **Avoid**: `@Published` (`@Observable` already observes all public properties)
- **Avoid** `cornerRadius(8)`, use `background(style, in: .rect(cornerRadius: 8))` or `.clipShape(.rect(cornerRadius: 8))` when appropriate.
- **Prefer**: Static shapes like `.rect(cornerRadius:)` over shape objects like `RoundedRectangle(cornerRadius:)`.

## Observables
```swift
@Observable
class UserObservable {
    var users: [User] = []
    var isLoading = false
    var errorMessage: String?
    
    func fetch() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            users = try await userService.fetchUsers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

## Navigation
```swift
// Use NavigationStack with path binding
@State private var navigationPath = NavigationPath()

NavigationStack(path: $navigationPath) {
    HomeView()
        .navigationDestination(for: User.self) { user in
            UserDetailView(user: user)
        }
}
```

## Async/Await with SwiftUI
```swift
struct HomeView: View {
    @State private var oo = HomeViewObservable()
    
    var body: some View {
        List(oo.users) { user in
            UserRow(user: user)
        }
        .task {
            await oo.fetch()
        }
        .refreshable {
            await oo.fetch()
        }
    }
}
```

## Custom View Modifiers
```swift
struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.regularMaterial, in: .rect(cornerRadius: 12))
            .shadow(radius: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }
}
```

## Modularity and Encapsulation:
- **Reusable Components:** When suggesting a component that is already similar to an existing one, suggest it as a separate struct View in its own file.

- **Complexity Encapsulation (Even if Not Reused):** For sections of a parent View's body that become overly long or complex (e.g., >40 lines, intricate layout, or distinct internal logic), suggest extracting them into `private var someView: some View { ... }` computed properties or `private struct NestedView: View { ... }` structs within the same file. This improves readability and maintains focus without creating unnecessary file sprawl.

- **Avoid Excessive Extraction:** Do not automatically extract every small, single-use UI element into its own file. This leads to file sprawl and over-engineering. Only extract to a separate file if clear reuse is anticipated or if the component is significant in size/complexity and has a strong, distinct responsibility.
