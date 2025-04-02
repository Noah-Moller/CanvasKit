# Getting Started with CanvasKit

This guide will help you get started with CanvasKit development. We'll cover setup, basic usage, and common development tasks.

## Prerequisites

Before you begin, ensure you have:

- Xcode 13.0 or later
- iOS 15.0+ / macOS 12.0+
- Swift 5.5+
- A Canvas LMS API token
- Basic knowledge of SwiftUI and async/await

## Setup

1. **Add Package Dependency**

   Add CanvasKit to your Xcode project or Swift package:

   ```swift
   // Package.swift
   dependencies: [
       .package(url: "https://github.com/yourusername/CanvasKit.git", from: "1.0.0")
   ]
   ```

   Or in Xcode:
   - File > Add Packages...
   - Enter the repository URL
   - Choose the version

2. **Import CanvasKit**

   ```swift
   import CanvasKit
   ```

3. **Configure API Access**

   ```swift
   // Store API token securely
   class TokenManager {
       static func storeToken(_ token: String) throws {
           let query: [String: Any] = [
               kSecClass as String: kSecClassGenericPassword,
               kSecAttrAccount as String: "CanvasToken",
               kSecValueData as String: token.data(using: .utf8)!
           ]
           SecItemAdd(query as CFDictionary, nil)
       }
       
       static func getToken() throws -> String? {
           let query: [String: Any] = [
               kSecClass as String: kSecClassGenericPassword,
               kSecAttrAccount as String: "CanvasToken",
               kSecReturnData as String: true
           ]
           
           var result: AnyObject?
           let status = SecItemCopyMatching(query as CFDictionary, &result)
           
           guard status == errSecSuccess,
                 let data = result as? Data,
                 let token = String(data: data, encoding: .utf8) else {
               return nil
           }
           
           return token
       }
   }
   ```

## Basic Usage

### Initialize Client

```swift
class AppDelegate: NSObject, UIApplicationDelegate {
    static let shared = AppDelegate()
    
    lazy var canvasClient: CanvasClient = {
        guard let token = try? TokenManager.getToken() else {
            fatalError("Canvas API token not found")
        }
        return CanvasClient(
            domain: "your-canvas-domain.com",
            token: token
        )
    }()
}
```

### Create Main View

```swift
@main
struct CanvasApp: App {
    var body: some Scene {
        WindowGroup {
            CanvasKitDemoView(client: AppDelegate.shared.canvasClient)
        }
    }
}
```

### Implement Course List

```swift
struct CourseList: View {
    @StateObject private var viewModel: CourseViewModel
    
    init(client: CanvasClient) {
        _viewModel = StateObject(wrappedValue: CourseViewModel(client: client))
    }
    
    var body: some View {
        List {
            ForEach(viewModel.courses) { course in
                NavigationLink {
                    CourseDetail(course: course)
                } label: {
                    CourseRow(course: course)
                }
            }
        }
        .navigationTitle("Courses")
        .task {
            await viewModel.loadCourses()
        }
        .refreshable {
            await viewModel.loadCourses()
        }
    }
}
```

## Common Tasks

### Fetch Course Content

```swift
class CourseViewModel: ObservableObject {
    @Published private(set) var courses: [Course] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let client: CanvasClient
    
    init(client: CanvasClient) {
        self.client = client
    }
    
    @MainActor
    func loadCourses() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            courses = try await client.getCourses()
        } catch {
            self.error = error
        }
    }
}
```

### Display Assignments

```swift
struct AssignmentList: View {
    let courseId: Int
    @StateObject private var viewModel: AssignmentViewModel
    
    init(courseId: Int, client: CanvasClient) {
        self.courseId = courseId
        _viewModel = StateObject(wrappedValue: AssignmentViewModel(
            client: client,
            courseId: courseId
        ))
    }
    
    var body: some View {
        List {
            ForEach(viewModel.assignments) { assignment in
                NavigationLink {
                    AssignmentDetail(assignment: assignment)
                } label: {
                    AssignmentRow(assignment: assignment)
                }
            }
        }
        .task {
            await viewModel.loadAssignments()
        }
    }
}
```

