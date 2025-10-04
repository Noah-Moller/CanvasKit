import SwiftUI
import PencilKit
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

/// Whiteboard canvas view that works with Data binding for maximum flexibility
#if canImport(UIKit)
public struct WhiteboardCanvasDataView: UIViewRepresentable {
    // MARK: - Properties
    
    /// Binding to the whiteboard canvas data
    @Binding public var canvasData: Data
    
    /// Canvas settings
    public var settings: CanvasSettings = CanvasSettings()
    
    /// Callbacks
    public var onDrawingChanged: ((PKDrawing) -> Void)?
    public var onZoomChanged: ((CGFloat) -> Void)?
    public var onScrollChanged: ((CGPoint) -> Void)?
    public var onToolBegan: (() -> Void)?
    public var onToolEnded: (() -> Void)?
    
    // MARK: - Private Properties
    
    /// Parsed whiteboard data (computed property)
    private var whiteboard: WhiteboardCanvasData {
        get {
            WhiteboardCanvasData.fromData(canvasData) ?? WhiteboardCanvasData(title: "New Whiteboard")
        }
        set {
            canvasData = newValue.toData()
        }
    }
    
    // MARK: - Initialization
    
    public init(
        canvasData: Binding<Data>,
        settings: CanvasSettings = CanvasSettings(),
        onDrawingChanged: ((PKDrawing) -> Void)? = nil,
        onZoomChanged: ((CGFloat) -> Void)? = nil,
        onScrollChanged: ((CGPoint) -> Void)? = nil,
        onToolBegan: (() -> Void)? = nil,
        onToolEnded: (() -> Void)? = nil
    ) {
        self._canvasData = canvasData
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
        scrollView.backgroundColor = whiteboard.backgroundUIColor
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
        canvasView.drawingPolicy = .anyInput
        canvasView.isOpaque = false
        canvasView.backgroundColor = UIColor.clear
        canvasView.drawing = whiteboard.drawing
        
        // Set initial content size
        scrollView.contentSize = whiteboard.contentSize
        
        // Add canvas to scroll view
        scrollView.addSubview(canvasView)
        
        // Set up constraints for infinite canvas
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            canvasView.widthAnchor.constraint(equalToConstant: whiteboard.contentSize.width),
            canvasView.heightAnchor.constraint(equalToConstant: whiteboard.contentSize.height)
        ])
        
        // Configure coordinator
        context.coordinator.parent = nil
        
        // Center the canvas initially
        DispatchQueue.main.async {
            let centerX = (whiteboard.contentSize.width - scrollView.bounds.width) / 2
            let centerY = (whiteboard.contentSize.height - scrollView.bounds.height) / 2
            scrollView.contentOffset = CGPoint(x: max(0, centerX), y: max(0, centerY))
        }
        
        return scrollView
    }
    
    public func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let canvasView = scrollView.subviews.first as? PKCanvasView else { return }
        
        // Update drawing
        canvasView.drawing = whiteboard.drawing
        
        // Update content size if it changed
        if scrollView.contentSize != whiteboard.contentSize {
            scrollView.contentSize = whiteboard.contentSize
            
            // Update canvas view constraints
            canvasView.removeFromSuperview()
            scrollView.addSubview(canvasView)
            canvasView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                canvasView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                canvasView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                canvasView.widthAnchor.constraint(equalToConstant: whiteboard.contentSize.width),
                canvasView.heightAnchor.constraint(equalToConstant: whiteboard.contentSize.height)
            ])
        }
        
        // Update settings
        scrollView.minimumZoomScale = settings.zoomRange.lowerBound
        scrollView.maximumZoomScale = settings.zoomRange.upperBound
        
        #if canImport(UIKit)
        // Update background color
        scrollView.backgroundColor = whiteboard.backgroundUIColor
        #endif
        
        // Update coordinator
        context.coordinator.parent = nil
    }
    
    public func makeCoordinator() -> CanvasCoordinator {
        return CanvasCoordinator(parent: nil)
    }
    
    // MARK: - Public Methods
    
    /// Clear the entire canvas
    public mutating func clearCanvas() {
        var newWhiteboard = whiteboard
        newWhiteboard.drawing = PKDrawing()
        whiteboard = newWhiteboard
    }
    
    #if canImport(UIKit)
    /// Set background color
    public mutating func setBackgroundColor(_ color: UIColor) {
        var newWhiteboard = whiteboard
        newWhiteboard.backgroundUIColor = color
        whiteboard = newWhiteboard
    }
    
    /// Get background color
    public var backgroundColor: UIColor {
        return whiteboard.backgroundUIColor
    }
    #endif
    
    /// Toggle grid visibility
    public mutating func toggleGrid() {
        var newWhiteboard = whiteboard
        newWhiteboard.showGrid.toggle()
        whiteboard = newWhiteboard
    }
    
    /// Set grid visibility
    public mutating func setGridVisible(_ visible: Bool) {
        var newWhiteboard = whiteboard
        newWhiteboard.showGrid = visible
        whiteboard = newWhiteboard
    }
    
    /// Toggle snap to grid
    public mutating func toggleSnapToGrid() {
        var newWhiteboard = whiteboard
        newWhiteboard.snapToGrid.toggle()
        whiteboard = newWhiteboard
    }
    
    /// Set snap to grid
    public mutating func setSnapToGrid(_ snap: Bool) {
        var newWhiteboard = whiteboard
        newWhiteboard.snapToGrid = snap
        whiteboard = newWhiteboard
    }
    
    /// Set grid size
    public mutating func setGridSize(_ size: CGFloat) {
        var newWhiteboard = whiteboard
        newWhiteboard.gridSize = size
        whiteboard = newWhiteboard
    }
    
    /// Get grid size
    public var gridSize: CGFloat {
        return whiteboard.gridSize
    }
    
    /// Check if grid is visible
    public var isGridVisible: Bool {
        return whiteboard.showGrid
    }
    
    /// Check if snap to grid is enabled
    public var isSnapToGridEnabled: Bool {
        return whiteboard.snapToGrid
    }
    
    #if canImport(UIKit)
    /// Export canvas as image
    public func exportAsImage() -> UIImage? {
        return whiteboard.drawing.image(from: whiteboard.drawing.bounds, scale: 1.0)
    }
    
    /// Export canvas as image with custom bounds
    public func exportAsImage(from bounds: CGRect, scale: CGFloat = 1.0) -> UIImage? {
        return whiteboard.drawing.image(from: bounds, scale: scale)
    }
    #endif
    
    /// Get canvas bounds
    public var canvasBounds: CGRect {
        return whiteboard.drawing.bounds
    }
    
    /// Check if canvas has content
    public var hasContent: Bool {
        return whiteboard.hasContent
    }
    
    /// Get canvas title
    public var title: String {
        return whiteboard.title
    }
    
    /// Set canvas title
    public mutating func setTitle(_ newTitle: String) {
        var newWhiteboard = whiteboard
        newWhiteboard.title = newTitle
        whiteboard = newWhiteboard
    }
    
    /// Expand content size based on drawing
    public mutating func expandContentSizeIfNeeded() {
        var newWhiteboard = whiteboard
        newWhiteboard.expandContentSizeIfNeeded()
        whiteboard = newWhiteboard
    }
}

// MARK: - Drawing Change Handling

extension WhiteboardCanvasDataView {
    public func notifyDrawingChanged() {
        // The whiteboard model is already updated through the binding
        // This method is called by the coordinator after drawing changes
    }
}

#else
// macOS placeholder
public struct WhiteboardCanvasDataView: View {
    public var body: some View {
        Text("Whiteboard Canvas Data View - iOS only")
            .foregroundColor(.secondary)
    }
    
    public init(canvasData: Binding<Data>) {}
}
#endif

