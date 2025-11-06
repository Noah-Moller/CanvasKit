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
        
        // Configure scroll view for zoom
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = settings.zoomRange.lowerBound
        scrollView.maximumZoomScale = settings.zoomRange.upperBound
        scrollView.zoomScale = settings.defaultZoom
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.backgroundColor = UIColor.systemGray5
        scrollView.bouncesZoom = true
        scrollView.isScrollEnabled = true
        
        // Configure canvas view
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = settings.enablePalmRejection ? .pencilOnly : .anyInput
        canvasView.isOpaque = true
        canvasView.backgroundColor = UIColor.white
        
        // Get current page size - ensure we have at least one page
        let pageSize: CGSize
        if document.pages.isEmpty {
            // If no pages, create one with default paper size
            var updatedDocument = document
            updatedDocument.pages = [PageData(pageNumber: 1, paperSize: document.paperSize)]
            pageSize = document.paperSize.cgSize
            canvasView.drawing = PKDrawing()
        } else if document.pages.indices.contains(currentPageIndex) {
            pageSize = document.pages[currentPageIndex].pageSize
            canvasView.drawing = document.pages[currentPageIndex].drawing
        } else {
            // Fallback to first page or paper size
            pageSize = document.pages.first?.pageSize ?? document.paperSize.cgSize
            canvasView.drawing = document.pages.first?.drawing ?? PKDrawing()
        }
        
        // Add canvas to scroll view
        scrollView.addSubview(canvasView)
        
        // Set up constraints with proper page size
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            canvasView.widthAnchor.constraint(equalToConstant: pageSize.width),
            canvasView.heightAnchor.constraint(equalToConstant: pageSize.height)
        ])
        
        // Set scroll view content size to match page size
        scrollView.contentSize = pageSize
        
        // Ensure scroll view can scroll and has proper frame
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        
        // Store references in coordinator
        context.coordinator.canvasView = canvasView
        
        // Set up drawing change callback to update Data binding
        let currentPageIdx = currentPageIndex
        let canvasDataBinding = _canvasData
        context.coordinator.onDrawingChangedCallback = { drawing in
            // Update the document's current page drawing
            var updatedDocument = DocumentCanvasDataView(
                canvasData: canvasDataBinding,
                settings: settings
            ).document
            if updatedDocument.pages.indices.contains(currentPageIdx) {
                updatedDocument.pages[currentPageIdx].drawing = drawing
                canvasDataBinding.wrappedValue = updatedDocument.toData()
            }
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
        }
        
        return scrollView
    }
    
    public func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let canvasView = scrollView.subviews.first as? PKCanvasView else { return }
        
        // Update page size if needed - ensure we have at least one page
        let pageSize: CGSize
        if document.pages.isEmpty {
            // If no pages, use paper size
            pageSize = document.paperSize.cgSize
        } else if document.pages.indices.contains(currentPageIndex) {
            pageSize = document.pages[currentPageIndex].pageSize
        } else {
            // Fallback to first page or paper size
            pageSize = document.pages.first?.pageSize ?? document.paperSize.cgSize
        }
        
        // Update canvas view constraints if page size changed
        if let widthConstraint = canvasView.constraints.first(where: { $0.firstAttribute == .width }),
           widthConstraint.constant != pageSize.width {
            widthConstraint.constant = pageSize.width
            canvasView.constraints.first(where: { $0.firstAttribute == .height })?.constant = pageSize.height
            // Update content size when page size changes
            scrollView.contentSize = pageSize
        }
        
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
        
        // Ensure content size is set
        if scrollView.contentSize != pageSize {
            scrollView.contentSize = pageSize
        }
        
        // Update coordinator
        context.coordinator.canvasView = canvasView
        
        // Update drawing change callback
        let currentPageIdx = currentPageIndex
        let canvasDataBinding = _canvasData
        context.coordinator.onDrawingChangedCallback = { drawing in
            // Update the document's current page drawing
            var updatedDocument = DocumentCanvasDataView(
                canvasData: canvasDataBinding,
                settings: settings
            ).document
            if updatedDocument.pages.indices.contains(currentPageIdx) {
                updatedDocument.pages[currentPageIdx].drawing = drawing
                canvasDataBinding.wrappedValue = updatedDocument.toData()
            }
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
        
        init(parent: DocumentCanvasDataView) {
            self.settings = parent.settings
            super.init(parent: nil)
        }
        
        @MainActor
        @objc func resetZoom(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }
            UIView.animate(withDuration: 0.3) {
                scrollView.zoomScale = self.settings.defaultZoom
                scrollView.contentOffset = CGPoint(x: 0, y: 0)
            }
        }
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

// MARK: - Public Zoom Methods

extension DocumentCanvasDataView {
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
public struct DocumentCanvasDataView: View {
    public var body: some View {
        Text("Document Canvas Data View - iOS only")
            .foregroundColor(.secondary)
    }
    
    public init(canvasData: Binding<Data>) {}
}
#endif

