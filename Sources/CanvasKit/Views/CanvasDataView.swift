import SwiftUI
import PencilKit

/// Generic canvas view that automatically detects canvas type and displays appropriate view
public struct CanvasDataView: View {
    // MARK: - Properties
    
    /// Binding to the canvas data
    @Binding public var canvasData: Data
    
    /// Canvas settings
    public var settings: CanvasSettings = CanvasSettings()
    
    /// Callbacks
    public var onDrawingChanged: ((PKDrawing) -> Void)?
    public var onPageChanged: ((Int) -> Void)?
    public var onZoomChanged: ((CGFloat) -> Void)?
    public var onScrollChanged: ((CGPoint) -> Void)?
    public var onToolBegan: (() -> Void)?
    public var onToolEnded: (() -> Void)?
    
    // MARK: - Computed Properties
    
    /// Detect canvas type from data
    private var canvasType: CanvasType? {
        if getDocumentData(from: canvasData) != nil {
            return .document
        } else if getWhiteboardData(from: canvasData) != nil {
            return .whiteboard
        } else if let canvas = getCanvasData(from: canvasData) {
            return canvas.canvasType
        }
        return nil
    }
    
    // MARK: - Initialization
    
    public init(
        canvasData: Binding<Data>,
        settings: CanvasSettings = CanvasSettings(),
        onDrawingChanged: ((PKDrawing) -> Void)? = nil,
        onPageChanged: ((Int) -> Void)? = nil,
        onZoomChanged: ((CGFloat) -> Void)? = nil,
        onScrollChanged: ((CGPoint) -> Void)? = nil,
        onToolBegan: (() -> Void)? = nil,
        onToolEnded: (() -> Void)? = nil
    ) {
        self._canvasData = canvasData
        self.settings = settings
        self.onDrawingChanged = onDrawingChanged
        self.onPageChanged = onPageChanged
        self.onZoomChanged = onZoomChanged
        self.onScrollChanged = onScrollChanged
        self.onToolBegan = onToolBegan
        self.onToolEnded = onToolEnded
    }
    
    // MARK: - Body
    
    public var body: some View {
        Group {
            switch canvasType {
            case .document:
                DocumentCanvasDataView(canvasData: $canvasData)
                
            case .whiteboard:
                WhiteboardCanvasDataView(canvasData: $canvasData)
                
            case .none:
                Text("Invalid canvas data")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
}

// MARK: - Convenience Initializers

public extension CanvasDataView {
    /// Create a document canvas view
    static func document(canvasData: Binding<Data>) -> DocumentCanvasDataView {
        DocumentCanvasDataView(canvasData: canvasData)
    }
    
    /// Create a whiteboard canvas view
    static func whiteboard(canvasData: Binding<Data>) -> WhiteboardCanvasDataView {
        WhiteboardCanvasDataView(canvasData: canvasData)
    }
}
