import SwiftUI
import PencilKit

#if canImport(UIKit)
import UIKit

/// Minimal, GoodNotes-inspired toolbar for canvas/whiteboard mode
/// Uses preset-based color and width selection for quick access
public struct CanvasToolbar: View {
    // MARK: - Properties
    
    /// Current tool
    @Binding public var currentTool: PKTool
    
    /// Selected color preset index
    @State private var selectedColorIndex: Int = 0
    
    /// Selected width preset
    @State private var selectedWidth: ToolPresets.StrokeWidth = .medium
    
    /// Current instrument type
    @Binding public var instrument: PKInkingTool.InkType
    
    /// Undo/redo state
    @Binding public var canUndo: Bool
    @Binding public var canRedo: Bool
    
    /// Grid visibility
    @Binding public var showGrid: Bool
    
    /// Callbacks
    public var onToolChanged: ((PKTool) -> Void)?
    public var onUndo: (() -> Void)?
    public var onRedo: (() -> Void)?
    public var onClear: (() -> Void)?
    public var onToggleGrid: (() -> Void)?
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
        showGrid: Binding<Bool> = .constant(false),
        isVisible: Binding<Bool> = .constant(true),
        configuration: ToolbarConfiguration = ToolbarConfiguration(),
        onToolChanged: ((PKTool) -> Void)? = nil,
        onUndo: (() -> Void)? = nil,
        onRedo: (() -> Void)? = nil,
        onClear: (() -> Void)? = nil,
        onToggleGrid: (() -> Void)? = nil,
        onZoomIn: (() -> Void)? = nil,
        onZoomOut: (() -> Void)? = nil,
        onZoomReset: (() -> Void)? = nil
    ) {
        self._currentTool = currentTool
        self._instrument = instrument
        self._canUndo = canUndo
        self._canRedo = canRedo
        self._showGrid = showGrid
        self._isVisible = isVisible
        self.configuration = configuration
        self.onToolChanged = onToolChanged
        self.onUndo = onUndo
        self.onRedo = onRedo
        self.onClear = onClear
        self.onToggleGrid = onToggleGrid
        self.onZoomIn = onZoomIn
        self.onZoomOut = onZoomOut
        self.onZoomReset = onZoomReset
        
        // Initialize selected color and width from provided values
        _selectedColorIndex = State(initialValue: ToolPresets.closestColorIndex(for: inkColor.wrappedValue))
        _selectedWidth = State(initialValue: ToolPresets.closestWidth(for: inkWidth.wrappedValue))
    }
    
    // MARK: - Body
    
    public var body: some View {
        if isVisible {
            VStack(spacing: 0) {
                // Main toolbar - compact and minimal, scrollable for smaller displays
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Drawing tools
                        toolSelectionView
                        
                        Divider()
                            .frame(height: 30)
                        
                        // Color & Width presets (only for inking tools)
                        if currentTool is PKInkingTool {
                            colorPresetsView
                            
                            Divider()
                                .frame(height: 30)
                            
                            widthPresetsView
                            
                            Divider()
                                .frame(height: 30)
                        }
                        
                        Spacer(minLength: 20)
                        
                        // Grid toggle
                        gridToggleButton
                        
                        // Action buttons
                        actionButtonsView
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Material.regular)
                .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    // MARK: - Drawing Tools
    
    private var toolSelectionView: some View {
        HStack(spacing: 6) {
            // Pen
            toolButton(
                tool: createTool(type: .pen),
                icon: "pencil",
                isSelected: currentTool is PKInkingTool && instrument == .pen
            )
            
            // Marker (highlighter)
            toolButton(
                tool: createTool(type: .marker),
                icon: "highlighter",
                isSelected: currentTool is PKInkingTool && instrument == .marker
            )
            
            // Lasso (selection)
            toolButton(
                tool: PKLassoTool(),
                icon: "lasso",
                isSelected: currentTool is PKLassoTool
            )
            
            // Eraser
            toolButton(
                tool: PKEraserTool(.bitmap),
                icon: "eraser",
                isSelected: currentTool is PKEraserTool
            )
        }
    }
    
    // MARK: - Color Presets
    
    private var colorPresetsView: some View {
        HStack(spacing: 4) {
            ForEach(0..<ToolPresets.colors.count, id: \.self) { index in
                colorPresetButton(colorIndex: index)
            }
        }
    }
    
    private func colorPresetButton(colorIndex: Int) -> some View {
        let color = ToolPresets.colors[colorIndex]
        let isSelected = selectedColorIndex == colorIndex
        
        return Button(action: {
            selectedColorIndex = colorIndex
            updateToolWithCurrentSettings()
        }) {
            Circle()
                .fill(Color(color))
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.2), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(ToolPresets.colorNames[colorIndex])
    }
    
    // MARK: - Width Presets
    
    private var widthPresetsView: some View {
        HStack(spacing: 6) {
            ForEach(ToolPresets.StrokeWidth.allCases) { width in
                widthPresetButton(width: width)
            }
        }
    }
    
    private func widthPresetButton(width: ToolPresets.StrokeWidth) -> some View {
        let isSelected = selectedWidth == width
        
        return Button(action: {
            selectedWidth = width
            updateToolWithCurrentSettings()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.blue.opacity(0.15) : Color.clear)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .fill(Color.primary)
                    .frame(width: width.iconSize, height: width.iconSize)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(width.displayName)
    }
    
    // MARK: - Grid Toggle
    
    private var gridToggleButton: some View {
        Button(action: { onToggleGrid?() }) {
            Image(systemName: "grid")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(showGrid ? .blue : .primary)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(showGrid ? Color.blue.opacity(0.15) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsView: some View {
        HStack(spacing: 8) {
            // Undo
            Button(action: { onUndo?() }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 16, weight: .medium))
            }
            .disabled(!canUndo)
            .buttonStyle(.plain)
            .opacity(canUndo ? 1.0 : 0.3)
            
            // Redo
            Button(action: { onRedo?() }) {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 16, weight: .medium))
            }
            .disabled(!canRedo)
            .buttonStyle(.plain)
            .opacity(canRedo ? 1.0 : 0.3)
            
            // Clear
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
                        .stroke(isSelected ? Color.clear : Color.primary.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Methods
    
    private func createTool(type: PKInkingTool.InkType) -> PKInkingTool {
        let color = ToolPresets.colors[selectedColorIndex]
        let width = selectedWidth.rawValue
        return PKInkingTool(type, color: color, width: width)
    }
    
    private func updateToolWithCurrentSettings() {
        // Only update if we're using an inking tool
        guard currentTool is PKInkingTool else { return }
        
        let newTool = createTool(type: instrument)
        currentTool = newTool
        onToolChanged?(newTool)
    }
}

#else
// macOS placeholder
public struct CanvasToolbar: View {
    public var body: some View {
        Text("Canvas Toolbar - iOS only")
            .foregroundColor(.secondary)
    }
    
    public init(
        currentTool: Binding<PKTool>,
        inkColor: Binding<Any> = .constant(0),
        inkWidth: Binding<CGFloat> = .constant(5.0),
        instrument: Binding<PKInkingTool.InkType> = .constant(.pen),
        canUndo: Binding<Bool> = .constant(false),
        canRedo: Binding<Bool> = .constant(false),
        showGrid: Binding<Bool> = .constant(false),
        isVisible: Binding<Bool> = .constant(true),
        configuration: ToolbarConfiguration = ToolbarConfiguration(),
        onToolChanged: ((PKTool) -> Void)? = nil,
        onUndo: (() -> Void)? = nil,
        onRedo: (() -> Void)? = nil,
        onClear: (() -> Void)? = nil,
        onToggleGrid: (() -> Void)? = nil,
        onZoomIn: (() -> Void)? = nil,
        onZoomOut: (() -> Void)? = nil,
        onZoomReset: (() -> Void)? = nil
    ) {}
}
#endif

