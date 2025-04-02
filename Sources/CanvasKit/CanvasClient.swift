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
        let url = baseURL.appendingPathComponent("courses")
        return try await fetch([Course].self, from: url)
    }
    
    public func getModules(courseId: Int) async throws -> [Module] {
        let url = baseURL.appendingPathComponent("courses/\(courseId)/modules")
        return try await fetch([Module].self, from: url)
    }
    
    public func getAssignments(courseId: Int) async throws -> [Assignment] {
        let url = baseURL.appendingPathComponent("courses/\(courseId)/assignments")
        return try await fetch([Assignment].self, from: url)
    }
    
    public func getModuleItemContent(courseId: Int, moduleItem: ModuleItem) async throws -> ModuleItemContent {
        // Build URL based on item type
        let url: URL
        switch moduleItem.type.lowercased() {
        case "assignment":
            url = baseURL.appendingPathComponent("courses/\(courseId)/assignments/\(moduleItem.contentId)")
        case "quiz":
            url = baseURL.appendingPathComponent("courses/\(courseId)/quizzes/\(moduleItem.contentId)")
        case "discussion_topic":
            url = baseURL.appendingPathComponent("courses/\(courseId)/discussion_topics/\(moduleItem.contentId)")
        case "file":
            url = baseURL.appendingPathComponent("courses/\(courseId)/files/\(moduleItem.contentId)")
        case "page":
            url = baseURL.appendingPathComponent("courses/\(courseId)/pages/\(moduleItem.contentId)")
        default:
            throw CanvasError.unsupportedModuleItemType(moduleItem.type)
        }
        
        return try await fetch(ModuleItemContent.self, from: url)
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