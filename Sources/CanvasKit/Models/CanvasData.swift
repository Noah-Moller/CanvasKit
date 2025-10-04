import Foundation
import PencilKit
import SwiftUI

/// Lightweight canvas data wrapper that can be easily serialized to/from Data
public struct CanvasData: Codable, Equatable {
    /// Unique identifier for the canvas
    public let id: UUID
    
    /// Canvas title
    public var title: String
    
    /// Canvas type
    public var canvasType: CanvasType
    
    /// Drawing data (PKDrawing serialized to Data)
    public var drawingData: Data
    
    /// Canvas settings
    public var settings: CanvasSettings
    
    /// Creation timestamp
    public let createdAt: Date
    
    /// Last modification timestamp
    public var modifiedAt: Date
    
    /// Canvas-specific metadata
    public var metadata: CanvasMetadata
    
    public init(
        id: UUID = UUID(),
        title: String,
        canvasType: CanvasType,
        settings: CanvasSettings = CanvasSettings(),
        metadata: CanvasMetadata = CanvasMetadata()
    ) {
        self.id = id
        self.title = title
        self.canvasType = canvasType
        self.drawingData = PKDrawing().dataRepresentation()
        self.settings = settings
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.metadata = metadata
    }
    
    /// Get the PKDrawing object
    public var drawing: PKDrawing {
        get {
            (try? PKDrawing(data: drawingData)) ?? PKDrawing()
        }
        set {
            drawingData = newValue.dataRepresentation()
            modifiedAt = Date()
        }
    }
    
    /// Check if canvas has content
    public var hasContent: Bool {
        return drawing.hasContent
    }
    
    /// Convert to Data for storage
    public func toData() -> Data {
        return (try? JSONEncoder().encode(self)) ?? Data()
    }
    
    /// Create from Data
    public static func fromData(_ data: Data) -> CanvasData? {
        return try? JSONDecoder().decode(CanvasData.self, from: data)
    }
}

/// Canvas type enumeration
public enum CanvasType: String, Codable, CaseIterable, Equatable {
    case document = "document"
    case whiteboard = "whiteboard"
    
    public var displayName: String {
        switch self {
        case .document: return "Document"
        case .whiteboard: return "Whiteboard"
        }
    }
}

/// Canvas-specific metadata
public struct CanvasMetadata: Codable, Equatable {
    /// For document canvases: paper size and template
    public var paperSize: PaperSize?
    public var pageTemplate: PageTemplate?
    
    /// For whiteboard canvases: grid and background settings
    public var showGrid: Bool?
    public var snapToGrid: Bool?
    public var gridSize: CGFloat?
    public var backgroundColor: Data?
    
    /// Content size for whiteboard canvases
    public var contentSize: CGSize?
    
    /// Page count for document canvases
    public var pageCount: Int?
    
    public init(
        paperSize: PaperSize? = nil,
        pageTemplate: PageTemplate? = nil,
        showGrid: Bool? = nil,
        snapToGrid: Bool? = nil,
        gridSize: CGFloat? = nil,
        backgroundColor: Data? = nil,
        contentSize: CGSize? = nil,
        pageCount: Int? = nil
    ) {
        self.paperSize = paperSize
        self.pageTemplate = pageTemplate
        self.showGrid = showGrid
        self.snapToGrid = snapToGrid
        self.gridSize = gridSize
        self.backgroundColor = backgroundColor
        self.contentSize = contentSize
        self.pageCount = pageCount
    }
}

/// Document-specific canvas data (for multi-page documents)
public struct DocumentCanvasData: Codable, Equatable {
    /// Unique identifier for the document
    public let id: UUID
    
    /// Document title
    public var title: String
    
    /// Paper size for all pages
    public var paperSize: PaperSize
    
    /// Document settings
    public var settings: DocumentSettings
    
    /// Array of page data
    public var pages: [PageData]
    
    /// Creation timestamp
    public let createdAt: Date
    
    /// Last modification timestamp
    public var modifiedAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        paperSize: PaperSize = .a4,
        settings: DocumentSettings = DocumentSettings(),
        pages: [PageData] = [PageData(pageNumber: 1, paperSize: .a4)]
    ) {
        self.id = id
        self.title = title
        self.paperSize = paperSize
        self.settings = settings
        self.pages = pages
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    /// Add a new page
    public mutating func addPage(template: PageTemplate = .blank) {
        let newPageNumber = pages.count + 1
        let newPage = PageData(pageNumber: newPageNumber, paperSize: paperSize, template: template)
        pages.append(newPage)
        modifiedAt = Date()
    }
    
    /// Remove a page at index
    public mutating func removePage(at index: Int) {
        guard index < pages.count && index >= 0 && pages.count > 1 else { return }
        pages.remove(at: index)
        
        // Renumber remaining pages
        for (newIndex, _) in pages.enumerated() {
            pages[newIndex].pageNumber = newIndex + 1
        }
        
        modifiedAt = Date()
    }
    
    /// Insert a page at index
    public mutating func insertPage(at index: Int, template: PageTemplate = .blank) {
        let newPage = PageData(pageNumber: index + 1, paperSize: paperSize, template: template)
        pages.insert(newPage, at: index)
        
        // Renumber all pages
        for (newIndex, _) in pages.enumerated() {
            pages[newIndex].pageNumber = newIndex + 1
        }
        
        modifiedAt = Date()
    }
    
    /// Get page count
    public var pageCount: Int {
        return pages.count
    }
    
    /// Check if document has any content
    public var hasContent: Bool {
        return pages.contains { $0.hasContent }
    }
    
    /// Convert to Data for storage
    public func toData() -> Data {
        return (try? JSONEncoder().encode(self)) ?? Data()
    }
    
    /// Create from Data
    public static func fromData(_ data: Data) -> DocumentCanvasData? {
        return try? JSONDecoder().decode(DocumentCanvasData.self, from: data)
    }
}

