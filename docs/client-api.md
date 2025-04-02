# Client API Reference

The `CanvasClient` class provides a type-safe interface to the Canvas LMS API. All methods are asynchronous and use Swift's modern concurrency features.

## Initialization

Create a new client instance with your Canvas domain and API token:

```swift
let client = CanvasClient(
    domain: "your-canvas-domain.com",
    token: "your-api-token"
)
```

## Available Methods

### Courses

#### Get Courses

Fetches all courses for the authenticated user.

```swift
func getCourses() async throws -> [Course]
```

Example:
```swift
let courses = try await client.getCourses()
for course in courses {
    print("\(course.name) (\(course.courseCode))")
}
```

### Modules

#### Get Modules

Fetches all modules for a specific course.

```swift
func getModules(courseId: Int) async throws -> [Module]
```

Example:
```swift
let modules = try await client.getModules(courseId: courseId)
for module in modules {
    print("\(module.name) - \(module.items?.count ?? 0) items")
}
```

#### Get Module Item Content

Fetches the content for a specific module item.

```swift
func getModuleItemContent(courseId: Int, moduleItem: ModuleItem) async throws -> ModuleItemContent
```

Example:
```swift
let content = try await client.getModuleItemContent(courseId: courseId, moduleItem: item)
if let description = content.description {
    print("Description: \(description)")
}
```

### Assignments

#### Get Assignments

Fetches all assignments for a specific course.

```swift
func getAssignments(courseId: Int) async throws -> [Assignment]
```

Example:
```swift
let assignments = try await client.getAssignments(courseId: courseId)
for assignment in assignments {
    if let dueAt = assignment.dueAt {
        print("\(assignment.name) due at \(dueAt)")
    }
}
```

### Grades

#### Get Grades

Fetches all grades for a specific course.

```swift
func getGrades(courseId: Int) async throws -> [Grade]
```

Example:
```swift
let grades = try await client.getGrades(courseId: courseId)
for grade in grades {
    if let score = grade.score {
        print("Assignment \(grade.assignmentId): \(score)")
    }
}
```

## Error Handling

All methods can throw `CanvasError`:

```swift
public enum CanvasError: Error {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
}
```

Example error handling:
```swift
do {
    let courses = try await client.getCourses()
    // Handle success
} catch CanvasError.httpError(let statusCode) {
    print("HTTP error: \(statusCode)")
} catch CanvasError.invalidResponse {
    print("Invalid response from server")
} catch CanvasError.decodingError(let error) {
    print("Failed to decode response: \(error)")
} catch {
    print("Unknown error: \(error)")
}
```

## Best Practices

1. **Error Handling**
   - Always handle potential errors
   - Provide appropriate user feedback
   - Consider retry logic for transient failures

2. **Performance**
   - Cache results when appropriate
   - Use pagination for large result sets
   - Consider rate limiting for bulk operations

3. **Security**
   - Store API tokens securely
   - Use HTTPS for all requests
   - Validate server certificates

4. **Resource Management**
   - Release resources when no longer needed
   - Handle background/foreground transitions
   - Consider memory usage with large responses

## Example Usage Patterns

### Fetching Course Content

```swift
func loadCourseContent(courseId: Int) async {
    do {
        async let modules = client.getModules(courseId: courseId)
        async let assignments = client.getAssignments(courseId: courseId)
        async let grades = client.getGrades(courseId: courseId)
        
        let (moduleList, assignmentList, gradeList) = try await (modules, assignments, grades)
        
        // Process results
        print("Loaded \(moduleList.count) modules")
        print("Loaded \(assignmentList.count) assignments")
        print("Loaded \(gradeList.count) grades")
    } catch {
        print("Error loading course content: \(error)")
    }
}
```

### Efficient Module Content Loading

```swift
func loadModuleContent(courseId: Int, module: Module) async {
    guard let items = module.items else { return }
    
    // Load content for each item sequentially to avoid overwhelming the server
    for item in items {
        do {
            let content = try await client.getModuleItemContent(courseId: courseId, moduleItem: item)
            print("Loaded content for \(item.title)")
            // Process content
        } catch {
            print("Error loading content for \(item.title): \(error)")
            // Continue with next item
            continue
        }
    }
}
```

## See Also

- [API Models](models.md) for details on the data models
- [Error Handling](error-handling.md) for more error handling details
- [Best Practices](advanced/best-practices.md) for usage guidelines 