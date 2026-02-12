---
name: SwiftData instructions
description: "Instructions for all implementing SwiftData features and models"

# Copilot
applyTo: **/*View.swift, **/*Model.swift

---

# SwiftData Integration
## Model Definition
- Append `Model` to class names.
- Each model should be in its own file.
- Prefix computed properties that prepare data for views with `view`.
- **Avoid** conforming to `Identifiable` (`@Model` makes the model conform to `Identifiable` already)
- **Avoid** adding `id` property to models, (`@Model` conforms to `Identifiable` and implements an `id` property)
- **Avoid** naming a property called `description` (it is reserved), **Prefer** `desc` instead.

```swift
@Model
class UserModel {
    var name: String
    var email: String
    var profileImage: Data? // Optional image data
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade)
    var posts: [PostModel] = []

    init(name: String, email: String, profileImage: Data?) {
        self.name = name
        self.email = email
        self.profileImage = profileImage
        self.createdAt = Date()
    }
}

// MARK: - Image Helpers
import UIKit

extension UserModel {
    var viewProfileImage: UIImage {
        if let data = profileImage, let image = UIImage(data: data) {
            return image
        } else {
            return UIImage(systemName: "person")! // SF Symbol
        }
    }
}

// MARK: - Preview Helpers
extension UserModel {
    static let mock = UserModel(name: "Mock User", email: "mock@test.com", profileImage: nil)
    static let mocks = [
        UserModel(name: "Alice", email: "alice@test.com"),
        UserModel(name: "Bob", email: "bob@test.com")
    ]
}

extension UserModel {
    @MainActor
    static var preview: ModelContainer {
        let container = ModelContainer(for: UserModel.self,
                                        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        container.insert(UserModel.mock)

        return container
    }
}
```

## Container Setup
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [UserModel.self, PostModel.self])
    }
}
```

## Queries in Views
```swift
import SwiftData
...
struct UserListView: View {
    @Query(sort: \UserModel.name) private var users: [UserModel]
    @Environment(\.modelContext) private var context
    
    var body: some View {
        List(users) { user in
            Text(user.name)
        }
        .toolbar {
            Button("Add User") {
                let newUser = UserModel(name: "New User", email: "user@example.com")
                context.insert(newUser)
            }
        }
    }
}
```
