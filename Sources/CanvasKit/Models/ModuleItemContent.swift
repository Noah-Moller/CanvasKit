import Foundation

public struct ModuleItemContent: Codable, Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let description: String?
    public let content: String?
    public let htmlContent: String?
    public let url: String?
    public let fileUrl: String?
    public let mimeType: String?
    public let createdAt: Date
    public let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case content = "body"
        case htmlContent = "html_content"
        case url = "html_url"
        case fileUrl = "url"
        case mimeType = "mime_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(Int.self, forKey: .id)
        
        // Try different possible title keys based on content type
        if let name = try? container.decode(String.self, forKey: .title) {
            title = name
        } else {
            title = try container.decode(String.self, forKey: .title)
        }
        
        // Optional fields with different possible keys
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        // Content can be in different fields depending on the type
        if let bodyContent = try container.decodeIfPresent(String.self, forKey: .content) {
            content = bodyContent
        } else if let htmlContent = try container.decodeIfPresent(String.self, forKey: .htmlContent) {
            content = htmlContent
        } else {
            content = nil
        }
        
        htmlContent = try container.decodeIfPresent(String.self, forKey: .htmlContent)
        
        // URL handling
        if let contentUrl = try container.decodeIfPresent(String.self, forKey: .url) {
            url = contentUrl
        } else if let fileContentUrl = try container.decodeIfPresent(String.self, forKey: .fileUrl) {
            url = fileContentUrl
        } else {
            url = nil
        }
        
        fileUrl = try container.decodeIfPresent(String.self, forKey: .fileUrl)
        mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType)
        
        // Dates
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
} 