### Handle Errors

```swift
struct ErrorHandlingView<Content: View>: View {
    let error: Error?
    let retryAction: () async -> Void
    let content: () -> Content
    
    var body: some View {
        if let error = error {
            VStack {
                Text("Error: \(error.localizedDescription)")
                Button("Retry") {
                    Task {
                        await retryAction()
                    }
                }
            }
        } else {
            content()
        }
    }
}
```

## Development Workflow

1. **Project Structure**
   ```
   Sources/
   ├── CanvasKit/
   │   ├── Models/
   │   │   ├── Course.swift
   │   │   ├── Module.swift
   │   │   └── Assignment.swift
   │   ├── Views/
   │   │   ├── CourseList.swift
   │   │   └── AssignmentDetail.swift
   │   ├── ViewModels/
   │   │   ├── CourseViewModel.swift
   │   │   └── AssignmentViewModel.swift
   │   └── Networking/
   │       ├── CanvasClient.swift
   │       └── APIError.swift
   └── CanvasKitDemo/
       └── CanvasKitDemoApp.swift
   ```

2. **Testing**
   ```swift
   class CourseViewModelTests: XCTestCase {
       var viewModel: CourseViewModel!
       var mockClient: MockCanvasClient!
       
       override func setUp() {
           super.setUp()
           mockClient = MockCanvasClient()
           viewModel = CourseViewModel(client: mockClient)
       }
       
       func testLoadCourses() async {
           // Given
           let mockCourses = [Course(id: 1, name: "Test")]
           mockClient.mockCourses = mockCourses
           
           // When
           await viewModel.loadCourses()
           
           // Then
           XCTAssertEqual(viewModel.courses, mockCourses)
       }
   }
   ```

3. **Debugging**
   ```swift
   extension CanvasClient {
       func debugLog(_ message: String) {
           #if DEBUG
           print("[CanvasKit] \(message)")
           #endif
       }
   }
   ```

## Best Practices

1. **API Token Security**
   - Never hardcode tokens
   - Use Keychain for storage
   - Implement token refresh

2. **Error Handling**
   - Handle network errors gracefully
   - Show user-friendly messages
   - Implement retry logic

3. **Performance**
   - Cache network responses
   - Implement pagination
   - Use async/await properly

4. **Testing**
   - Write unit tests
   - Use mock clients
   - Test error scenarios

5. **UI/UX**
   - Show loading states
   - Handle empty states
   - Provide error feedback

## Next Steps

1. Read the [Client API Reference](client-api.md)
2. Explore [API Models](models.md)
3. Review [Best Practices](advanced/best-practices.md)
4. Check [Error Handling](error-handling.md)
5. Study [Testing Guide](testing.md)

## Troubleshooting

### Common Issues

1. **API Token Invalid**
   ```swift
   // Check token validity
   func validateToken() async throws -> Bool {
       do {
           _ = try await client.getCourses()
           return true
       } catch CanvasError.httpError(401) {
           return false
       }
   }
   ```

2. **Network Errors**
   ```swift
   // Implement retry logic
   func retryingFetch<T>(
       maxAttempts: Int = 3,
       operation: () async throws -> T
   ) async throws -> T {
       var attempts = 0
       var lastError: Error?
       
       while attempts < maxAttempts {
           do {
               return try await operation()
           } catch {
               attempts += 1
               lastError = error
               if attempts < maxAttempts {
                   try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempts)) * 1e9))
               }
           }
       }
       
       throw lastError!
   }
   ```

3. **Memory Issues**
   ```swift
   // Implement proper cleanup
   class ResourceManager {
       static let shared = ResourceManager()
       private var cache = NSCache<NSString, AnyObject>()
       
       func clearCache() {
           cache.removeAllObjects()
       }
   }
   ```

## Support

For additional help:

1. Check the [documentation](docs/)
2. File an issue on GitHub
3. Contact the maintainers

## See Also

- [Client API Reference](client-api.md)
- [Models Documentation](models.md)
- [Views Guide](views.md)
- [Testing Guide](testing.md) 