import SwiftUI
import PencilKit
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

/// Document canvas view that works with Data binding for maximum flexibility
#if canImport(UIKit)
public struct DocumentCanvasDataView: UIViewRepresentable {
    // MARK: - Properties
    
    /// Binding to the document canvas data
    @Binding public var canvasData: Data
    
    /// Current page index
    @State public var currentPageIndex: Int = 0
    
    /// Canvas settings
    public var settings: CanvasSettings = CanvasSettings()
    
    /// Callbacks
    public var onDrawingChanged: ((PKDrawing) -> Void)?
    public var onPageChanged: ((Int) -> Void)?
    public var onZoomChanged: ((CGFloat) -> Void)?
    public var onToolBegan: (() -> Void)?
    public var onToolEnded: (() -> Void)?
    
    // MARK: - Private Properties
    
    /// Parsed document data (computed property)
    private var document: DocumentCanvasData {
        get {
            DocumentCanvasData.fromData(canvasData) ?? DocumentCanvasData(title: "New Document")
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
        onPageChanged: ((Int) -> Void)? = nil,
        onZoomChanged: ((CGFloat) -> Void)? = nil,
        onToolBegan: (() -> Void)? = nil,
        onToolEnded: (() -> Void)? = nil
    ) {
        self._canvasData = canvasData
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
        canvasView.drawingPolicy = .anyInput
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
    }
    
    public func makeCoordinator() -> CanvasCoordinator {
        return CanvasCoordinator(parent: nil)
    }
    
    // MARK: - Public Methods
    
    /// Navigate to a specific page
    public mutating func goToPage(_ pageIndex: Int) {
        guard pageIndex >= 0 && pageIndex < document.pageCount else { return }
        currentPageIndex = pageIndex
        onPageChanged?(pageIndex)
    }
    
    /// Navigate to next page
    public mutating func nextPage() {
        if currentPageIndex < document.pageCount - 1 {
            goToPage(currentPageIndex + 1)
        }
    }
    
    /// Navigate to previous page
    public mutating func previousPage() {
        if currentPageIndex > 0 {
            goToPage(currentPageIndex - 1)
        }
    }
    
    /// Add a new page
    public mutating func addPage(template: PageTemplate = .blank) {
        var newDocument = document
        newDocument.addPage(template: template)
        document = newDocument
        goToPage(newDocument.pageCount - 1)
    }
    
    /// Remove current page
    public mutating func removeCurrentPage() {
        guard document.pageCount > 1 else { return }
        
        var newDocument = document
        newDocument.removePage(at: currentPageIndex)
        document = newDocument
        
        // Adjust current page index
        if currentPageIndex >= newDocument.pageCount {
            currentPageIndex = newDocument.pageCount - 1
        }
        
        onPageChanged?(currentPageIndex)
    }
    
    /// Get current page
    public var currentPage: PageData? {
        guard document.pages.indices.contains(currentPageIndex) else { return nil }
        return document.pages[currentPageIndex]
    }
    
    /// Check if can go to next page
    public var canGoToNextPage: Bool {
        return currentPageIndex < document.pageCount - 1
    }
    
    /// Check if can go to previous page
    public var canGoToPreviousPage: Bool {
        return currentPageIndex > 0
    }
    
    /// Get page count
    public var pageCount: Int {
        return document.pageCount
    }
    
    /// Get current page number (1-based)
    public var currentPageNumber: Int {
        return currentPageIndex + 1
    }
    
    /// Get document title
    public var title: String {
        return document.title
    }
    
    /// Set document title
    public mutating func setTitle(_ newTitle: String) {
        var newDocument = document
        newDocument.title = newTitle
        document = newDocument
    }
    
    /// Check if document has content
    public var hasContent: Bool {
        return document.hasContent
    }
}

// MARK: - Drawing Change Handling

extension DocumentCanvasDataView {
    public func notifyDrawingChanged() {
        // The drawing is already updated through the binding
        // This method is called by the coordinator after drawing changes
    }
}

#else
// macOS placeholder
public struct DocumentCanvasDataView: View {
    public var body: some View {
        Text("Document Canvas Data View - iOS only")
            .foregroundColor(.secondary)
    }
    
    public init(canvasData: Binding<Data>) {}
}
#endif

