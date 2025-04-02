import Foundation
import Logging

public actor CanvasClient {
    private let baseURL: URL
    private let token: String
    private let logger = Logger(label: "com.canvaskit.client")
    private let decoder: JSONDecoder
    private let urlSession: URLSession
    
    public init(domain: String, token: String) {
        self.baseURL = URL(string: "https://\(domain)/api/v1")!
        self.token = token
        
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        self.urlSession = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        self.decoder.dateDecodingStrategy = .formatted(formatter)
    }
    
    // MARK: - API Methods
    
    public func getCourses() async throws -> [Course] {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("courses"), resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [
            URLQueryItem(name: "enrollment_state", value: "active"),
            URLQueryItem(name: "enrollment_type", value: "student"),
            URLQueryItem(name: "state[]", value: "available"),
            URLQueryItem(name: "include[]", value: "term"),
            URLQueryItem(name: "per_page", value: "100")
        ]
        
        guard let url = urlComponents.url else {
            throw CanvasError.invalidResponse
        }
        
        return try await fetch([Course].self, from: url)
    }
    
    public func getModules(courseId: Int) async throws -> [Module] {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("courses/\(courseId)/modules"), resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [
            URLQueryItem(name: "include[]", value: "items"),
            URLQueryItem(name: "include[]", value: "content_details"),
            URLQueryItem(name: "per_page", value: "100")
        ]
        
        guard let url = urlComponents.url else {
            throw CanvasError.invalidResponse
        }
        
        return try await fetch([Module].self, from: url)
    }
    
    public func getAssignments(courseId: Int) async throws -> [Assignment] {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("courses/\(courseId)/assignments"), resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [
            URLQueryItem(name: "include[]", value: "description"),
            URLQueryItem(name: "per_page", value: "100")
        ]
        
        guard let url = urlComponents.url else {
            throw CanvasError.invalidResponse
        }
        
        return try await fetch([Assignment].self, from: url)
    }
    
    public func getModuleItemContent(courseId: Int, moduleItem: ModuleItem) async throws -> ModuleItemContent {
        guard let contentId = moduleItem.contentId else {
            // For items without content ID (like external URLs), return a basic content object
            return ModuleItemContent(
                id: moduleItem.id,
                title: moduleItem.title,
                description: nil,
                content: nil,
                htmlContent: nil,
                url: moduleItem.externalUrl ?? moduleItem.url ?? moduleItem.htmlUrl,
                fileUrl: nil,
                mimeType: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        // Build URL based on item type
        let url: URL
        switch moduleItem.type.lowercased() {
        case "assignment":
            url = baseURL.appendingPathComponent("courses/\(courseId)/assignments/\(contentId)")
        case "quiz":
            url = baseURL.appendingPathComponent("courses/\(courseId)/quizzes/\(contentId)")
        case "discussion_topic":
            url = baseURL.appendingPathComponent("courses/\(courseId)/discussion_topics/\(contentId)")
        case "file":
            url = baseURL.appendingPathComponent("courses/\(courseId)/files/\(contentId)")
        case "page":
            url = baseURL.appendingPathComponent("courses/\(courseId)/pages/\(moduleItem.pageUrl ?? String(contentId))")
        default:
            throw CanvasError.unsupportedModuleItemType(moduleItem.type)
        }
        
        return try await fetch(ModuleItemContent.self, from: url)
    }
    
    // MARK: - New Methods
    
    public func getGrades(courseId: Int) async throws -> [Grade] {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent("courses/\(courseId)/students/submissions"), resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [
            URLQueryItem(name: "include[]", value: "submission_comments"),
            URLQueryItem(name: "include[]", value: "assignment"),
            URLQueryItem(name: "student_ids[]", value: "self"),
            URLQueryItem(name: "per_page", value: "100")
        ]
        
        guard let url = urlComponents.url else {
            throw CanvasError.invalidResponse
        }
        
        return try await fetch([Grade].self, from: url)
    }
    
    public func getTodos() async throws -> [Todo] {
        // First get courses to get valid course IDs
        let courses = try await getCourses()
        var todos: [Todo] = []
        
        // Get assignments for each course
        for course in courses {
            var urlComponents = URLComponents(url: baseURL.appendingPathComponent("api/v1/courses/\(course.id)/assignments"), resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [
                URLQueryItem(name: "needs_grading_count", value: "true"),
                URLQueryItem(name: "include[]", value: "submission"),
                URLQueryItem(name: "per_page", value: "100")
            ]
            
            guard let url = urlComponents.url else {
                throw CanvasError.invalidResponse
            }
            
            let assignments = try await fetch([Assignment].self, from: url)
            
            // Convert assignments to todos
            let assignmentTodos = assignments.map { assignment -> Todo in
                Todo(
                    id: assignment.id,
                    title: assignment.name,
                    message: assignment.description,
                    type: "Assignment",
                    courseId: course.id,
                    assignmentId: assignment.id,
                    htmlUrl: assignment.htmlUrl,
                    createdAt: nil,
                    updatedAt: nil,
                    dueAt: assignment.dueAt
                )
            }
            
            todos.append(contentsOf: assignmentTodos)
        }
        
        return todos
    }
    
    // MARK: - Private Methods
    
    private func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        let (data, response) = try await urlSession.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CanvasError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            logger.error("API request failed with status code: \(httpResponse.statusCode)")
            throw CanvasError.httpError(statusCode: httpResponse.statusCode)
        }
        
        do {
            return try decoder.decode(type, from: data)
        } catch {
            logger.error("Failed to decode response: \(error)")
            throw CanvasError.decodingError(error)
        }
    }
}

public enum CanvasError: Error {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case unsupportedModuleItemType(String)
} 