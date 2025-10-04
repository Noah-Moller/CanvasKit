import SwiftUI
import PencilKit

#if canImport(UIKit)
import UIKit
#endif

/// Toolbar view for canvas controls and tools (iOS only)
#if canImport(UIKit)
public struct CanvasToolbarView: View {
    // MARK: - Properties
    
    /// Current tool
    @Binding public var currentTool: PKTool
    
    /// Current ink color
    @Binding public var inkColor: UIColor
    
    /// Current ink width
    @Binding public var inkWidth: CGFloat
    
    /// Current instrument type
    @Binding public var instrument: PKInkingTool.InkType
    
    /// Toolbar configuration
    public var configuration: ToolbarConfiguration
    
    /// Callbacks
    public var onToolChanged: ((PKTool) -> Void)?
    public var onUndo: (() -> Void)?
    public var onRedo: (() -> Void)?
    public var onClear: (() -> Void)?
    public var onExport: (() -> Void)?
    
    // MARK: - Initialization
    
    public init(
        currentTool: Binding<PKTool>,
        inkColor: Binding<UIColor> = .constant(.black),
        inkWidth: Binding<CGFloat> = .constant(5.0),
        instrument: Binding<PKInkingTool.InkType> = .constant(.pen),
        configuration: ToolbarConfiguration = ToolbarConfiguration(),
        onToolChanged: ((PKTool) -> Void)? = nil,
        onUndo: (() -> Void)? = nil,
        onRedo: (() -> Void)? = nil,
        onClear: (() -> Void)? = nil,
        onExport: (() -> Void)? = nil
    ) {
        self._currentTool = currentTool
        self._inkColor = inkColor
        self._inkWidth = inkWidth
        self._instrument = instrument
        self.configuration = configuration
        self.onToolChanged = onToolChanged
        self.onUndo = onUndo
        self.onRedo = onRedo
        self.onClear = onClear
        self.onExport = onExport
    }
    
    // MARK: - Body
    
    public var body: some View {
        HStack(spacing: configuration.spacing) {
            // Tool selection
            toolSelectionView
            
            // Ink controls
            if currentTool is PKInkingTool {
                inkControlsView
            }
            
            Spacer()
            
            // Action buttons
            actionButtonsView
        }
        .padding(.horizontal, configuration.horizontalPadding)
        .padding(.vertical, configuration.verticalPadding)
        .background(configuration.backgroundColor.swiftUIColor)
        .cornerRadius(configuration.cornerRadius)
        .shadow(radius: configuration.shadowRadius)
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
            
            // Lasso tool
            toolButton(
                tool: PKLassoTool(),
                icon: "lasso",
                isSelected: currentTool is PKLassoTool
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
                    .frame(width: 100)
            }
            
            // Instrument selector
            Picker("Instrument", selection: $instrument) {
                Text("Pen").tag(PKInkingTool.InkType.pen)
                Text("Pencil").tag(PKInkingTool.InkType.pencil)
                Text("Marker").tag(PKInkingTool.InkType.marker)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 120)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsView: some View {
        HStack(spacing: 8) {
            // Undo button
            Button(action: { onUndo?() }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(configuration.buttonColor.swiftUIColor)
            }
            .disabled(!configuration.canUndo)
            
            // Redo button
            Button(action: { onRedo?() }) {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(configuration.buttonColor.swiftUIColor)
            }
            .disabled(!configuration.canRedo)
            
            // Clear button
            Button(action: { onClear?() }) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
            }
            
            // Export button
            if configuration.showExportButton {
                Button(action: { onExport?() }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(configuration.buttonColor.swiftUIColor)
                }
            }
        }
    }
    
    // MARK: - Tool Button
    
    private func toolButton(tool: PKTool, icon: String, isSelected: Bool) -> some View {
        Button(action: {
            currentTool = tool
            onToolChanged?(tool)
        }) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isSelected ? .white : configuration.buttonColor.swiftUIColor)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(configuration.buttonColor.swiftUIColor, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Toolbar Configuration

public struct ToolbarConfiguration {
    public var spacing: CGFloat
    public var horizontalPadding: CGFloat
    public var verticalPadding: CGFloat
    public var cornerRadius: CGFloat
    public var shadowRadius: CGFloat
    public var backgroundColor: UIColor
    public var buttonColor: UIColor
    public var canUndo: Bool
    public var canRedo: Bool
    public var showExportButton: Bool
    
    public init(
        spacing: CGFloat = 12,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 12,
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 2,
        backgroundColor: UIColor = UIColor.systemBackground,
        buttonColor: UIColor = UIColor.label,
        canUndo: Bool = false,
        canRedo: Bool = false,
        showExportButton: Bool = true
    ) {
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.backgroundColor = backgroundColor
        self.buttonColor = buttonColor
        self.canUndo = canUndo
        self.canRedo = canRedo
        self.showExportButton = showExportButton
    }
}

#else
// macOS placeholder
public struct CanvasToolbarView: View {
    public var body: some View {
        Text("Canvas Toolbar - iOS only")
            .foregroundColor(.secondary)
    }
    
    public init(currentTool: Binding<PKTool>) {}
}

public struct ToolbarConfiguration {
    public init() {}
}
#endif