import Foundation
import SwiftData
import PencilKit

#if canImport(UIKit)
import UIKit
#endif

/// Main document model for multi-page documents
@Model
public class CanvasDocument {
    public var id: UUID
    public var title: String
    public var createdAt: Date
    public var modifiedAt: Date
    public var paperSize: PaperSize
    public var pages: [CanvasPage]
    public var documentSettings: DocumentSettings
    
    public init(title: String, paperSize: PaperSize = .a4, settings: DocumentSettings = DocumentSettings()) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.paperSize = paperSize
        self.documentSettings = settings
        self.pages = [CanvasPage(pageNumber: 1, paperSize: paperSize)]
    }
    
    /// Add a new page to the document
    public func addPage(template: PageTemplate = .blank) {
        let newPageNumber = pages.count + 1
        let newPage = CanvasPage(pageNumber: newPageNumber, paperSize: paperSize, template: template)
        pages.append(newPage)
        modifiedAt = Date()
    }
    
    /// Remove a page from the document
    public func removePage(at index: Int) {
        guard index < pages.count && index >= 0 else { return }
        
        // Don't allow removing the last page
        guard pages.count > 1 else { return }
        
        pages.remove(at: index)
        
        // Renumber remaining pages
        for (newIndex, page) in pages.enumerated() {
            page.pageNumber = newIndex + 1
        }
        
        modifiedAt = Date()
    }
    
    /// Insert a page at a specific index
    public func insertPage(at index: Int, template: PageTemplate = .blank) {
        let newPage = CanvasPage(pageNumber: index + 1, paperSize: paperSize, template: template)
        pages.insert(newPage, at: index)
        
        // Renumber all pages
        for (newIndex, page) in pages.enumerated() {
            page.pageNumber = newIndex + 1
        }
        
        modifiedAt = Date()
    }
    
    /// Get page count
    public var pageCount: Int {
        return pages.count
    }
    
    /// Check if document has any content
    public var hasContent: Bool {
        return pages.contains { $0.drawing.hasContent }
    }
}

/// Individual page model within a document
@Model
public class CanvasPage {
    public var id: UUID
    public var pageNumber: Int
    public var drawingData: Data
    public var paperSize: PaperSize
    public var template: PageTemplate
    public var createdAt: Date
    public var modifiedAt: Date
    public var pageSettings: PageSettings
    
    public init(pageNumber: Int, paperSize: PaperSize, template: PageTemplate = .blank, settings: PageSettings = PageSettings()) {
        self.id = UUID()
        self.pageNumber = pageNumber
        self.drawingData = PKDrawing().dataRepresentation()
        self.paperSize = paperSize
        self.template = template
        self.pageSettings = settings
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

/// Infinite whiteboard canvas model
@Model
public class WhiteboardCanvas {
    public var id: UUID
    public var title: String
    public var drawingData: Data
    public var contentSize: CGSize
    public var showGrid: Bool
    public var snapToGrid: Bool
    public var gridSize: CGFloat
    public var backgroundColor: Data
    public var createdAt: Date
    public var modifiedAt: Date
    public var canvasSettings: CanvasSettings
    
    public init(title: String, settings: CanvasSettings = CanvasSettings()) {
        self.id = UUID()
        self.title = title
        self.drawingData = PKDrawing().dataRepresentation()
        self.contentSize = CGSize(width: 2000, height: 2000)
        self.showGrid = false
        self.snapToGrid = false
        self.gridSize = 20.0
        
        #if canImport(UIKit)
        self.backgroundColor = UIColor.white.toData()
        #else
        self.backgroundColor = Data() // Placeholder for macOS
        #endif
        
        self.canvasSettings = settings
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
    
    /// Get the background color
    #if canImport(UIKit)
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
    public func expandContentSizeIfNeeded() {
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
        }
    }
    
    /// Check if canvas has content
    public var hasContent: Bool {
        return drawing.hasContent
    }
}

/// Document-level settings
public struct DocumentSettings: Codable, Sendable, Equatable {
    public var defaultTemplate: PageTemplate
    public var autoSave: Bool
    public var version: Int
    
    public init(defaultTemplate: PageTemplate = .blank, autoSave: Bool = true, version: Int = 1) {
        self.defaultTemplate = defaultTemplate
        self.autoSave = autoSave
        self.version = version
    }
}

/// Page-level settings
public struct PageSettings: Codable, Sendable, Equatable {
    public var showTemplate: Bool
    public var templateOpacity: CGFloat
    public var pageOrientation: PageOrientation
    
    public init(showTemplate: Bool = true, templateOpacity: CGFloat = 0.3, pageOrientation: PageOrientation = .portrait) {
        self.showTemplate = showTemplate
        self.templateOpacity = templateOpacity
        self.pageOrientation = pageOrientation
    }
}

/// Canvas-level settings
public struct CanvasSettings: Codable, Sendable, Equatable {
    public var zoomRange: ClosedRange<CGFloat>
    public var defaultZoom: CGFloat
    public var showRuler: Bool
    public var enablePalmRejection: Bool
    public var drawingPolicy: DrawingPolicy
    
    public init(
        zoomRange: ClosedRange<CGFloat> = 0.1...5.0,
        defaultZoom: CGFloat = 1.0,
        showRuler: Bool = false,
        enablePalmRejection: Bool = true,
        drawingPolicy: DrawingPolicy = .anyInput
    ) {
        self.zoomRange = zoomRange
        self.defaultZoom = defaultZoom
        self.showRuler = showRuler
        self.enablePalmRejection = enablePalmRejection
        self.drawingPolicy = drawingPolicy
    }
}

/// Page orientation
public enum PageOrientation: String, CaseIterable, Codable, Sendable {
    case portrait, landscape
    
    public var displayName: String {
        switch self {
        case .portrait: return "Portrait"
        case .landscape: return "Landscape"
        }
    }
}

/// Drawing policy for canvas input
public enum DrawingPolicy: String, CaseIterable, Codable, Sendable {
    case anyInput, pencilOnly, penOnly
    
    public var displayName: String {
        switch self {
        case .anyInput: return "Any Input"
        case .pencilOnly: return "Pencil Only"
        case .penOnly: return "Pen Only"
        }
    }
}