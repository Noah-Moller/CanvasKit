import SwiftUI
import PencilKit

#if canImport(UIKit)
import UIKit

/// Complete notebook experience with toolbar, page navigation, and zoom controls
public struct NotebookView: View {
    // MARK: - Properties
    
    /// Binding to the document canvas data
    @Binding public var canvasData: Data
    
    /// Current page index
    @State private var currentPageIndex: Int = 0
    
    /// Current tool
    @State private var currentTool: PKTool
    
    /// Tool settings
    @State private var inkColor: UIColor = .black
    @State private var inkWidth: CGFloat = 5.0
    @State private var instrument: PKInkingTool.InkType = .pen
    
    /// Undo/redo state
    @State private var canUndo: Bool = false
    @State private var canRedo: Bool = false
    
    /// Zoom state
    @State private var currentZoom: CGFloat = 1.0
    
    /// Toolbar visibility
    @State private var isToolbarVisible: Bool = true
    
    /// Canvas settings
    public var settings: CanvasSettings = CanvasSettings(zoomRange: 0.5...3.0, defaultZoom: 1.0)
    
    /// Callbacks
    public var onDataChanged: (@Sendable (Data) -> Void)?
    public var onPageChanged: (@Sendable (Int) -> Void)?
    
    // MARK: - Computed Properties
    
    private var document: DocumentCanvasData {
        get {
            DocumentCanvasData.fromData(canvasData) ?? DocumentCanvasData(title: "New Notebook")
        }
        set {
            canvasData = newValue.toData()
            onDataChanged?(canvasData)
        }
    }
    
    // MARK: - Initialization
    
    public init(
        canvasData: Binding<Data>,
        settings: CanvasSettings = CanvasSettings(zoomRange: 0.5...3.0, defaultZoom: 1.0),
        onDataChanged: (@Sendable (Data) -> Void)? = nil,
        onPageChanged: (@Sendable (Int) -> Void)? = nil
    ) {
        self._canvasData = canvasData
        self.settings = settings
        self.onDataChanged = onDataChanged
        self.onPageChanged = onPageChanged
        
        // Initialize tool
        _currentTool = State(initialValue: PKInkingTool(.pen, color: .black, width: 5.0))
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // Canvas view
            DocumentCanvasDataView(
                canvasData: $canvasData,
                settings: settings,
                currentTool: currentTool,
                onDrawingChanged: { drawing in
                    updateDrawing(drawing)
                },
                onPageChanged: { pageIndex in
                    currentPageIndex = pageIndex
                    onPageChanged?(pageIndex)
                },
                onZoomChanged: { zoom in
                    currentZoom = zoom
                }
            )
            .pageSwipeNavigation(
                currentPageIndex: $currentPageIndex,
                pageCount: document.pageCount,
                onPageChanged: { pageIndex in
                    currentPageIndex = pageIndex
                    onPageChanged?(pageIndex)
                }
            )
            .onAppear {
                // Initialize with current tool
                updateTool()
            }
            
            // Page navigation indicator (top)
            VStack {
                if document.pageCount > 1 {
                    PageNavigationView(
                        currentPageIndex: $currentPageIndex,
                        pageCount: document.pageCount,
                        showPageNumbers: true,
                        showPageDots: true
                    )
                    .padding(.top, 8)
                }
                
                Spacer()
            }
            
            // Toolbar (bottom)
            VStack {
                Spacer()
                
                NotebookToolbar(
                    currentTool: $currentTool,
                    inkColor: $inkColor,
                    inkWidth: $inkWidth,
                    instrument: $instrument,
                    canUndo: $canUndo,
                    canRedo: $canRedo,
                    currentPageIndex: currentPageIndex,
                    pageCount: document.pageCount,
                    isVisible: $isToolbarVisible,
                    onToolChanged: { tool in
                        currentTool = tool
                        updateTool()
                    },
                    onUndo: {
                        undo()
                    },
                    onRedo: {
                        redo()
                    },
                    onClear: {
                        clearCurrentPage()
                    },
                    onAddPage: {
                        addPage()
                    },
                    onRemovePage: {
                        removeCurrentPage()
                    },
                    onPageChanged: { pageIndex in
                        goToPage(pageIndex)
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
        // Tool is passed to DocumentCanvasDataView via currentTool property
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
    
    private func clearCurrentPage() {
        var updatedDocument = document
        if updatedDocument.pages.indices.contains(currentPageIndex) {
            updatedDocument.pages[currentPageIndex].drawing = PKDrawing()
            canvasData = updatedDocument.toData()
            onDataChanged?(canvasData)
        }
    }
    
    private func addPage() {
        var updatedDocument = document
        updatedDocument.addPage()
        canvasData = updatedDocument.toData()
        onDataChanged?(canvasData)
        currentPageIndex = updatedDocument.pageCount - 1
        onPageChanged?(currentPageIndex)
    }
    
    private func removeCurrentPage() {
        guard document.pageCount > 1 else { return }
        var updatedDocument = document
        updatedDocument.removePage(at: currentPageIndex)
        canvasData = updatedDocument.toData()
        onDataChanged?(canvasData)
        
        if currentPageIndex >= updatedDocument.pageCount {
            currentPageIndex = updatedDocument.pageCount - 1
        }
        onPageChanged?(currentPageIndex)
    }
    
    private func goToPage(_ pageIndex: Int) {
        guard pageIndex >= 0 && pageIndex < document.pageCount else { return }
        currentPageIndex = pageIndex
        onPageChanged?(pageIndex)
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

#else
// macOS placeholder
public struct NotebookView: View {
    public var body: some View {
        Text("Notebook View - iOS only")
            .foregroundColor(.secondary)
    }
    
    public init(
        canvasData: Binding<Data>,
        settings: CanvasSettings = CanvasSettings(zoomRange: 0.5...3.0, defaultZoom: 1.0),
        onDataChanged: (@Sendable (Data) -> Void)? = nil,
        onPageChanged: (@Sendable (Int) -> Void)? = nil
    ) {}
}
#endif

