import SwiftUI
import PencilKit

#if canImport(UIKit)
import UIKit

/// Toolbar for notebook/document canvas mode
public struct NotebookToolbar: View {
    // MARK: - Properties
    
    /// Current tool
    @Binding public var currentTool: PKTool
    
    /// Current ink color
    @Binding public var inkColor: UIColor
    
    /// Current ink width
    @Binding public var inkWidth: CGFloat
    
    /// Current instrument type
    @Binding public var instrument: PKInkingTool.InkType
    
    /// Undo/redo state
    @Binding public var canUndo: Bool
    @Binding public var canRedo: Bool
    
    /// Current page index
    public var currentPageIndex: Int
    
    /// Total page count
    public var pageCount: Int
    
    /// Callbacks
    public var onToolChanged: ((PKTool) -> Void)?
    public var onUndo: (() -> Void)?
    public var onRedo: (() -> Void)?
    public var onClear: (() -> Void)?
    public var onAddPage: (() -> Void)?
    public var onRemovePage: (() -> Void)?
    public var onPageChanged: ((Int) -> Void)?
    public var onZoomIn: (() -> Void)?
    public var onZoomOut: (() -> Void)?
    public var onZoomReset: (() -> Void)?
    
    /// Toolbar visibility
    @Binding public var isVisible: Bool
    
    /// Configuration
    public var configuration: ToolbarConfiguration
    
    // MARK: - Initialization
    
    public init(
        currentTool: Binding<PKTool>,
        inkColor: Binding<UIColor> = .constant(.black),
        inkWidth: Binding<CGFloat> = .constant(5.0),
        instrument: Binding<PKInkingTool.InkType> = .constant(.pen),
        canUndo: Binding<Bool> = .constant(false),
        canRedo: Binding<Bool> = .constant(false),
        currentPageIndex: Int = 0,
        pageCount: Int = 1,
        isVisible: Binding<Bool> = .constant(true),
        configuration: ToolbarConfiguration = ToolbarConfiguration(),
        onToolChanged: ((PKTool) -> Void)? = nil,
        onUndo: (() -> Void)? = nil,
        onRedo: (() -> Void)? = nil,
        onClear: (() -> Void)? = nil,
        onAddPage: (() -> Void)? = nil,
        onRemovePage: (() -> Void)? = nil,
        onPageChanged: ((Int) -> Void)? = nil,
        onZoomIn: (() -> Void)? = nil,
        onZoomOut: (() -> Void)? = nil,
        onZoomReset: (() -> Void)? = nil
    ) {
        self._currentTool = currentTool
        self._inkColor = inkColor
        self._inkWidth = inkWidth
        self._instrument = instrument
        self._canUndo = canUndo
        self._canRedo = canRedo
        self.currentPageIndex = currentPageIndex
        self.pageCount = pageCount
        self._isVisible = isVisible
        self.configuration = configuration
        self.onToolChanged = onToolChanged
        self.onUndo = onUndo
        self.onRedo = onRedo
        self.onClear = onClear
        self.onAddPage = onAddPage
        self.onRemovePage = onRemovePage
        self.onPageChanged = onPageChanged
        self.onZoomIn = onZoomIn
        self.onZoomOut = onZoomOut
        self.onZoomReset = onZoomReset
    }
    
    // MARK: - Body
    
