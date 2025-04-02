# CanvasKit

A Swift package for easily interfacing with the Canvas LMS API. This package provides a simple way to access Canvas courses, modules, and assignments data, along with a SwiftUI demo view to showcase the functionality.

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 6.1+
- Canvas API Token

## Installation

Add CanvasKit to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "YOUR_REPOSITORY_URL", from: "1.0.0")
]
```

## Usage

### Initialize the Client

```swift
import CanvasKit

let client = CanvasClient(
    domain: "your-institution.instructure.com",
    token: "your-canvas-api-token"
)
```

### Fetch Courses

```swift
do {
    let courses = try await client.getCourses()
    for course in courses {
        print(course.name)
    }
} catch {
    print("Error: \(error)")
}
```

### Fetch Modules

```swift
do {
    let modules = try await client.getModules(courseId: courseId)
    for module in modules {
        print(module.name)
    }
} catch {
    print("Error: \(error)")
}
```

### Fetch Assignments

```swift
do {
    let assignments = try await client.getAssignments(courseId: courseId)
    for assignment in assignments {
        print(assignment.name)
    }
} catch {
    print("Error: \(error)")
}
```

### Use the Demo View

```swift
import SwiftUI
import CanvasKit

struct ContentView: View {
    let client = CanvasClient(
        domain: "your-institution.instructure.com",
        token: "your-canvas-api-token"
    )
    
    var body: some View {
        CanvasKitDemoView(client: client)
    }
}
```

## Features

- Fetch courses information
- Fetch course modules
- Fetch course assignments
- SwiftUI demo view
- Async/await API
- Error handling
- Type-safe models

## Note

This package requires a Canvas API token. You can generate one in your Canvas account settings. The token should have appropriate permissions to access the required endpoints.

## License

This project is available under the MIT license. 