import Foundation

public struct Module: Codable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let position: Int
    public let unlockAt: Date?
    public let requireSequentialProgress: Bool
    public let publishFinalGrade: Bool
    public let items: [ModuleItem]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case position
        case unlockAt = "unlock_at"
        case requireSequentialProgress = "require_sequential_progress"
        case publishFinalGrade = "publish_final_grade"
        case items
    }
}

public struct ModuleItem: Codable, Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let position: Int
    public let type: String
    public let contentId: Int
    public let htmlUrl: String
    public let url: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case position
        case type
        case contentId = "content_id"
        case htmlUrl = "html_url"
        case url
    }
} 