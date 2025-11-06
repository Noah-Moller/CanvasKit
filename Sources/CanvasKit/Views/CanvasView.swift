import SwiftUI
import PencilKit

#if canImport(UIKit)
import UIKit

/// Complete canvas/whiteboard experience with toolbar and zoom controls
public struct CanvasView: View {
    // MARK: - Properties
    
    /// Binding to the whiteboard canvas data
    @Binding public var canvasData: Data
    
    /// Current tool
    @State private var currentTool: PKTool
    
    /// Tool settings
    @State private var inkColor: UIColor = .black
    @State private var inkWidth: CGFloat = 5.0
    @State private var instrument: PKInkingTool.InkType = .pen
    
    /// Undo/redo state
    @State private var canUndo: Bool = false
    @State private var canRedo: Bool = false
    
    /// Grid visibility
    @State private var showGrid: Bool = false
    
    /// Zoom state
    @State private var currentZoom: CGFloat = 1.0
    
    /// Toolbar visibility
    @State private var isToolbarVisible: Bool = true
    
    /// Canvas settings
    public var settings: CanvasSettings = CanvasSettings(zoomRange: 0.1...5.0, defaultZoom: 1.0)
    
    /// Callbacks
    public var onDataChanged: (@Sendable (Data) -> Void)?
    
    // MARK: - Computed Properties
    
    private var whiteboard: WhiteboardCanvasData {
        get {
            WhiteboardCanvasData.fromData(canvasData) ?? WhiteboardCanvasData(title: "New Canvas")
        }
        set {
            canvasData = newValue.toData()
            onDataChanged?(canvasData)
        }
    }
    
    // MARK: - Initialization
    
