import SwiftUI
import PencilKit
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

/// Infinite whiteboard canvas view (iOS only)
#if canImport(UIKit)
public struct WhiteboardCanvasView: UIViewRepresentable {
    // MARK: - Properties
    
    /// The whiteboard canvas model
    @Bindable public var canvas: WhiteboardCanvas
    
    /// Model context for SwiftData operations
    public var modelContext: ModelContext?
    
    /// Canvas settings
    public var settings: CanvasSettings = CanvasSettings()
    
    /// Callbacks
    public var onDrawingChanged: ((PKDrawing) -> Void)?
    public var onZoomChanged: ((CGFloat) -> Void)?
    public var onScrollChanged: ((CGPoint) -> Void)?
    public var onToolBegan: (() -> Void)?
    public var onToolEnded: (() -> Void)?
    
    // MARK: - Initialization
    
    public init(
        canvas: WhiteboardCanvas,
        modelContext: ModelContext? = nil,
        settings: CanvasSettings = CanvasSettings(),
        onDrawingChanged: ((PKDrawing) -> Void)? = nil,
        onZoomChanged: ((CGFloat) -> Void)? = nil,
        onScrollChanged: ((CGPoint) -> Void)? = nil,
        onToolBegan: (() -> Void)? = nil,
        onToolEnded: (() -> Void)? = nil
    ) {
        self.canvas = canvas
        self.modelContext = modelContext
        self.settings = settings
        self.onDrawingChanged = onDrawingChanged
        self.onZoomChanged = onZoomChanged
        self.onScrollChanged = onScrollChanged
        self.onToolBegan = onToolBegan
        self.onToolEnded = onToolEnded
    }
    
    // MARK: - UIViewRepresentable
    
    public func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        let canvasView = PKCanvasView()
        
        // Configure scroll view for infinite canvas
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = settings.zoomRange.lowerBound
        scrollView.maximumZoomScale = settings.zoomRange.upperBound
        scrollView.zoomScale = settings.defaultZoom
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        #if canImport(UIKit)
        scrollView.backgroundColor = canvas.backgroundUIColor
        #else
        scrollView.backgroundColor = .white
        #endif
        
        // Enable infinite scrolling
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.contentInsetAdjustmentBehavior = .never
        
        // Configure canvas view
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput // Simplified for cross-platform
        canvasView.isOpaque = false
        canvasView.backgroundColor = UIColor.clear
        canvasView.drawing = canvas.drawing
        
        // Set initial content size
        scrollView.contentSize = canvas.contentSize
        
        // Add canvas to scroll view
        scrollView.addSubview(canvasView)
        
        // Set up constraints for infinite canvas
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            canvasView.widthAnchor.constraint(equalToConstant: canvas.contentSize.width),
            canvasView.heightAnchor.constraint(equalToConstant: canvas.contentSize.height)
        ])
        
        // Configure coordinator
        context.coordinator.parent = nil
        context.coordinator.modelContext = modelContext
        
        // Center the canvas initially
        DispatchQueue.main.async {
            let centerX = (canvas.contentSize.width - scrollView.bounds.width) / 2
            let centerY = (canvas.contentSize.height - scrollView.bounds.height) / 2
            scrollView.contentOffset = CGPoint(x: max(0, centerX), y: max(0, centerY))
        }
        
        return scrollView
    }
    
    public func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let canvasView = scrollView.subviews.first as? PKCanvasView else { return }
        
        // Update drawing
        canvasView.drawing = canvas.drawing
        
        // Update content size if it changed
        if scrollView.contentSize != canvas.contentSize {
            scrollView.contentSize = canvas.contentSize
            
            // Update canvas view constraints
            canvasView.removeFromSuperview()
            scrollView.addSubview(canvasView)
            canvasView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                canvasView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                canvasView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                canvasView.widthAnchor.constraint(equalToConstant: canvas.contentSize.width),
                canvasView.heightAnchor.constraint(equalToConstant: canvas.contentSize.height)
            ])
        }
        
        // Update settings
        scrollView.minimumZoomScale = settings.zoomRange.lowerBound
        scrollView.maximumZoomScale = settings.zoomRange.upperBound
        
        #if canImport(UIKit)
        // Update background color
        scrollView.backgroundColor = canvas.backgroundUIColor
        #endif
        
        // Update coordinator
        context.coordinator.parent = nil
        context.coordinator.modelContext = modelContext
    }
    
    public func makeCoordinator() -> CanvasCoordinator {
        return CanvasCoordinator(parent: nil, modelContext: modelContext)
    }
    
    // MARK: - Public Methods
    
    /// Clear the entire canvas
    public func clearCanvas() {
        canvas.drawing = PKDrawing()
    }
    
    #if canImport(UIKit)
    /// Set background color
    public func setBackgroundColor(_ color: UIColor) {
        canvas.backgroundUIColor = color
    }
    
    /// Get background color
    public var backgroundColor: UIColor {
        return canvas.backgroundUIColor
    }
    #endif
    
    /// Toggle grid visibility
    public func toggleGrid() {
        canvas.showGrid.toggle()
    }
    
    /// Set grid visibility
    public func setGridVisible(_ visible: Bool) {
        canvas.showGrid = visible
    }
    
    /// Toggle snap to grid
    public func toggleSnapToGrid() {
        canvas.snapToGrid.toggle()
    }
    
    /// Set snap to grid
    public func setSnapToGrid(_ snap: Bool) {
        canvas.snapToGrid = snap
    }
    
    /// Set grid size
    public func setGridSize(_ size: CGFloat) {
        canvas.gridSize = size
    }
    
    /// Get grid size
    public var gridSize: CGFloat {
        return canvas.gridSize
    }
    
    /// Check if grid is visible
    public var isGridVisible: Bool {
        return canvas.showGrid
    }
    
    /// Check if snap to grid is enabled
    public var isSnapToGridEnabled: Bool {
        return canvas.snapToGrid
    }
    
    #if canImport(UIKit)
    /// Export canvas as image
    public func exportAsImage() -> UIImage? {
        return canvas.drawing.image(from: canvas.drawing.bounds, scale: 1.0)
    }
    
    /// Export canvas as image with custom bounds
    public func exportAsImage(from bounds: CGRect, scale: CGFloat = 1.0) -> UIImage? {
        return canvas.drawing.image(from: bounds, scale: scale)
    }
    #endif
    
    /// Get canvas bounds
    public var canvasBounds: CGRect {
        return canvas.drawing.bounds
    }
    
    /// Check if canvas has content
    public var hasContent: Bool {
        return canvas.hasContent
    }
}

// MARK: - WhiteboardCanvasViewDelegate Protocol

public protocol WhiteboardCanvasViewDelegate: AnyObject {
    var onDrawingChanged: ((PKDrawing) -> Void)? { get }
    var onZoomChanged: ((CGFloat) -> Void)? { get }
    var onToolBegan: (() -> Void)? { get }
    var onToolEnded: (() -> Void)? { get }
    
    func notifyDrawingChanged()
}

// MARK: - Drawing Change Handling

extension WhiteboardCanvasView {
    public func notifyDrawingChanged() {
        // The canvas model is already updated through the binding
        // This method is called by the coordinator after drawing changes
    }
}

#else
// macOS placeholder
public struct WhiteboardCanvasView: View {
    public var body: some View {
        Text("Whiteboard Canvas View - iOS only")
            .foregroundColor(.secondary)
    }
    
    public init(canvas: WhiteboardCanvas, modelContext: ModelContext? = nil) {}
}
#endif