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
        case name
        case displayName = "display_name"
        case description
        case content = "body"
        case htmlContent = "html_content"
        case url = "html_url"
        case fileUrl = "url"
        case mimeType = "mime_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(id: Int, title: String, description: String?, content: String?, htmlContent: String?, url: String?, fileUrl: String?, mimeType: String?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.title = title
        self.description = description
        self.content = content
        self.htmlContent = htmlContent
        self.url = url
        self.fileUrl = fileUrl
        self.mimeType = mimeType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(Int.self, forKey: .id)
        
        // Try different possible title keys based on content type
        if let displayName = try? container.decode(String.self, forKey: .displayName) {
            title = displayName
        } else if let name = try? container.decode(String.self, forKey: .name) {
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        
        if let description = description {
            try container.encode(description, forKey: .description)
        }
        
        if let content = content {
            try container.encode(content, forKey: .content)
        }
        
        if let htmlContent = htmlContent {
            try container.encode(htmlContent, forKey: .htmlContent)
        }
        
        if let url = url {
            try container.encode(url, forKey: .url)
        }
        
        if let fileUrl = fileUrl {
            try container.encode(fileUrl, forKey: .fileUrl)
        }
        
        if let mimeType = mimeType {
            try container.encode(mimeType, forKey: .mimeType)
        }
        
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
} 