    public init(
        canvasData: Binding<Data>,
        settings: CanvasSettings = CanvasSettings(zoomRange: 0.1...5.0, defaultZoom: 1.0),
        onDataChanged: (@Sendable (Data) -> Void)? = nil
    ) {
        self._canvasData = canvasData
        self.settings = settings
        self.onDataChanged = onDataChanged
        
        // Initialize tool
        _currentTool = State(initialValue: PKInkingTool(.pen, color: .black, width: 5.0))
        
        // Initialize grid visibility from whiteboard
        if let whiteboardData = WhiteboardCanvasData.fromData(canvasData.wrappedValue) {
            _showGrid = State(initialValue: whiteboardData.showGrid)
        }
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // Canvas view
            WhiteboardCanvasDataView(
                canvasData: $canvasData,
                settings: settings,
                currentTool: currentTool,
                onDrawingChanged: { drawing in
                    updateDrawing(drawing)
                },
                onZoomChanged: { zoom in
                    currentZoom = zoom
                }
            )
            .onAppear {
                // Initialize with current tool
                updateTool()
            }
            
            // Grid overlay (if enabled)
            if showGrid {
                GridOverlayView(
                    gridSize: whiteboard.gridSize,
                    snapToGrid: whiteboard.snapToGrid
                )
                .allowsHitTesting(false)
            }
            
            // Toolbar (bottom)
            VStack {
                Spacer()
                
                CanvasToolbar(
                    currentTool: $currentTool,
                    inkColor: $inkColor,
                    inkWidth: $inkWidth,
                    instrument: $instrument,
                    canUndo: $canUndo,
                    canRedo: $canRedo,
                    showGrid: $showGrid,
                    isVisible: $isToolbarVisible,
                    onToolChanged: { tool in
                        currentTool = tool
                        // Update instrument if it's an inking tool
                        if let inkingTool = tool as? PKInkingTool {
                            instrument = inkingTool.inkType
                            inkColor = inkingTool.color
                            inkWidth = inkingTool.width
                        }
                    },
                    onUndo: {
                        undo()
                    },
                    onRedo: {
                        redo()
                    },
                    onClear: {
                        clearCanvas()
                    },
                    onToggleGrid: {
                        toggleGrid()
                    },
                    onZoomIn: {
                        zoomIn()
                    },
                    onZoomOut: {
                        zoomOut()
                    },
                    onZoomReset: {
                        resetZoom()
                    }
                )
                .padding(.bottom)
            }
        }
        .onChange(of: canvasData) { _, newData in
            // Update grid visibility from whiteboard
            if let whiteboardData = WhiteboardCanvasData.fromData(newData) {
                showGrid = whiteboardData.showGrid
            }
            // Update undo/redo state when data changes
            updateUndoRedoState()
        }
        .onChange(of: inkColor) { _, _ in
            // Recreate tool with new color
            recreateTool()
        }
        .onChange(of: inkWidth) { _, _ in
            // Recreate tool with new width
            recreateTool()
        }
        .onChange(of: instrument) { _, _ in
            // Recreate tool with new instrument type
            recreateTool()
        }
    }
    
    // MARK: - Private Methods
    
    private func updateTool() {
        // Tool is passed to WhiteboardCanvasDataView via currentTool property
        // The view will update the canvas tool in updateUIView
        recreateTool()
    }
    
    private func recreateTool() {
        // Recreate tool with current settings
        if currentTool is PKInkingTool {
            currentTool = PKInkingTool(instrument, color: inkColor, width: inkWidth)
        } else if currentTool is PKEraserTool {
            // Keep eraser as is
        } else {
            // Default to pen
            currentTool = PKInkingTool(instrument, color: inkColor, width: inkWidth)
        }
    }
    
    private func updateDrawing(_ drawing: PKDrawing) {
        // Update undo/redo state
        updateUndoRedoState()
    }
    
    private func updateUndoRedoState() {
        // This would need access to the canvas view's undo manager
        // For now, we'll track it through callbacks
    }
    
    private func undo() {
        // This will be handled by accessing the canvas view's undo manager
        // For now, it's a placeholder
    }
    
    private func redo() {
        // This will be handled by accessing the canvas view's undo manager
        // For now, it's a placeholder
    }
    
    private func clearCanvas() {
        var updatedWhiteboard = whiteboard
        updatedWhiteboard.drawing = PKDrawing()
        canvasData = updatedWhiteboard.toData()
        onDataChanged?(canvasData)
    }
    
    private func toggleGrid() {
        var updatedWhiteboard = whiteboard
        updatedWhiteboard.showGrid.toggle()
        canvasData = updatedWhiteboard.toData()
        onDataChanged?(canvasData)
        showGrid = updatedWhiteboard.showGrid
    }
    
    private func zoomIn() {
        // This will be handled by the wrapper that has access to scroll view
        currentZoom = min(currentZoom * 1.2, settings.zoomRange.upperBound)
    }
    
    private func zoomOut() {
        // This will be handled by the wrapper that has access to scroll view
        currentZoom = max(currentZoom / 1.2, settings.zoomRange.lowerBound)
    }
    
    private func resetZoom() {
        // This will be handled by the wrapper that has access to scroll view
        currentZoom = settings.defaultZoom
    }
}

// MARK: - Grid Overlay View

private struct GridOverlayView: View {
    let gridSize: CGFloat
    let snapToGrid: Bool
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                
                // Vertical lines
                var x: CGFloat = 0
                while x < width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                    x += gridSize
                }
                
                // Horizontal lines
                var y: CGFloat = 0
                while y < height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                    y += gridSize
                }
            }
            .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
        }
    }
}

#else
// macOS placeholder
public struct CanvasView: View {
    public var body: some View {
        Text("Canvas View - iOS only")
            .foregroundColor(.secondary)
    }
    
    public init(
        canvasData: Binding<Data>,
        settings: CanvasSettings = CanvasSettings(zoomRange: 0.1...5.0, defaultZoom: 1.0),
        onDataChanged: (@Sendable (Data) -> Void)? = nil
    ) {}
}
#endif

