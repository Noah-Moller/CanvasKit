# Testing Guide

This guide covers testing strategies and best practices for CanvasKit, including unit tests, integration tests, and mocking.

## Test Structure

Tests are organized in the `Tests` directory:

```
Tests/
├── CanvasKitTests/
│   ├── ClientTests/
│   │   ├── CanvasClientTests.swift
│   │   └── MockCanvasClient.swift
│   ├── ModelTests/
│   │   ├── CourseTests.swift
│   │   ├── ModuleTests.swift
│   │   └── AssignmentTests.swift
│   └── ViewTests/
│       ├── CourseViewTests.swift
│       └── ModuleViewTests.swift
└── CanvasKitUITests/
    └── CanvasKitDemoViewTests.swift
```

## Unit Testing

### Model Tests

Test model decoding and encoding:

```swift
class CourseTests: XCTestCase {
    func testDecoding() throws {
        let json = """
        {
            "id": 1,
            "name": "Test Course",
            "course_code": "TEST101",
            "workflow_state": "available"
        }
        """
        
        let data = json.data(using: .utf8)!
        let course = try JSONDecoder().decode(Course.self, from: data)
        
        XCTAssertEqual(course.id, 1)
        XCTAssertEqual(course.name, "Test Course")
        XCTAssertEqual(course.courseCode, "TEST101")
        XCTAssertEqual(course.workflowState, "available")
    }
    
    func testEncoding() throws {
        let course = Course(
            id: 1,
            name: "Test Course",
            courseCode: "TEST101",
            workflowState: "available"
        )
        
        let data = try JSONEncoder().encode(course)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        XCTAssertEqual(json["id"] as? Int, 1)
        XCTAssertEqual(json["name"] as? String, "Test Course")
        XCTAssertEqual(json["course_code"] as? String, "TEST101")
        XCTAssertEqual(json["workflow_state"] as? String, "available")
    }
}
```

### Client Tests

Test API client methods using mocked responses:

```swift
class CanvasClientTests: XCTestCase {
    var client: CanvasClient!
    var mockURLSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        mockURLSession = MockURLSession()
        client = CanvasClient(
            domain: "test.instructure.com",
            token: "test-token",
            urlSession: mockURLSession
        )
    }
    
    func testGetCourses() async throws {
        // Setup mock response
        let json = """
        [
            {
                "id": 1,
                "name": "Test Course",
                "course_code": "TEST101",
                "workflow_state": "available"
            }
        ]
        """
        
        mockURLSession.mockResponse = (json.data(using: .utf8)!, HTTPURLResponse(
            url: URL(string: "https://test.instructure.com/api/v1/courses")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!)
        
        // Test
        let courses = try await client.getCourses()
        
        // Verify
        XCTAssertEqual(courses.count, 1)
        XCTAssertEqual(courses[0].id, 1)
        XCTAssertEqual(courses[0].name, "Test Course")
    }
    
    func testGetCoursesError() async throws {
        // Setup mock error response
        mockURLSession.mockResponse = (Data(), HTTPURLResponse(
            url: URL(string: "https://test.instructure.com/api/v1/courses")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!)
        
        // Test and verify error
        do {
            _ = try await client.getCourses()
            XCTFail("Expected error")
        } catch CanvasError.httpError(let statusCode) {
            XCTAssertEqual(statusCode, 401)
        }
    }
}
```

### View Model Tests

Test view model behavior and state management:

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
        // Setup mock data
        let mockCourses = [
            Course(id: 1, name: "Course 1", courseCode: "C1", workflowState: "available"),
            Course(id: 2, name: "Course 2", courseCode: "C2", workflowState: "available")
        ]
        mockClient.mockCourses = mockCourses
        
        // Test
        await viewModel.loadCourses()
        
        // Verify
        XCTAssertEqual(viewModel.courses.count, 2)
        XCTAssertEqual(viewModel.courses[0].name, "Course 1")
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testLoadCoursesError() async {
        // Setup mock error
        mockClient.mockError = CanvasError.httpError(statusCode: 500)
        
        // Test
        await viewModel.loadCourses()
        
        // Verify
        XCTAssertTrue(viewModel.courses.isEmpty)
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }
}
```

## UI Testing

Test SwiftUI views using ViewInspector:

```swift
class CourseViewTests: XCTestCase {
    func testCourseView() throws {
        let course = Course(
            id: 1,
            name: "Test Course",
            courseCode: "TEST101",
            workflowState: "available"
        )
        
        let view = CourseView(course: course)
        
        let title = try view.inspect().find(viewWithId: "courseTitle").text().string()
        XCTAssertEqual(title, "Test Course")
        
        let code = try view.inspect().find(viewWithId: "courseCode").text().string()
        XCTAssertEqual(code, "TEST101")
    }
}
```

## Mocking

### Mock URL Session

```swift
class MockURLSession: URLSessionProtocol {
    var mockResponse: (Data, URLResponse)!
    var mockError: Error?
    
    func data(
        for request: URLRequest,
        delegate: URLSessionTaskDelegate?
    ) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        return mockResponse
    }
}
```

### Mock Canvas Client

```swift
class MockCanvasClient: CanvasClientProtocol {
    var mockCourses: [Course] = []
    var mockModules: [Module] = []
    var mockError: Error?
    
    func getCourses() async throws -> [Course] {
        if let error = mockError {
            throw error
        }
        return mockCourses
    }
    
    func getModules(courseId: Int) async throws -> [Module] {
        if let error = mockError {
            throw error
        }
        return mockModules
    }
}
```

## Test Coverage

Run tests with coverage:

```bash
swift test --enable-code-coverage
```

Generate coverage report:

```bash
xcrun llvm-cov report .build/debug/CanvasKitPackageTests.xctest/Contents/MacOS/CanvasKitPackageTests
```

## Best Practices

1. **Test Organization**
   - Group related tests in test cases
   - Use clear, descriptive test names
   - Follow the Arrange-Act-Assert pattern

2. **Mocking**
   - Mock external dependencies
   - Use protocols for testability
   - Keep mocks simple and focused

3. **Async Testing**
   - Use async/await for asynchronous tests
   - Test timeout scenarios
   - Handle task cancellation

4. **Error Testing**
   - Test error scenarios
   - Verify error messages
   - Test recovery paths

5. **UI Testing**
   - Test view hierarchy
   - Test user interactions
   - Test accessibility

## See Also

- [Client API Reference](client-api.md) for API details
- [Error Handling](error-handling.md) for error scenarios
- [Best Practices](advanced/best-practices.md) for general guidelines 