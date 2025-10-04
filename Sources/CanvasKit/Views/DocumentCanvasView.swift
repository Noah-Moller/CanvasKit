import SwiftUI
import PencilKit
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

/// Main document canvas view with multi-page support (iOS only)
#if canImport(UIKit)
public struct DocumentCanvasView: UIViewRepresentable {
    // MARK: - Properties
    
    /// The document containing all pages
    @Bindable public var document: CanvasDocument
    
    /// Current page index
    @State public var currentPageIndex: Int = 0
    
    /// Model context for SwiftData operations
    public var modelContext: ModelContext?
    
    /// Canvas settings
    public var settings: CanvasSettings = CanvasSettings()
    
    /// Callbacks
    public var onDrawingChanged: ((PKDrawing) -> Void)?
    public var onPageChanged: ((Int) -> Void)?
    public var onZoomChanged: ((CGFloat) -> Void)?
    public var onToolBegan: (() -> Void)?
    public var onToolEnded: (() -> Void)?
    
    // MARK: - Initialization
    
    public init(
        document: CanvasDocument,
        modelContext: ModelContext? = nil,
        settings: CanvasSettings = CanvasSettings(),
        onDrawingChanged: ((PKDrawing) -> Void)? = nil,
        onPageChanged: ((Int) -> Void)? = nil,
        onZoomChanged: ((CGFloat) -> Void)? = nil,
        onToolBegan: (() -> Void)? = nil,
        onToolEnded: (() -> Void)? = nil
    ) {
        self.document = document
        self.modelContext = modelContext
        self.settings = settings
        self.onDrawingChanged = onDrawingChanged
        self.onPageChanged = onPageChanged
        self.onZoomChanged = onZoomChanged
        self.onToolBegan = onToolBegan
        self.onToolEnded = onToolEnded
    }
    
    // MARK: - UIViewRepresentable
    
    public func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        let canvasView = PKCanvasView()
        
        // Configure scroll view
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = settings.zoomRange.lowerBound
        scrollView.maximumZoomScale = settings.zoomRange.upperBound
        scrollView.zoomScale = settings.defaultZoom
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = UIColor.systemBackground
        
        // Configure canvas view
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput // Simplified for cross-platform
        canvasView.isOpaque = false
        canvasView.backgroundColor = UIColor.clear
        
        // Set initial drawing
        if document.pages.indices.contains(currentPageIndex) {
            canvasView.drawing = document.pages[currentPageIndex].drawing
        }
        
        // Add canvas to scroll view
        scrollView.addSubview(canvasView)
        
        // Set up constraints
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            canvasView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            canvasView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        // Configure coordinator
        context.coordinator.parent = nil
        context.coordinator.modelContext = modelContext
        
        return scrollView
    }
    
    public func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let canvasView = scrollView.subviews.first as? PKCanvasView else { return }
        
        // Update drawing if page changed
        if document.pages.indices.contains(currentPageIndex) {
            let currentDrawing = document.pages[currentPageIndex].drawing
            if canvasView.drawing != currentDrawing {
                canvasView.drawing = currentDrawing
            }
        }
        
        // Update settings
        scrollView.minimumZoomScale = settings.zoomRange.lowerBound
        scrollView.maximumZoomScale = settings.zoomRange.upperBound
        
        // Update coordinator
        context.coordinator.parent = nil
        context.coordinator.modelContext = modelContext
    }
    
    public func makeCoordinator() -> CanvasCoordinator {
        return CanvasCoordinator(parent: nil, modelContext: modelContext)
    }
    
    // MARK: - Public Methods
    
    /// Navigate to a specific page
    public func goToPage(_ pageIndex: Int) {
        guard pageIndex >= 0 && pageIndex < document.pages.count else { return }
        currentPageIndex = pageIndex
        onPageChanged?(pageIndex)
    }
    
    /// Navigate to next page
    public func nextPage() {
        if currentPageIndex < document.pages.count - 1 {
            goToPage(currentPageIndex + 1)
        }
    }
    
    /// Navigate to previous page
    public func previousPage() {
        if currentPageIndex > 0 {
            goToPage(currentPageIndex - 1)
        }
    }
    
    /// Add a new page
    public func addPage(template: PageTemplate = .blank) {
        document.addPage(template: template)
        goToPage(document.pages.count - 1)
    }
    
    /// Remove current page
    public func removeCurrentPage() {
        guard document.pages.count > 1 else { return }
        
        let removedIndex = currentPageIndex
        document.removePage(at: currentPageIndex)
        
        // Adjust current page index
        if currentPageIndex >= document.pages.count {
            currentPageIndex = document.pages.count - 1
        }
        
        onPageChanged?(currentPageIndex)
    }
    
    /// Get current page
    public var currentPage: CanvasPage? {
        guard document.pages.indices.contains(currentPageIndex) else { return nil }
        return document.pages[currentPageIndex]
    }
    
    /// Check if can go to next page
    public var canGoToNextPage: Bool {
        return currentPageIndex < document.pages.count - 1
    }
    
    /// Check if can go to previous page
    public var canGoToPreviousPage: Bool {
        return currentPageIndex > 0
    }
    
    /// Get page count
    public var pageCount: Int {
        return document.pages.count
    }
    
    /// Get current page number (1-based)
    public var currentPageNumber: Int {
        return currentPageIndex + 1
    }
}

// MARK: - DocumentCanvasViewDelegate Protocol

public protocol DocumentCanvasViewDelegate: AnyObject {
    var onDrawingChanged: ((PKDrawing) -> Void)? { get }
    var onZoomChanged: ((CGFloat) -> Void)? { get }
    var onToolBegan: (() -> Void)? { get }
    var onToolEnded: (() -> Void)? { get }
    
    func notifyDrawingChanged()
}

// MARK: - Drawing Change Handling

extension DocumentCanvasView {
    public func notifyDrawingChanged() {
        // The drawing is already updated through the binding
        // This method is called by the coordinator after drawing changes
    }
}

#else
// macOS placeholder
public struct DocumentCanvasView: View {
    public var body: some View {
        Text("Document Canvas View - iOS only")
            .foregroundColor(.secondary)
    }
    
    public init(document: CanvasDocument, modelContext: ModelContext? = nil) {}
}
#endif