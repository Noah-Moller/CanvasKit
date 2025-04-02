import Foundation

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
    
    enum CodingKeys: String, CodingKey {
        case id
        case assignmentId = "assignment_id"
        case score
        case grade
        case submittedAt = "submitted_at"
        case gradedAt = "graded_at"
        case excused
        case late
        case missing
        case comments = "submission_comments"
    }
}

public struct SubmissionComment: Codable, Identifiable, Sendable {
    public let id: Int
    public let authorId: Int
    public let authorName: String
    public let comment: String
    public let createdAt: Date
    public let mediaComment: MediaComment?
    public let attachments: [Attachment]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case authorId = "author_id"
        case authorName = "author_name"
        case comment
        case createdAt = "created_at"
        case mediaComment = "media_comment"
        case attachments
    }
}

public struct MediaComment: Codable, Sendable {
    public let contentType: String
    public let displayName: String?
    public let mediaId: String
    public let mediaType: String
    public let url: String
    
    enum CodingKeys: String, CodingKey {
        case contentType = "content-type"
        case displayName = "display_name"
        case mediaId = "media_id"
        case mediaType = "media_type"
        case url
    }
}

public struct Attachment: Codable, Identifiable, Sendable {
    public let id: Int
    public let displayName: String
    public let filename: String
    public let contentType: String
    public let url: String
    public let size: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case filename
        case contentType = "content-type"
        case url
        case size
    }
} 