/// Individual page data within a document
public struct PageData: Codable, Equatable {
    /// Unique identifier for the page
    public let id: UUID
    
    /// Page number (1-based)
    public var pageNumber: Int
    
    /// Drawing data for this page
    public var drawingData: Data
    
    /// Paper size
    public var paperSize: PaperSize
    
    /// Page template
    public var template: PageTemplate
    
    /// Page settings
    public var settings: PageSettings
    
    /// Creation timestamp
    public let createdAt: Date
    
    /// Last modification timestamp
    public var modifiedAt: Date
    
    public init(
        id: UUID = UUID(),
        pageNumber: Int,
        paperSize: PaperSize,
        template: PageTemplate = .blank,
        settings: PageSettings = PageSettings()
    ) {
        self.id = id
        self.pageNumber = pageNumber
        self.drawingData = PKDrawing().dataRepresentation()
        self.paperSize = paperSize
        self.template = template
        self.settings = settings
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    /// Get the PKDrawing object
    public var drawing: PKDrawing {
        get {
            (try? PKDrawing(data: drawingData)) ?? PKDrawing()
        }
        set {
            drawingData = newValue.dataRepresentation()
            modifiedAt = Date()
        }
    }
    
    /// Check if page has content
    public var hasContent: Bool {
        return drawing.hasContent
    }
    
    /// Get page size in points
    public var pageSize: CGSize {
        return paperSize.cgSize
    }
}

/// Whiteboard-specific canvas data (for infinite canvases)
public struct WhiteboardCanvasData: Codable, Equatable {
    /// Unique identifier for the canvas
    public let id: UUID
    
    /// Canvas title
    public var title: String
    
    /// Drawing data
    public var drawingData: Data
    
    /// Canvas content size
    public var contentSize: CGSize
    
    /// Grid settings
    public var showGrid: Bool
    public var snapToGrid: Bool
    public var gridSize: CGFloat
    
    /// Background color data
    public var backgroundColor: Data
    
    /// Canvas settings
    public var settings: CanvasSettings
    
    /// Creation timestamp
    public let createdAt: Date
    
    /// Last modification timestamp
    public var modifiedAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        contentSize: CGSize = CGSize(width: 2000, height: 2000),
        settings: CanvasSettings = CanvasSettings()
    ) {
        self.id = id
        self.title = title
        self.drawingData = PKDrawing().dataRepresentation()
        self.contentSize = contentSize
        self.showGrid = false
        self.snapToGrid = false
        self.gridSize = 20.0
        
        #if canImport(UIKit)
        self.backgroundColor = UIColor.white.toData()
        #else
        self.backgroundColor = Data()
        #endif
        
        self.settings = settings
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    /// Get the PKDrawing object
    public var drawing: PKDrawing {
        get {
            (try? PKDrawing(data: drawingData)) ?? PKDrawing()
        }
        set {
            drawingData = newValue.dataRepresentation()
            modifiedAt = Date()
        }
    }
    
    #if canImport(UIKit)
    /// Get the background color
    public var backgroundUIColor: UIColor {
        get {
            return UIColor.fromData(backgroundColor) ?? .white
        }
        set {
            backgroundColor = newValue.toData()
        }
    }
    #endif
    
    /// Expand content size if needed based on drawing bounds
    public mutating func expandContentSizeIfNeeded() {
        let bounds = drawing.boundingRect
        let padding: CGFloat = 200
        
        // Handle infinite bounds from empty drawings
        guard bounds.width.isFinite && bounds.height.isFinite && bounds.width > 0 && bounds.height > 0 else {
            return // Don't expand for empty or infinite bounds
        }
        
        let requiredWidth = bounds.maxX + padding
        let requiredHeight = bounds.maxY + padding
        
        if requiredWidth > contentSize.width || requiredHeight > contentSize.height {
            contentSize = CGSize(
                width: max(contentSize.width, requiredWidth),
                height: max(contentSize.height, requiredHeight)
            )
            modifiedAt = Date()
        }
    }
    
    /// Check if canvas has content
    public var hasContent: Bool {
        return drawing.hasContent
    }
    
    /// Convert to Data for storage
    public func toData() -> Data {
        return (try? JSONEncoder().encode(self)) ?? Data()
    }
    
    /// Create from Data
    public static func fromData(_ data: Data) -> WhiteboardCanvasData? {
        return try? JSONDecoder().decode(WhiteboardCanvasData.self, from: data)
    }
}
