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
    
    /// Current tool (optional - if not provided, uses default pen)
    public var currentTool: PKTool?
    
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
        currentTool: PKTool? = nil,
        onDrawingChanged: ((PKDrawing) -> Void)? = nil,
        onZoomChanged: ((CGFloat) -> Void)? = nil,
        onScrollChanged: ((CGPoint) -> Void)? = nil,
        onToolBegan: (() -> Void)? = nil,
        onToolEnded: (() -> Void)? = nil
    ) {
        self._canvasData = canvasData
        self.settings = settings
        self.currentTool = currentTool
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
        
        // Configure scroll view for infinite canvas with zoom
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = settings.zoomRange.lowerBound
        scrollView.maximumZoomScale = settings.zoomRange.upperBound
        scrollView.zoomScale = settings.defaultZoom
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        
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
        canvasView.drawingPolicy = settings.enablePalmRejection ? .pencilOnly : .anyInput
        canvasView.isOpaque = true
        canvasView.backgroundColor = UIColor.white
        canvasView.drawing = whiteboard.drawing
        
        // Set initial tool if provided
        if let tool = currentTool {
            canvasView.tool = tool
        } else {
            // Default to pen tool
            canvasView.tool = PKInkingTool(.pen, color: .black, width: 5.0)
        }
        
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
        
        // Store references in coordinator
        context.coordinator.canvasView = canvasView
        
        // Set up drawing change callback to update Data binding
        let canvasDataBinding = _canvasData
        context.coordinator.onDrawingChangedCallback = { drawing in
            // Update the whiteboard drawing
            var updatedWhiteboard = WhiteboardCanvasDataView(
                canvasData: canvasDataBinding,
                settings: settings
            ).whiteboard
            updatedWhiteboard.drawing = drawing
            // Expand content size if needed
            updatedWhiteboard.expandContentSizeIfNeeded()
            canvasDataBinding.wrappedValue = updatedWhiteboard.toData()
        }
        
        // Add double tap gesture to reset zoom
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.resetZoom))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
        
        // Ensure layout after view appears
        DispatchQueue.main.async {
            scrollView.setNeedsLayout()
            scrollView.layoutIfNeeded()
            canvasView.setNeedsDisplay()
            
            // Center the canvas initially (after layout)
            guard scrollView.bounds.width > 0 && scrollView.bounds.height > 0 else {
                // If bounds not ready, set content offset to (0,0) to show top-left
                scrollView.contentOffset = .zero
                return
            }
            let centerX = (whiteboard.contentSize.width - scrollView.bounds.width) / 2
            let centerY = (whiteboard.contentSize.height - scrollView.bounds.height) / 2
            scrollView.contentOffset = CGPoint(x: max(0, centerX), y: max(0, centerY))
        }
        
        return scrollView
    }
    
    public func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let canvasView = scrollView.subviews.first as? PKCanvasView else { return }
        
        // Update drawing
        if canvasView.drawing != whiteboard.drawing {
            canvasView.drawing = whiteboard.drawing
        }
        
        // Update tool if provided
        if let tool = currentTool {
            // Always update tool to ensure color/width changes are applied
            canvasView.tool = tool
        }
        
        // Update content size if it changed
        if scrollView.contentSize != whiteboard.contentSize {
            scrollView.contentSize = whiteboard.contentSize
            
            // Update canvas view constraints
            if let widthConstraint = canvasView.constraints.first(where: { $0.firstAttribute == .width }),
               widthConstraint.constant != whiteboard.contentSize.width {
                widthConstraint.constant = whiteboard.contentSize.width
                canvasView.constraints.first(where: { $0.firstAttribute == .height })?.constant = whiteboard.contentSize.height
            }
        }
        
        // Update settings
        scrollView.minimumZoomScale = settings.zoomRange.lowerBound
        scrollView.maximumZoomScale = settings.zoomRange.upperBound
        
        #if canImport(UIKit)
        // Update background color
        scrollView.backgroundColor = whiteboard.backgroundUIColor
        #endif
        
        // Update coordinator
        context.coordinator.canvasView = canvasView
        
        // Update drawing change callback
        let canvasDataBinding = _canvasData
        context.coordinator.onDrawingChangedCallback = { drawing in
            // Update the whiteboard drawing
            var updatedWhiteboard = WhiteboardCanvasDataView(
                canvasData: canvasDataBinding,
                settings: settings
            ).whiteboard
            updatedWhiteboard.drawing = drawing
            // Expand content size if needed
            updatedWhiteboard.expandContentSizeIfNeeded()
            canvasDataBinding.wrappedValue = updatedWhiteboard.toData()
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(parent: self)
        coordinator.settings = settings
        return coordinator
    }
    
    // MARK: - Coordinator
    
    public class Coordinator: CanvasCoordinator {
        var settings: CanvasSettings = CanvasSettings()
        
        init(parent: WhiteboardCanvasDataView) {
            self.settings = parent.settings
            super.init(parent: nil)
        }
        
        @MainActor
        @objc func resetZoom(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }
            UIView.animate(withDuration: 0.3) {
                scrollView.zoomScale = self.settings.defaultZoom
            }
        }
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

// MARK: - Public Zoom Methods

extension WhiteboardCanvasDataView {
    /// Zoom in
    public func zoomIn() {
        // This will be handled by the wrapper view
    }
    
    /// Zoom out
    public func zoomOut() {
        // This will be handled by the wrapper view
    }
    
    /// Reset zoom
    public func resetZoom() {
        // This will be handled by the wrapper view
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

