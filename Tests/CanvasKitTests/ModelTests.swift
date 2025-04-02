import XCTest
@testable import CanvasKit

final class ModelTests: XCTestCase {
    let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }()
    
    func testCourseDecoding() throws {
        let json = """
        {
            "id": 12345,
            "name": "Test Course",
            "course_code": "TEST101",
            "start_at": "2024-01-01T00:00:00Z",
            "end_at": "2024-12-31T23:59:59Z",
            "enrollment_term": {
                "id": 678,
                "name": "Spring 2024",
                "start_at": "2024-01-01T00:00:00Z",
                "end_at": "2024-05-31T23:59:59Z"
            }
        }
        """.data(using: .utf8)!
        
        let course = try decoder.decode(Course.self, from: json)
        
        XCTAssertEqual(course.id, 12345)
        XCTAssertEqual(course.name, "Test Course")
        XCTAssertEqual(course.courseCode, "TEST101")
        XCTAssertNotNil(course.startAt)
        XCTAssertNotNil(course.endAt)
        XCTAssertNotNil(course.enrollmentTerm)
        XCTAssertEqual(course.enrollmentTerm?.id, 678)
        XCTAssertEqual(course.enrollmentTerm?.name, "Spring 2024")
    }
    
    func testModuleDecoding() throws {
        let json = """
        {
            "id": 54321,
            "name": "Module 1",
            "position": 1,
            "unlock_at": "2024-01-15T00:00:00Z",
            "require_sequential_progress": true,
            "publish_final_grade": false,
            "items": [
                {
                    "id": 111,
                    "title": "Assignment 1",
                    "position": 1,
                    "type": "Assignment",
                    "content_id": 222,
                    "html_url": "https://canvas.test/courses/1/modules/items/111",
                    "url": "https://canvas.test/api/v1/courses/1/assignments/222"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let module = try decoder.decode(Module.self, from: json)
        
        XCTAssertEqual(module.id, 54321)
        XCTAssertEqual(module.name, "Module 1")
        XCTAssertEqual(module.position, 1)
        XCTAssertNotNil(module.unlockAt)
        XCTAssertTrue(module.requireSequentialProgress)
        XCTAssertFalse(module.publishFinalGrade)
        XCTAssertNotNil(module.items)
        XCTAssertEqual(module.items?.count, 1)
        
        let item = module.items?.first
        XCTAssertEqual(item?.id, 111)
        XCTAssertEqual(item?.title, "Assignment 1")
        XCTAssertEqual(item?.type, "Assignment")
    }
    
    func testModuleItemContentDecoding() throws {
        // Test assignment content
        let assignmentJson = """
        {
            "id": 222,
            "title": "Assignment 1",
            "description": "This is the assignment description",
            "body": "This is the assignment content",
            "html_url": "https://canvas.test/courses/1/assignments/222",
            "created_at": "2024-01-15T00:00:00Z",
            "updated_at": "2024-01-15T00:00:00Z"
        }
        """.data(using: .utf8)!
        
        let assignmentContent = try decoder.decode(ModuleItemContent.self, from: assignmentJson)
        XCTAssertEqual(assignmentContent.id, 222)
        XCTAssertEqual(assignmentContent.title, "Assignment 1")
        XCTAssertEqual(assignmentContent.description, "This is the assignment description")
        XCTAssertEqual(assignmentContent.content, "This is the assignment content")
        XCTAssertEqual(assignmentContent.url, "https://canvas.test/courses/1/assignments/222")
        XCTAssertNotNil(assignmentContent.createdAt)
        XCTAssertNotNil(assignmentContent.updatedAt)
        
        // Test page content
        let pageJson = """
        {
            "id": 333,
            "title": "Course Page",
            "body": "This is the page content",
            "html_content": "<p>This is the page content</p>",
            "url": "https://canvas.test/courses/1/pages/course-page",
            "created_at": "2024-01-15T00:00:00Z",
            "updated_at": "2024-01-15T00:00:00Z"
        }
        """.data(using: .utf8)!
        
        let pageContent = try decoder.decode(ModuleItemContent.self, from: pageJson)
        XCTAssertEqual(pageContent.id, 333)
        XCTAssertEqual(pageContent.title, "Course Page")
        XCTAssertEqual(pageContent.content, "This is the page content")
        XCTAssertEqual(pageContent.htmlContent, "<p>This is the page content</p>")
        XCTAssertEqual(pageContent.fileUrl, "https://canvas.test/courses/1/pages/course-page")
        XCTAssertNotNil(pageContent.createdAt)
        XCTAssertNotNil(pageContent.updatedAt)
        
        // Test file content
        let fileJson = """
        {
            "id": 444,
            "title": "Course File",
            "mime_type": "application/pdf",
            "url": "https://canvas.test/files/444/download",
            "html_url": "https://canvas.test/courses/1/files/444",
            "created_at": "2024-01-15T00:00:00Z",
            "updated_at": "2024-01-15T00:00:00Z"
        }
        """.data(using: .utf8)!
        
        let fileContent = try decoder.decode(ModuleItemContent.self, from: fileJson)
        XCTAssertEqual(fileContent.id, 444)
        XCTAssertEqual(fileContent.title, "Course File")
        XCTAssertEqual(fileContent.mimeType, "application/pdf")
        XCTAssertEqual(fileContent.fileUrl, "https://canvas.test/files/444/download")
        XCTAssertEqual(fileContent.url, "https://canvas.test/courses/1/files/444")
        XCTAssertNotNil(fileContent.createdAt)
        XCTAssertNotNil(fileContent.updatedAt)
    }
    
    func testAssignmentDecoding() throws {
        let json = """
        {
            "id": 98765,
            "name": "Final Project",
            "description": "Submit your final project",
            "due_at": "2024-05-15T23:59:59Z",
            "points_possible": 100.0,
            "course_id": 12345,
            "html_url": "https://canvas.test/courses/12345/assignments/98765",
            "submission_types": ["online_upload", "online_text_entry"],
            "is_quiz_assignment": false,
            "locked": false
        }
        """.data(using: .utf8)!
        
        let assignment = try decoder.decode(Assignment.self, from: json)
        
        XCTAssertEqual(assignment.id, 98765)
        XCTAssertEqual(assignment.name, "Final Project")
        XCTAssertEqual(assignment.description, "Submit your final project")
        XCTAssertNotNil(assignment.dueAt)
        XCTAssertEqual(assignment.pointsPossible, 100.0)
        XCTAssertEqual(assignment.courseId, 12345)
        XCTAssertEqual(assignment.htmlUrl, "https://canvas.test/courses/12345/assignments/98765")
        XCTAssertEqual(assignment.submissionTypes, ["online_upload", "online_text_entry"])
        XCTAssertFalse(assignment.isQuiz)
        XCTAssertEqual(assignment.locked, false)
    }
} 