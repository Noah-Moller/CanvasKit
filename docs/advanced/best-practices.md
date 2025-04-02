# Best Practices Guide

This guide outlines best practices for using CanvasKit effectively in your iOS applications.

## Architecture

### Client Configuration

1. **API Token Management**
   ```swift
   // DO: Store API token securely
   let token = KeychainService.getToken()
   let client = CanvasClient(domain: domain, token: token)
   
   // DON'T: Hardcode tokens
   let client = CanvasClient(domain: domain, token: "1234...")
   ```

2. **Client Lifecycle**
   ```swift
   // DO: Share client instance
   class AppDelegate {
       static let shared = AppDelegate()
       let canvasClient: CanvasClient
       
       init() {
           canvasClient = CanvasClient(...)
       }
   }
   
   // DON'T: Create multiple instances
   struct ContentView {
       let client = CanvasClient(...) // New instance per view
   }
   ```

### View Models

1. **State Management**
   ```swift
   // DO: Use proper state management
   class CourseViewModel: ObservableObject {
       @Published private(set) var courses: [Course] = []
       @Published private(set) var isLoading = false
       @Published private(set) var error: Error?
       
       func loadCourses() async {
           await MainActor.run { isLoading = true }
           do {
               let courses = try await client.getCourses()
               await MainActor.run {
                   self.courses = courses
                   self.isLoading = false
               }
           } catch {
               await MainActor.run {
                   self.error = error
                   self.isLoading = false
               }
           }
       }
   }
   
   // DON'T: Mix UI and business logic
   struct CourseView {
       func loadCourses() {
           // Direct API calls in view
           Task {
               courses = try await client.getCourses()
           }
       }
   }
   ```

2. **Dependency Injection**
   ```swift
   // DO: Use dependency injection
   class CourseViewModel {
       private let client: CanvasClientProtocol
       
       init(client: CanvasClientProtocol) {
           self.client = client
       }
   }
   
   // DON'T: Create dependencies internally
   class CourseViewModel {
       private let client = CanvasClient(...)
   }
   ```

## Performance

### Data Loading

1. **Pagination**
   ```swift
   // DO: Implement pagination
   func loadCourses(page: Int = 1) async throws -> [Course] {
       let perPage = 20
       let courses = try await client.getCourses(
           page: page,
           perPage: perPage
       )
       return courses
   }
   
   // DON'T: Load everything at once
   func loadAllCourses() async throws -> [Course] {
       return try await client.getCourses()
   }
   ```

2. **Caching**
   ```swift
   // DO: Implement caching
   actor CourseCache {
       private var cache: [Int: Course] = [:]
       private let expirationInterval: TimeInterval = 300
       
       func getCourse(_ id: Int) async -> Course? {
           return cache[id]
       }
       
       func setCourse(_ course: Course) async {
           cache[course.id] = course
       }
   }
   
   // DON'T: Always fetch fresh data
   func getCourse(_ id: Int) async throws -> Course {
       return try await client.getCourse(id)
   }
   ```

### Resource Management

1. **Task Management**
   ```swift
   // DO: Handle task cancellation
   class CourseViewModel: ObservableObject {
       private var loadingTask: Task<Void, Never>?
       
       func loadCourses() {
           loadingTask?.cancel()
           loadingTask = Task {
               do {
                   try Task.checkCancellation()
                   let courses = try await client.getCourses()
                   // Handle results
               } catch {
                   // Handle error
               }
           }
       }
       
       deinit {
           loadingTask?.cancel()
       }
   }
   
   // DON'T: Leave tasks unmanaged
   func loadCourses() {
       Task {
           let courses = try await client.getCourses()
       }
   }
   ```

2. **Memory Management**
   ```swift
   // DO: Clean up resources
   class CourseViewModel {
       private var observers: Set<AnyCancellable> = []
       
       init() {
           client.courseUpdates
               .sink { [weak self] courses in
                   self?.updateCourses(courses)
               }
               .store(in: &observers)
       }
   }
   
   // DON'T: Create retain cycles
   init() {
       client.courseUpdates
           .sink { courses in
               self.updateCourses(courses)
           }
           .store(in: &observers)
   }
   ```

## Error Handling

1. **Granular Error Handling**
   ```swift
   // DO: Handle specific errors
   func loadCourse() async {
       do {
           let course = try await client.getCourse(id)
       } catch CanvasError.httpError(let code) where code == 401 {
           await refreshToken()
       } catch CanvasError.httpError(let code) where code == 404 {
           await showNotFoundError()
       } catch {
           await showGeneralError(error)
       }
   }
   
   // DON'T: Catch all errors the same way
   func loadCourse() async {
       do {
           let course = try await client.getCourse(id)
       } catch {
           print("Error: \(error)")
       }
   }
   ```

2. **User Feedback**
   ```swift
   // DO: Provide meaningful feedback
   func handleError(_ error: Error) {
       switch error {
       case CanvasError.httpError(401):
           showAlert(
               title: "Session Expired",
               message: "Please sign in again"
           )
       case CanvasError.networkError:
           showAlert(
               title: "Connection Error",
               message: "Please check your internet connection"
           )
       default:
           showAlert(
               title: "Error",
               message: error.localizedDescription
           )
       }
   }
   
   // DON'T: Show technical errors
   func handleError(_ error: Error) {
       showAlert(message: error.localizedDescription)
   }
   ```

## Testing

1. **Mock Dependencies**
   ```swift
   // DO: Use protocols for mocking
   protocol CanvasClientProtocol {
       func getCourses() async throws -> [Course]
   }
   
   class MockCanvasClient: CanvasClientProtocol {
       var mockCourses: [Course] = []
       func getCourses() async throws -> [Course] {
           return mockCourses
       }
   }
   
   // DON'T: Use concrete implementations in tests
   class TestViewModel {
       let client = CanvasClient(...)
   }
   ```

2. **Test Edge Cases**
   ```swift
   // DO: Test error scenarios
   func testLoadCoursesError() async {
       let mockClient = MockCanvasClient()
       mockClient.mockError = CanvasError.httpError(500)
       let viewModel = CourseViewModel(client: mockClient)
       
       await viewModel.loadCourses()
       
       XCTAssertNotNil(viewModel.error)
       XCTAssertTrue(viewModel.courses.isEmpty)
   }
   
   // DON'T: Test only happy path
   func testLoadCourses() async {
       let viewModel = CourseViewModel(client: MockCanvasClient())
       await viewModel.loadCourses()
       XCTAssertFalse(viewModel.courses.isEmpty)
   }
   ```

## Security

1. **Token Storage**
   ```swift
   // DO: Use Keychain
   class TokenManager {
       func storeToken(_ token: String) throws {
           let query: [String: Any] = [
               kSecClass as String: kSecClassGenericPassword,
               kSecAttrAccount as String: "CanvasToken",
               kSecValueData as String: token.data(using: .utf8)!
           ]
           SecItemAdd(query as CFDictionary, nil)
       }
   }
   
   // DON'T: Use UserDefaults
   UserDefaults.standard.set(token, forKey: "CanvasToken")
   ```

2. **Network Security**
   ```swift
   // DO: Validate certificates
   let session = URLSession(configuration: .ephemeral)
   session.configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
   
   // DON'T: Disable certificate validation
   let session = URLSession(configuration: .ephemeral)
   session.configuration.urlCredentialStorage = nil
   ```

## See Also

- [Client API Reference](../client-api.md)
- [Error Handling Guide](../error-handling.md)
- [Testing Guide](../testing.md) 