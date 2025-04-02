# API Models

CanvasKit provides a set of Swift models that map to Canvas LMS API responses. All models conform to `Codable`, `Identifiable`, and `Sendable` protocols.

## Core Models

### Course

Represents a Canvas course.

```swift
public struct Course: Codable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let courseCode: String
    public let workflowState: String?
}
```

### Module

Represents a course module.

```swift
public struct Module: Codable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let position: Int
    public let items: [ModuleItem]?
}
```

### ModuleItem

Represents an item within a module.

```swift
public struct ModuleItem: Codable, Identifiable, Sendable {
    public let id: Int
    public let moduleId: Int
    public let title: String
    public let type: String
    public let position: Int
    public let url: String?
    public let htmlUrl: String?
}
```

### ModuleItemContent

Represents the content of a module item.

```swift
public struct ModuleItemContent: Codable, Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let description: String?
    public let content: String?
    public let htmlContent: String?
    public let url: String?
    public let fileUrl: String?
    public let mimeType: String?
    public let createdAt: Date?
    public let updatedAt: Date?
}
```

### Assignment

Represents a course assignment.

```swift
public struct Assignment: Codable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let description: String?
    public let htmlDescription: String?
    public let dueAt: Date?
    public let pointsPossible: Double?
    public let courseId: Int
    public let htmlUrl: String?
    public let submissionTypes: [String]
    public let isQuiz: Bool
    public let locked: Bool
    public let allowedAttempts: Int?
    public let gradingType: String?
    public let published: Bool
}
```

### Grade

Represents a grade for an assignment.

```swift
public struct Grade: Codable, Identifiable, Sendable {
    public let id: Int
    public let assignmentId: Int
    public let score: Double?
    public let grade: String?
    public let submittedAt: Date?
    public let gradedAt: Date?
    public let excused: Bool?
    public let late: Bool?
    public let missing: Bool?
    public let comments: [SubmissionComment]?
}
```

### SubmissionComment

Represents a comment on a submission.

```swift
public struct SubmissionComment: Codable, Identifiable, Sendable {
    public let id: Int
    public let authorId: Int
    public let authorName: String
    public let comment: String
    public let createdAt: Date
    public let mediaComment: MediaComment?
    public let attachments: [Attachment]?
}
```

## Helper Models

### MediaComment

Represents a media (audio/video) comment.

```swift
public struct MediaComment: Codable, Sendable {
    public let contentType: String
    public let displayName: String?
    public let mediaId: String
    public let mediaType: String
    public let url: String
}
```

### Attachment

Represents a file attachment.

```swift
public struct Attachment: Codable, Identifiable, Sendable {
    public let id: Int
    public let filename: String
    public let displayName: String
    public let contentType: String
    public let url: String
    public let size: Int
}
```

## Error Types

### CanvasError

Represents errors that can occur when interacting with the Canvas API.

```swift
public enum CanvasError: Error {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
}
```

## Best Practices

1. Always check for optional values before using them
2. Use the `htmlDescription` for assignments when available
3. Handle all error cases appropriately
4. Use proper date formatting when displaying dates
5. Check `submissionTypes` before allowing submissions

## Example Usage

```swift
// Fetch and display course assignments
func loadAssignments(for course: Course) async throws {
    let assignments = try await client.getAssignments(courseId: course.id)
    
    for assignment in assignments {
        print("Assignment: \(assignment.name)")
        if let dueAt = assignment.dueAt {
            print("Due: \(dueAt)")
        }
        if let points = assignment.pointsPossible {
            print("Points: \(points)")
        }
    }
}

// Get grades for an assignment
func loadGrades(courseId: Int) async throws {
    let grades = try await client.getGrades(courseId: courseId)
    
    for grade in grades {
        print("Assignment ID: \(grade.assignmentId)")
        if let score = grade.score {
            print("Score: \(score)")
        }
        if let comments = grade.comments {
            for comment in comments {
                print("Comment by \(comment.authorName): \(comment.comment)")
            }
        }
    }
}
```

## See Also

- [Client API Reference](client-api.md) for methods to interact with these models
- [Error Handling](error-handling.md) for more details on error handling
- [Best Practices](advanced/best-practices.md) for model usage guidelines 