# CanvasKit

A Swift package for interacting with the Canvas LMS API. Built with modern Swift features and SwiftUI integration.

## Documentation

[Documentation](docs)

## Features

- ✨ Modern Swift API using async/await
- 🔒 Type-safe API client
- 📱 SwiftUI integration
- 🧪 Comprehensive test coverage
- 📚 Extensive documentation

## Installation

### Swift Package Manager

Add CanvasKit to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/Noah-Moller/CanvasKit.git", from: "1.0.0")
]
```

### Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 5.5+
- Xcode 13.0+

## Quick Start

```swift
import CanvasKit

// Initialize client
let client = CanvasClient(
    domain: "your-canvas-domain.com",
    token: "your-api-token"
)

// Fetch courses
let courses = try await client.getCourses()

// Display courses in SwiftUI
struct CourseList: View {
    @StateObject private var viewModel: CourseViewModel
    
    var body: some View {
        List(viewModel.courses) { course in
            Text(course.name)
        }
        .task {
            await viewModel.loadCourses()
        }
    }
}
```

## Example App

The package includes a demo app showcasing common use cases:

```swift
import SwiftUI
import CanvasKit

@main
struct CanvasKitDemo: App {
    var body: some Scene {
        WindowGroup {
            CanvasKitDemoView()
        }
    }
}
```

## Features

### Course Management

- Fetch course list
- View course details
- Access course modules

### Module Support

- List modules
- View module items
- Access module content

### Assignment Integration

- List assignments
- View assignment details
- Check grades and comments

### Error Handling

- Type-safe error handling
- User-friendly error messages
- Automatic retry for transient failures

### SwiftUI Integration

- Ready-to-use SwiftUI views
- MVVM architecture
- State management

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.