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
    public let moduleId: Int
    public let title: String
    public let position: Int
    public let indent: Int
    public let type: String
    public let contentId: Int?
    public let htmlUrl: String?
    public let url: String?
    public let pageUrl: String?
    public let externalUrl: String?
    public let newTab: Bool?
    public let completionRequirement: CompletionRequirement?
    
    enum CodingKeys: String, CodingKey {
        case id
        case moduleId = "module_id"
        case title
        case position
        case indent
        case type
        case contentId = "content_id"
        case htmlUrl = "html_url"
        case url
        case pageUrl = "page_url"
        case externalUrl = "external_url"
        case newTab = "new_tab"
        case completionRequirement = "completion_requirement"
    }
}

public struct CompletionRequirement: Codable, Sendable {
    public let type: String
    public let minScore: Double?
    public let completed: Bool?
    
    enum CodingKeys: String, CodingKey {
        case type
        case minScore = "min_score"
        case completed
    }
} 