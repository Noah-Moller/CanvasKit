import XCTest
@testable import CanvasKit

final class CanvasClientTests: XCTestCase {
    var client: CanvasClient!
    
    override func setUp() {
        super.setUp()
        client = CanvasClient(
            domain: "saac.instructure.com",
            token: "8070~ETJMArXrv6uZMRVHU62DNNKXkL2RxakRUM86aYk7BUYmRHXNKtxz7UF4w46xtuyC"
        )
    }
    
    override func tearDown() {
        client = nil
        super.tearDown()
    }
    
    func testGetCourses() async throws {
        let courses = try await client.getCourses()
        XCTAssertFalse(courses.isEmpty, "Should fetch at least one course")
        
        // Test first course properties
        let firstCourse = courses[0]
        XCTAssertGreaterThan(firstCourse.id, 0)
        XCTAssertFalse(firstCourse.name.isEmpty)
        XCTAssertFalse(firstCourse.courseCode.isEmpty)
        
        // Print course details for verification
        print("Found courses:")
        for course in courses {
            print("- \(course.name) (\(course.courseCode))")
        }
    }
    
    func testGetModules() async throws {
        // First get courses to get a valid course ID
        let courses = try await client.getCourses()
        XCTAssertFalse(courses.isEmpty, "Need at least one course for testing")
        
        print("\nChecking modules for all courses:")
        for course in courses {
            print("\nModules for course \(course.name):")
            let modules = try await client.getModules(courseId: course.id)
            
            if modules.isEmpty {
                print("- No modules found")
            } else {
                for module in modules {
                    print("- \(module.name)")
                    if let items = module.items {
                        for item in items {
                            print("  • \(item.title) (Type: \(item.type))")
                        }
                    }
                }
            }
            
            // Test module properties if they exist
            if let firstModule = modules.first {
                XCTAssertGreaterThan(firstModule.id, 0)
                XCTAssertFalse(firstModule.name.isEmpty)
                XCTAssertGreaterThanOrEqual(firstModule.position, 0)
            }
        }
    }
    
    func testGetModuleItemContent() async throws {
        // First get courses to get a valid course ID
        let courses = try await client.getCourses()
        XCTAssertFalse(courses.isEmpty, "Need at least one course for testing")
        
        // Try specific courses that are likely to have content
        let targetCourses = ["Year 11 Literature", "Year 11 Music", "XCode Swift UI"]
        
        print("\nChecking module content for specific courses:")
        for course in courses {
            guard targetCourses.contains(where: { course.name.contains($0) }) else { continue }
            
            print("\nChecking content in course: \(course.name)")
            let modules = try await client.getModules(courseId: course.id)
            
            for module in modules {
                print("\nModule: \(module.name)")
                if let items = module.items {
                    for item in items {
                        print("\nItem: \(item.title) (Type: \(item.type))")
                        do {
                            let content = try await client.getModuleItemContent(courseId: course.id, moduleItem: item)
                            print("- ID: \(content.id)")
                            print("- Title: \(content.title)")
                            if let description = content.description {
                                print("- Description: \(description)")
                            }
                            if let contentText = content.content {
                                let previewText = String(contentText.prefix(100)) + (contentText.count > 100 ? "..." : "")
                                print("- Content: \(previewText)")
                            }
                            if let url = content.url {
                                print("- URL: \(url)")
                            }
                            
                            // Test content properties
                            XCTAssertGreaterThan(content.id, 0)
                            XCTAssertFalse(content.title.isEmpty)
                            XCTAssertNotNil(content.createdAt)
                            XCTAssertNotNil(content.updatedAt)
                        } catch {
                            print("Error fetching content: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func testGetAssignments() async throws {
        // First get courses to get a valid course ID
        let courses = try await client.getCourses()
        XCTAssertFalse(courses.isEmpty, "Need at least one course for testing")
        
        let courseId = courses[0].id
        let assignments = try await client.getAssignments(courseId: courseId)
        
        // Print assignment details for verification
        print("\nAssignments for course \(courses[0].name):")
        for assignment in assignments {
            print("- \(assignment.name)")
            if let dueAt = assignment.dueAt {
                print("  Due: \(dueAt)")
            }
        }
        
        // Even if there are no assignments, the call should succeed
        // Test assignment properties if they exist
        if let firstAssignment = assignments.first {
            XCTAssertGreaterThan(firstAssignment.id, 0)
            XCTAssertFalse(firstAssignment.name.isEmpty)
            XCTAssertEqual(firstAssignment.courseId, courseId)
        }
    }
    
    func testInvalidToken() async {
        let invalidClient = CanvasClient(
            domain: "saac.instructure.com",
            token: "invalid_token"
        )
        
        do {
            _ = try await invalidClient.getCourses()
            XCTFail("Should throw an error for invalid token")
        } catch CanvasError.httpError(let statusCode) {
            XCTAssertEqual(statusCode, 401)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testGetGrades() async throws {
        // First get courses to get a valid course ID
        let courses = try await client.getCourses()
        XCTAssertFalse(courses.isEmpty, "Need at least one course for testing")
        
        print("\nChecking grades for all courses:")
        for course in courses {
            print("\nGrades for course \(course.name):")
            let grades = try await client.getGrades(courseId: course.id)
            
            for grade in grades {
                print("- Assignment ID: \(grade.assignmentId)")
                if let score = grade.score {
                    print("  Score: \(score)")
                }
                if let gradeStr = grade.grade {
                    print("  Grade: \(gradeStr)")
                }
                if let comments = grade.comments {
                    print("  Comments:")
                    for comment in comments {
                        print("    • \(comment.authorName): \(comment.comment)")
                    }
                }
            }
            
            // Test grade properties if they exist
            if let firstGrade = grades.first {
                XCTAssertGreaterThan(firstGrade.id, 0)
                XCTAssertGreaterThan(firstGrade.assignmentId, 0)
            }
        }
    }
    
    func testGetTodos() async throws {
        let todos = try await client.getTodos()
        
        // Print todos for debugging
        print("\nTodos:")
        for todo in todos {
            print("\nTodo:")
            print("  ID: \(todo.id)")
            print("  Title: \(todo.title)")
            print("  Type: \(todo.type)")
            if let courseId = todo.courseId {
                print("  Course ID: \(courseId)")
            }
            if let assignmentId = todo.assignmentId {
                print("  Assignment ID: \(assignmentId)")
            }
            if let dueAt = todo.dueAt {
                print("  Due: \(dueAt)")
            }
        }
        
        // Verify todos
        XCTAssertFalse(todos.isEmpty, "Todos should not be empty")
        
        if let firstTodo = todos.first {
            XCTAssertGreaterThan(firstTodo.id, 0)
            XCTAssertFalse(firstTodo.title.isEmpty)
            XCTAssertFalse(firstTodo.type.isEmpty)
        }
    }
} 