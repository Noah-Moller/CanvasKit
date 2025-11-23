import Foundation
import PencilKit
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

/// Protocol for canvas view delegates
public protocol CanvasViewDelegate: AnyObject {
    var onDrawingChanged: ((PKDrawing) -> Void)? { get }
    var onZoomChanged: ((CGFloat) -> Void)? { get }
    var onToolBegan: (() -> Void)? { get }
    var onToolEnded: (() -> Void)? { get }
    
    func notifyDrawingChanged()
}

/// Coordinator class to handle PencilKit delegate methods and canvas interactions (iOS only)
#if canImport(UIKit)
public class CanvasCoordinator: NSObject {
    // MARK: - Properties
    
    /// Weak reference to avoid retain cycles
    public weak var parent: AnyObject?
    
    /// Model context for SwiftData operations
    public var modelContext: ModelContext?
    
    /// Weak reference to canvas view for tool management
    public weak var canvasView: PKCanvasView?
    
    /// Template background hosting controller (for document canvases)
    public var templateHostingController: UIHostingController<PageTemplateBackgroundView>?
    
    /// Current zoom scale
    public var currentZoomScale: CGFloat = 1.0
    
    /// Auto-save timer
    private var autoSaveTimer: Timer?
    
    /// Drawing change tracking
    private var hasUnsavedChanges = false
    
    /// Callback for when drawing changes (for Data binding updates)
    public var onDrawingChangedCallback: ((PKDrawing) -> Void)?
    
    /// Undo/redo state tracking
    public var canUndo: Bool = false
    public var canRedo: Bool = false
    
    // MARK: - Configuration
    
    /// Auto-save interval in seconds
    public var autoSaveInterval: TimeInterval = 2.0
    
    /// Enable auto-save functionality
    public var autoSaveEnabled: Bool = true
    
    // MARK: - Initialization
    
    public init(parent: AnyObject?, modelContext: ModelContext? = nil) {
        self.parent = parent
        self.modelContext = modelContext
        super.init()
    }
    
    public init(parent: AnyObject?) {
        self.parent = parent
        self.modelContext = nil
        super.init()
    }
    
    // MARK: - Auto-save Management
    
    /// Start auto-save timer
    public func startAutoSave() {
        guard autoSaveEnabled else { return }
        
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { [weak self] _ in
            self?.performAutoSave()
        }
    }
    
    /// Stop auto-save timer
    public func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    /// Perform auto-save if there are unsaved changes
    private func performAutoSave() {
        guard hasUnsavedChanges, let modelContext = modelContext else { return }
        
        do {
            try modelContext.save()
            hasUnsavedChanges = false
            print("Canvas auto-saved successfully")
        } catch {
            print("Failed to auto-save canvas: \(error)")
        }
    }
    
    /// Manually save the canvas
    public func saveCanvas() {
        performAutoSave()
    }
    
    /// Mark that changes have been made
    public func markAsChanged() {
        hasUnsavedChanges = true
    }
}

// MARK: - PKCanvasViewDelegate

extension CanvasCoordinator: PKCanvasViewDelegate {
    public func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        // Store reference to canvas view
        self.canvasView = canvasView
        
        // Update undo/redo state
        updateUndoRedoState(canvasView)
        
        // Mark as changed for auto-save
        markAsChanged()
        
        // Call drawing changed callback for Data binding updates
        onDrawingChangedCallback?(canvasView.drawing)
        
        // Update parent with new drawing
        if let canvasDelegate = parent as? CanvasViewDelegate {
            canvasDelegate.onDrawingChanged?(canvasView.drawing)
            canvasDelegate.notifyDrawingChanged()
        }
    }
    
    public func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
        self.canvasView = canvasView
        if let canvasDelegate = parent as? CanvasViewDelegate {
            canvasDelegate.onToolBegan?()
        }
    }
    
    public func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
        self.canvasView = canvasView
        updateUndoRedoState(canvasView)
        if let canvasDelegate = parent as? CanvasViewDelegate {
            canvasDelegate.onToolEnded?()
        }
    }
}

