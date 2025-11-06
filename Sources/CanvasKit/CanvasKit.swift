// CanvasKit
// A SwiftUI package for Apple Pencil integration with document and whiteboard canvases
// https://github.com/yourusername/CanvasKit

import Foundation
import SwiftUI
import PencilKit
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

/// Main CanvasKit module
public struct CanvasKit {
    /// CanvasKit version
    public static let version = "2.0.0"
    
    /// Initialize CanvasKit
    public static func initialize() {
        print("CanvasKit v\(version) initialized")
    }
}

// MARK: - Public API

/// Create a new document canvas data
public func createDocumentCanvasData(
    title: String,
    paperSize: PaperSize = .a4
) -> Data {
    let document = DocumentCanvasData(title: title, paperSize: paperSize)
    return document.toData()
}

/// Create a new whiteboard canvas data
public func createWhiteboardCanvasData(
    title: String
) -> Data {
    let whiteboard = WhiteboardCanvasData(title: title)
    return whiteboard.toData()
}

/// Create a new canvas data (generic)
public func createCanvasData(
    title: String,
    type: CanvasType,
    settings: CanvasSettings = CanvasSettings()
) -> Data {
    let canvas = CanvasData(title: title, canvasType: type, settings: settings)
    return canvas.toData()
}

// MARK: - SwiftData Convenience Functions

/// Create a new document canvas (SwiftData model for backward compatibility)
public func createDocumentCanvas(
    title: String,
    paperSize: PaperSize = .a4,
    modelContext: ModelContext? = nil
) -> CanvasDocument {
    return CanvasDocument(title: title, paperSize: paperSize)
}

/// Create a new whiteboard canvas (SwiftData model for backward compatibility)
public func createWhiteboardCanvas(
    title: String,
    modelContext: ModelContext? = nil
) -> WhiteboardCanvas {
    return WhiteboardCanvas(title: title)
}

/// Create tools (iOS only)
#if canImport(UIKit)
/// Create a pen tool with custom properties
public func createPenTool(
    color: UIColor = .black,
    width: CGFloat = 5.0
) -> PKInkingTool {
    return PKInkingTool(.pen, color: color, width: width)
}

/// Create a pencil tool with custom properties
public func createPencilTool(
    color: UIColor = .black,
    width: CGFloat = 3.0
) -> PKInkingTool {
    return PKInkingTool(.pencil, color: color, width: width)
}

/// Create a marker tool with custom properties
public func createMarkerTool(
    color: UIColor = .black,
    width: CGFloat = 8.0
) -> PKInkingTool {
    return PKInkingTool(.marker, color: color, width: width)
}
#endif

/// Create an eraser tool
public func createEraserTool() -> PKEraserTool {
    return PKEraserTool(.bitmap)
}

/// Create a lasso tool for selection
public func createLassoTool() -> PKLassoTool {
    return PKLassoTool()
}

// MARK: - SwiftData Model Container

/// Create a SwiftData model container for CanvasKit
public func createModelContainer() -> ModelContainer {
    let schema = Schema([
        CanvasDocument.self,
        CanvasPage.self,
        WhiteboardCanvas.self
    ])
    
    let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        allowsSave: true
    )
    
    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}

// MARK: - Utility Functions

/// Export a drawing as an image (iOS only)
#if canImport(UIKit)
public func exportDrawingAsImage(
    _ drawing: PKDrawing,
    from bounds: CGRect? = nil,
    scale: CGFloat = 1.0
) -> UIImage? {
    let exportBounds = bounds ?? drawing.bounds
    return drawing.image(from: exportBounds, scale: scale)
}
#endif

/// Convert a drawing to data
public func drawingToData(_ drawing: PKDrawing) -> Data {
    return drawing.dataRepresentation()
}

/// Create a drawing from data
public func drawingFromData(_ data: Data) -> PKDrawing? {
    return try? PKDrawing(data: data)
}

/// Get paper size for a given name
public func paperSize(named name: String) -> PaperSize? {
    return PaperSize.allCases.first { $0.displayName.lowercased() == name.lowercased() }
}

/// Get template for a given name
public func pageTemplate(named name: String) -> PageTemplate? {
    return PageTemplate.allCases.first { $0.displayName.lowercased() == name.lowercased() }
}

// MARK: - Data Conversion Utilities

/// Extract document data from Data binding
public func getDocumentData(from data: Data) -> DocumentCanvasData? {
    return DocumentCanvasData.fromData(data)
}

/// Extract whiteboard data from Data binding
public func getWhiteboardData(from data: Data) -> WhiteboardCanvasData? {
    return WhiteboardCanvasData.fromData(data)
}

/// Extract generic canvas data from Data binding
public func getCanvasData(from data: Data) -> CanvasData? {
    return CanvasData.fromData(data)
}

/// Convert document data to Data
public func documentDataToData(_ document: DocumentCanvasData) -> Data {
    return document.toData()
}

/// Convert whiteboard data to Data
public func whiteboardDataToData(_ whiteboard: WhiteboardCanvasData) -> Data {
    return whiteboard.toData()
}

/// Convert generic canvas data to Data
public func canvasDataToData(_ canvas: CanvasData) -> Data {
    return canvas.toData()
}

// MARK: - High-Level View Convenience Functions

#if canImport(UIKit)
/// Create a complete notebook view with toolbar and page navigation
/// This is the recommended way to use CanvasKit for notebook experiences
public func createNotebookView(
    canvasData: Binding<Data>,
    settings: CanvasSettings = CanvasSettings(zoomRange: 0.5...3.0, defaultZoom: 1.0),
    onDataChanged: ((Data) -> Void)? = nil,
    onPageChanged: ((Int) -> Void)? = nil
) -> NotebookView {
    return NotebookView(
        canvasData: canvasData,
        settings: settings,
        onDataChanged: onDataChanged,
        onPageChanged: onPageChanged
    )
}

/// Create a complete canvas/whiteboard view with toolbar
/// This is the recommended way to use CanvasKit for freeform canvas experiences
public func createCanvasView(
    canvasData: Binding<Data>,
    settings: CanvasSettings = CanvasSettings(zoomRange: 0.1...5.0, defaultZoom: 1.0),
    onDataChanged: ((Data) -> Void)? = nil
) -> CanvasView {
    return CanvasView(
        canvasData: canvasData,
        settings: settings,
        onDataChanged: onDataChanged
    )
}
#endif

// MARK: - View Extensions

public extension View {
    /// Apply document canvas settings
    func documentCanvasSettings(
        paperSize: PaperSize = .a4,
        template: PageTemplate = .blank
    ) -> some View {
        self
    }
    
    /// Apply whiteboard canvas settings
    func whiteboardCanvasSettings(
        showGrid: Bool = false,
        snapToGrid: Bool = false,
        gridSize: CGFloat = 20.0
    ) -> some View {
        self
    }
}