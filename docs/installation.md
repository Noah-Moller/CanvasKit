# Installation Guide

CanvasKit can be installed using Swift Package Manager, which is built into Xcode.

## Requirements

- iOS 15.0+ / macOS 12.0+
- Xcode 13.0+
- Swift 5.5+

## Swift Package Manager

1. In Xcode, select File > Add Packages...
2. Enter the package repository URL:
```
https://github.com/yourusername/CanvasKit.git
```
3. Select the version rule (recommended: "Up to Next Major Version")
4. Click "Add Package"

## Manual Package File

Alternatively, you can add CanvasKit directly to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/CanvasKit.git", from: "1.0.0")
]
```

Then add "CanvasKit" as a dependency to your target:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["CanvasKit"]
    )
]
```

## Importing

After installation, import CanvasKit in your Swift files:

```swift
import CanvasKit
```

## Verifying Installation

To verify the installation, create a simple test:

```swift
import CanvasKit

let client = CanvasClient(
    domain: "your-canvas-domain.com",
    token: "your-api-token"
)

// Test the connection
Task {
    do {
        let courses = try await client.getCourses()
        print("Successfully connected to Canvas!")
        print("Found \(courses.count) courses")
    } catch {
        print("Error connecting to Canvas: \(error)")
    }
}
```

## Next Steps

- Read the [Quick Start Guide](quick-start.md) to begin using CanvasKit
- Learn about [Configuration](configuration.md) options
- Check out the [API Models](models.md) documentation 