    public var body: some View {
        if isVisible {
            VStack(spacing: 0) {
                // Main toolbar
                HStack(spacing: configuration.spacing) {
                    // Tool selection
                    toolSelectionView
                    
                    // Ink controls
                    if currentTool is PKInkingTool {
                        inkControlsView
                    }
                    
                    Spacer()
                    
                    // Zoom controls
                    zoomControlsView
                    
                    // Page controls
                    pageControlsView
                    
                    // Action buttons
                    actionButtonsView
                }
                .padding(.horizontal, configuration.horizontalPadding)
                .padding(.vertical, configuration.verticalPadding)
                .background(
                    Material.regular
                        .shadow(color: .black.opacity(0.1), radius: configuration.shadowRadius)
                )
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    // MARK: - Tool Selection
    
    private var toolSelectionView: some View {
        HStack(spacing: 8) {
            // Pen tool
            toolButton(
                tool: PKInkingTool(.pen, color: inkColor, width: inkWidth),
                icon: "pencil",
                isSelected: currentTool is PKInkingTool && instrument == .pen
            )
            
            // Pencil tool
            toolButton(
                tool: PKInkingTool(.pencil, color: inkColor, width: inkWidth),
                icon: "pencil.circle",
                isSelected: currentTool is PKInkingTool && instrument == .pencil
            )
            
            // Marker tool
            toolButton(
                tool: PKInkingTool(.marker, color: inkColor, width: inkWidth),
                icon: "highlighter",
                isSelected: currentTool is PKInkingTool && instrument == .marker
            )
            
            // Eraser tool
            toolButton(
                tool: PKEraserTool(.bitmap),
                icon: "eraser",
                isSelected: currentTool is PKEraserTool
            )
        }
    }
    
    // MARK: - Ink Controls
    
    private var inkControlsView: some View {
        HStack(spacing: 12) {
            // Color picker
            ColorPicker("Ink Color", selection: Binding(
                get: { Color(inkColor) },
                set: { inkColor = UIColor($0) }
            ))
            .labelsHidden()
            .frame(width: 30, height: 30)
            
            // Width slider
            VStack(spacing: 2) {
                Text("Width")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Slider(value: $inkWidth, in: 1...20, step: 1)
                    .frame(width: 80)
            }
        }
    }
    
    // MARK: - Zoom Controls
    
    private var zoomControlsView: some View {
        HStack(spacing: 4) {
            Button(action: { onZoomOut?() }) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(.plain)
            
            Button(action: { onZoomReset?() }) {
                Image(systemName: "1.magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(.plain)
            
            Button(action: { onZoomIn?() }) {
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Page Controls
    
    private var pageControlsView: some View {
        HStack(spacing: 8) {
            // Previous page
            Button(action: {
                if currentPageIndex > 0 {
                    onPageChanged?(currentPageIndex - 1)
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
            }
            .disabled(currentPageIndex <= 0)
            .buttonStyle(.plain)
            
            // Page indicator
            Text("\(currentPageIndex + 1)/\(pageCount)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(minWidth: 50)
            
            // Next page
            Button(action: {
                if currentPageIndex < pageCount - 1 {
                    onPageChanged?(currentPageIndex + 1)
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
            }
            .disabled(currentPageIndex >= pageCount - 1)
            .buttonStyle(.plain)
            
            // Add page
            Button(action: { onAddPage?() }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(.plain)
            
            // Remove page (only if more than 1 page)
            if pageCount > 1 {
                Button(action: { onRemovePage?() }) {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsView: some View {
        HStack(spacing: 8) {
            // Undo button
            Button(action: { onUndo?() }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 16, weight: .medium))
            }
            .disabled(!canUndo)
            .buttonStyle(.plain)
            
            // Redo button
            Button(action: { onRedo?() }) {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 16, weight: .medium))
            }
            .disabled(!canRedo)
            .buttonStyle(.plain)
            
            // Clear button
            Button(action: { onClear?() }) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Tool Button
    
    private func toolButton(tool: PKTool, icon: String, isSelected: Bool) -> some View {
        Button(action: {
            currentTool = tool
            if let inkingTool = tool as? PKInkingTool {
                instrument = inkingTool.inkType
            }
            onToolChanged?(tool)
        }) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.clear : Color.primary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#else
// macOS placeholder
public struct NotebookToolbar: View {
    public var body: some View {
        Text("Notebook Toolbar - iOS only")
            .foregroundColor(.secondary)
    }
    
    public init(
        currentTool: Binding<PKTool>,
        inkColor: Binding<UIColor> = .constant(.black),
        inkWidth: Binding<CGFloat> = .constant(5.0),
        instrument: Binding<PKInkingTool.InkType> = .constant(.pen),
        canUndo: Binding<Bool> = .constant(false),
        canRedo: Binding<Bool> = .constant(false),
        currentPageIndex: Int = 0,
        pageCount: Int = 1,
        isVisible: Binding<Bool> = .constant(true),
        configuration: ToolbarConfiguration = ToolbarConfiguration(),
        onToolChanged: ((PKTool) -> Void)? = nil,
        onUndo: (() -> Void)? = nil,
        onRedo: (() -> Void)? = nil,
        onClear: (() -> Void)? = nil,
        onAddPage: (() -> Void)? = nil,
        onRemovePage: (() -> Void)? = nil,
        onPageChanged: ((Int) -> Void)? = nil,
        onZoomIn: (() -> Void)? = nil,
        onZoomOut: (() -> Void)? = nil,
        onZoomReset: (() -> Void)? = nil
    ) {}
}
#endif

