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
        
        let courseId = courses[0].id
        let modules = try await client.getModules(courseId: courseId)
        
        // Print module details for verification
        print("\nModules for course \(courses[0].name):")
        for module in modules {
            print("- \(module.name)")
            if let items = module.items {
                for item in items {
                    print("  • \(item.title)")
                }
            }
        }
        
        // Even if there are no modules, the call should succeed
        // Test module properties if they exist
        if let firstModule = modules.first {
            XCTAssertGreaterThan(firstModule.id, 0)
            XCTAssertFalse(firstModule.name.isEmpty)
            XCTAssertGreaterThanOrEqual(firstModule.position, 0)
        }
    }
    
    func testGetModuleItemContent() async throws {
        // First get courses to get a valid course ID
        let courses = try await client.getCourses()
        XCTAssertFalse(courses.isEmpty, "Need at least one course for testing")
        
        // Try each course until we find one with module items
        var moduleItemFound = false
        var content: ModuleItemContent?
        var foundItem: ModuleItem?
        var foundCourseId: Int?
        
        for course in courses {
            let modules = try await client.getModules(courseId: course.id)
            
            if let firstModule = modules.first,
               let firstItem = firstModule.items?.first {
                moduleItemFound = true
                foundItem = firstItem
                foundCourseId = course.id
                content = try await client.getModuleItemContent(courseId: course.id, moduleItem: firstItem)
                print("\nFound module item in course: \(course.name)")
                break
            }
        }
        
        guard moduleItemFound,
              let content = content,
              let foundItem = foundItem else {
            throw XCTSkip("No module items available in any course")
        }
        
        // Print content details for verification
        print("\nContent for module item '\(foundItem.title)':")
        print("- ID: \(content.id)")
        print("- Title: \(content.title)")
        if let description = content.description {
            print("- Description: \(description)")
        }
        if let contentText = content.content {
            print("- Content: \(contentText)")
        }
        if let url = content.url {
            print("- URL: \(url)")
        }
        
        // Test content properties
        XCTAssertGreaterThan(content.id, 0)
        XCTAssertFalse(content.title.isEmpty)
        XCTAssertNotNil(content.createdAt)
        XCTAssertNotNil(content.updatedAt)
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
} 