---
trigger: model_decision
description: when using the FoundationModels framework, LanguageModelSession, or Generable
---

# LanguageModelSession State
- Avoid using `isLoading` state variable for `LanguageModelSession` calls. Instead, use `session.isResponding` to know when the session is responding to a prompt.
- Use `session.isResponding` to disable UI elements while the model is responding or to show a `ProgressView()`.

## One-Shot LanguageModelSession
- Instantiate `LanguageModelSession` with a variable.
```swift
Button("Ask") {
    let session = LanguageModelSession()

    Task {
        response = try await session.respond(to: prompt).content
    }
}
```
### For Streaming:
- Instantiate `LanguageModelSession` with a variable.
```swift
...
Button("Ask") {
    let session = LanguageModelSession()

    Task {
        for try await partialResponse in session.streamResponse(to: prompt) {
            withAnimation {
                response = partialResponse.content
            }
        }
    }
}
```

## Multi-Turn LanguageModelSession
- Put `LanguageModelSession` in an `@State` variable.
- Prewarm the model using `.onAppear` if about one second before `session.respond(to:)` or `session.streamResponse(to:)` is used.
```swift
struct MyView: View {
    @State private var session = LanguageModelSession()
    @State private var response = ""
    let prompt = "Tell me a story about a brave knight."

    var body: some View {
        Button("Ask") {
            Task {
                response = try await session.respond(to: prompt).content
            }
            // or for streaming:
            Task {
                for try await partialResponse in session.streamResponse(to: prompt) {
                    withAnimation {
                        response = partialResponse.content
                    }
                }
            }
        }
        .onAppear {
            session.prewarm()
        }
    }
}
```

### Auto-Scrolling for New Content (Multi-Turn LanguageModelSession)
- If using a chat view, use this template to scroll to the bottom when new content is added:
```swift
ScrollViewReader { proxy in
    ScrollView {
        Text(.init(response))
            .frame(maxWidth: .infinity, alignment: .leading)
            .id("storyContent")
    }
    .onChange(of: response) {
        // 💡 Automatically scroll to bottom when new content is added
        withAnimation {
            proxy.scrollTo("storyContent", anchor: .bottom)
        }
    }
}
```

## @Generable
- Use `@Generable` - which only supports `String`, `Double`, `Bool`, `Float`, `Decimal`, and `Int` types or arrays of these types.
- Use `@Guide(description: "Your description here with example data/formats")` to provide context for each property.
- Use generation guides like `.anyOf`, `.range`, `.pattern`, `.count`, `.element`, `.pattern`, `.constant`, `.maximum`, `.maximumCount`, `.minimum` and `.minimumCount` to constrain input values.
- Add "Generable" suffix to struct and enum names that use `@Generable`.
- Example:
```swift
@Generable(description: "A cooking recipe")
struct RecipeGenerable {
    @Guide(description: "The name of the recipe")
    var name: String
    
    @Guide(description: "The difficulty level of the recipe")
    var difficulty: DifficultyGenerable
    
    @Guide(description: "The cooking time in minutes", .range(10...120))
    var cookTimeMinutes: Int
    
    @Guide(description: "The date recipe was added in YYYY-MM-DD format", .pattern(/\d{4}-\d{2}-\d{2}/))
    let dateString: String
    
    @Guide(description: "A list of ingredients needed for this recipe", .count(4...10))
    var ingredients: [String]
    
    @Guide(description: "", .element(.anyOf(["French", "Italian", "Mexican", "Asian",
                                             "Mediterranean", "Fusion", "Savory", "Sweet"])))
    let tags: [String]
    
    @Guide(description: "Step-by-step instructions for preparing the recipe", .minimumCount(3))
    var instructions: [String]
    
    // MARK: - Computed Properties
    
    var recipeDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString) ?? Date()
    }
}
```
- Use enums for fixed sets of options:
```swift
@Generable(description: "The difficulty level of the recipe")
enum DifficultyGenerable: String {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}
```

## Streaming to Generable Objects
- Use `@State` variable for `LanguageModelSession` and the response object.
- Use `session.streamResponse(to: , generating: )` to stream partial results into the response object.
- Use `.PartiallyGenerated` for the @Generable struct to allow partial updates. 
- Example:
```swift
@State private var session = LanguageModelSession()
@State private var story: StoryElements.PartiallyGenerated?
    
Button("Stream Story Generation") {
    Task {
        for try await snapshot in session.streamResponse(
            to: "Create elements for a mystery novel",
            generating: StoryElements.self
        ) {
            story = snapshot.content
        }
    }
}
```

## Streaming to Generable Object Arrays
- Use `.PartiallyGenerated` for the @Generable structs inside the Array to allow partial updates.
``` swift
@State private var events: [HistoricEvent.PartiallyGenerated] = []

Button("Stream to Array") {
    Task {
        let session = LanguageModelSession()
        for try await snapshot in session.streamResponse(
            to: "What are five events in history?",
            generating: [HistoricEvent].self
        ) {
            events = snapshot.content
        }
    }
}
```

## Tool Definition
- **Tool**: If I ask for a "tool", prefer this format in your response:
```swift
struct WeatherTool: Tool {
    let name = "getWeather"
    let description = "Gets the current weather for a given location"
    
    @Generable
    struct Arguments {
        @Guide(description: "The city or location to get weather for")
        let location: String
    }
    
    func call(arguments: Arguments) async throws -> String {
        return "It's currently 72°F and sunny in \(arguments.location)."
    }
}
```
