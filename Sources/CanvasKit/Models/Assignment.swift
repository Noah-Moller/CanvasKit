import Foundation

public struct Assignment: Codable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let description: String?
    public let dueAt: Date?
    public let pointsPossible: Double?
    public let courseId: Int
    public let htmlUrl: String
    public let submissionTypes: [String]
    public let isQuiz: Bool
    public let locked: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case dueAt = "due_at"
        case pointsPossible = "points_possible"
        case courseId = "course_id"
        case htmlUrl = "html_url"
        case submissionTypes = "submission_types"
        case isQuiz = "is_quiz_assignment"
        case locked
    }
} 