# Error Handling Guide

This guide covers error handling in CanvasKit, including common error types, best practices, and example implementations.

## Error Types

### CanvasError

The primary error type in CanvasKit is `CanvasError`:

```swift
public enum CanvasError: Error {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
}
```

#### Cases

- `invalidResponse`: The server response was invalid or malformed
- `httpError(statusCode: Int)`: An HTTP error occurred with the given status code
- `decodingError(Error)`: Failed to decode the JSON response

## Common Error Scenarios

### Network Errors

```swift
do {
    let courses = try await client.getCourses()
    // Process courses
} catch CanvasError.httpError(let statusCode) {
    switch statusCode {
    case 401:
        // Handle unauthorized access
        print("Invalid API token")
    case 403:
        // Handle forbidden access
        print("Insufficient permissions")
    case 404:
        // Handle not found
        print("Resource not found")
    case 429:
        // Handle rate limiting
        print("Too many requests")
    case 500...599:
        // Handle server errors
        print("Server error: \(statusCode)")
    default:
        print("HTTP error: \(statusCode)")
    }
}
```

### Decoding Errors

```swift
do {
    let modules = try await client.getModules(courseId: courseId)
    // Process modules
} catch CanvasError.decodingError(let error) {
    if let decodingError = error as? DecodingError {
        switch decodingError {
        case .keyNotFound(let key, _):
            print("Missing key: \(key)")
        case .valueNotFound(let type, _):
            print("Missing value of type: \(type)")
        case .typeMismatch(let type, _):
            print("Type mismatch for: \(type)")
        default:
            print("Decoding error: \(error)")
        }
    }
}
```

## Best Practices

### 1. Granular Error Handling

Handle specific error cases separately for better user feedback:

```swift
func fetchCourseData(courseId: Int) async {
    do {
        let assignments = try await client.getAssignments(courseId: courseId)
        // Process assignments
    } catch CanvasError.httpError(401) {
        // Handle authentication error
        await refreshToken()
        // Retry the request
    } catch CanvasError.httpError(429) {
        // Handle rate limiting
        await Task.sleep(UInt64(1e9))  // Wait 1 second
        // Retry the request
    } catch {
        // Handle other errors
        print("Unexpected error: \(error)")
    }
}
```

### 2. Retry Logic

Implement retry logic for transient failures:

```swift
func retryingFetch<T>(
    maxAttempts: Int = 3,
    operation: () async throws -> T
) async throws -> T {
    var attempts = 0
    var lastError: Error?
    
    while attempts < maxAttempts {
        do {
            return try await operation()
        } catch CanvasError.httpError(let code) where code >= 500 {
            attempts += 1
            lastError = CanvasError.httpError(statusCode: code)
            if attempts < maxAttempts {
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempts)) * 1e9))
            }
        } catch {
            throw error
        }
    }
    
    throw lastError!
}
```

### 3. Error Recovery

Implement recovery strategies for common errors:

```swift
func fetchWithRecovery<T>(
    operation: () async throws -> T,
    recovery: (Error) async throws -> T
) async throws -> T {
    do {
        return try await operation()
    } catch {
        return try await recovery(error)
    }
}
```

### 4. User-Friendly Error Messages

Convert technical errors into user-friendly messages:

```swift
extension CanvasError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response. Please try again."
        case .httpError(let statusCode):
            return "A network error occurred (Error \(statusCode)). Please check your connection."
        case .decodingError:
            return "There was an error processing the server response. Please try again."
        }
    }
}
```

## Error Propagation

### View Layer

```swift
struct CourseView: View {
    @StateObject private var viewModel = CourseViewModel()
    
    var body: some View {
        Group {
            if let error = viewModel.error {
                ErrorView(error: error) {
                    Task {
                        await viewModel.retry()
                    }
                }
            } else {
                // Normal content view
            }
        }
    }
}
```

### View Model Layer

```swift
class CourseViewModel: ObservableObject {
    @Published private(set) var error: Error?
    private let client: CanvasClient
    
    func loadCourse(id: Int) async {
        do {
            let course = try await client.getCourses()
            // Update UI
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }
}
```

## Testing Error Scenarios

```swift
class ErrorHandlingTests: XCTestCase {
    func testHttpErrors() async throws {
        let client = MockCanvasClient()
        client.mockError = CanvasError.httpError(statusCode: 401)
        
        do {
            _ = try await client.getCourses()
            XCTFail("Expected error")
        } catch CanvasError.httpError(let code) {
            XCTAssertEqual(code, 401)
        }
    }
    
    func testRetryLogic() async throws {
        let client = MockCanvasClient()
        var attempts = 0
        
        client.mockOperation = {
            attempts += 1
            if attempts < 3 {
                throw CanvasError.httpError(statusCode: 503)
            }
            return []
        }
        
        _ = try await retryingFetch {
            try await client.getCourses()
        }
        
        XCTAssertEqual(attempts, 3)
    }
}
```

## See Also

- [Client API Reference](client-api.md) for API method details
- [Best Practices](advanced/best-practices.md) for general usage guidelines
- [Testing Guide](testing.md) for testing strategies 