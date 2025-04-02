import Foundation

public struct Todo: Codable, Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let message: String?
    public let type: String
    public let courseId: Int?
    public let assignmentId: Int?
    public let htmlUrl: String?
    public let createdAt: Date?
    public let updatedAt: Date?
    public let dueAt: Date?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case message
        case type
        case courseId = "course_id"
        case assignmentId = "assignment_id"
        case htmlUrl = "html_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case dueAt = "due_at"
    }
} 