// MARK: - UIScrollViewDelegate

extension CanvasCoordinator: UIScrollViewDelegate {
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        currentZoomScale = scrollView.zoomScale
        
        // Notify parent of zoom changes
        if let canvasDelegate = parent as? CanvasViewDelegate {
            canvasDelegate.onZoomChanged?(scrollView.zoomScale)
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Notify parent of scroll changes if needed
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        currentZoomScale = scale
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        // Return the canvas view for zooming
        return scrollView.subviews.first
    }
}

// MARK: - Canvas Management

extension CanvasCoordinator {
    /// Load a drawing into the canvas
    public func loadDrawing(_ drawing: PKDrawing, into canvasView: PKCanvasView) {
        canvasView.drawing = drawing
        hasUnsavedChanges = false
    }
    
    /// Clear the canvas
    public func clearCanvas(_ canvasView: PKCanvasView) {
        canvasView.drawing = PKDrawing()
        markAsChanged()
    }
    
    /// Update undo/redo state
    private func updateUndoRedoState(_ canvasView: PKCanvasView) {
        canUndo = canvasView.undoManager?.canUndo == true
        canRedo = canvasView.undoManager?.canRedo == true
    }
    
    /// Undo the last action
    public func undo(_ canvasView: PKCanvasView? = nil) {
        let view = canvasView ?? self.canvasView
        guard let view = view, view.undoManager?.canUndo == true else { return }
        view.undoManager?.undo()
        updateUndoRedoState(view)
        markAsChanged()
    }
    
    /// Redo the last undone action
    public func redo(_ canvasView: PKCanvasView? = nil) {
        let view = canvasView ?? self.canvasView
        guard let view = view, view.undoManager?.canRedo == true else { return }
        view.undoManager?.redo()
        updateUndoRedoState(view)
        markAsChanged()
    }
    
    /// Check if undo is available
    public func checkCanUndo(_ canvasView: PKCanvasView? = nil) -> Bool {
        let view = canvasView ?? self.canvasView
        guard let view = view else { return false }
        let canUndoValue = view.undoManager?.canUndo == true
        canUndo = canUndoValue
        return canUndoValue
    }
    
    /// Check if redo is available
    public func checkCanRedo(_ canvasView: PKCanvasView? = nil) -> Bool {
        let view = canvasView ?? self.canvasView
        guard let view = view else { return false }
        let canRedoValue = view.undoManager?.canRedo == true
        canRedo = canRedoValue
        return canRedoValue
    }
}

// MARK: - Tool Management

extension CanvasCoordinator {
    /// Set the current tool
    public func setTool(_ tool: PKTool, in canvasView: PKCanvasView? = nil) {
        let view = canvasView ?? self.canvasView
        view?.tool = tool
    }
    
    /// Get the current tool
    public func getCurrentTool(from canvasView: PKCanvasView? = nil) -> PKTool? {
        let view = canvasView ?? self.canvasView
        return view?.tool
    }
    
    /// Create a pen tool with custom properties
    public func createPenTool(instrument: PKInkingTool.InkType = .pen, color: UIColor = .black, width: CGFloat = 5) -> PKInkingTool {
        return PKInkingTool(instrument, color: color, width: width)
    }
    
    /// Create a pencil tool with custom properties
    public func createPencilTool(color: UIColor = .black, width: CGFloat = 3) -> PKInkingTool {
        return PKInkingTool(.pencil, color: color, width: width)
    }
    
    /// Create an eraser tool
    public func createEraserTool() -> PKEraserTool {
        return PKEraserTool(.bitmap)
    }
    
    /// Create a lasso tool for selection
    public func createLassoTool() -> PKLassoTool {
        return PKLassoTool()
    }
}

#else
// macOS placeholder
public class CanvasCoordinator {
    public init(parent: AnyObject, modelContext: ModelContext? = nil) {}
}
#endif