# CanvasKit

A powerful SwiftUI package for creating Apple Pencil-enabled canvases with flexible data management. CanvasKit supports both document-style canvases (multi-page) and infinite whiteboard canvases, with complete flexibility over data storage and persistence.

## Features

- **Document Canvas**: Multi-page documents with standard paper sizes (A4, Letter, Legal, etc.)
- **Whiteboard Canvas**: Infinite scrollable canvas with zoom and pan
- **Flexible Data Binding**: Use any data storage solution with `Data` bindings
- **SwiftData Integration**: Built-in SwiftData support for automatic persistence
- **Cross-Platform**: Works on iOS, macOS, and visionOS
- **PencilKit Integration**: Full Apple Pencil support with pressure sensitivity
- **Customizable Tools**: Pen, pencil, marker, eraser, and lasso tools
- **Export Capabilities**: Export drawings as images

## Installation

Add CanvasKit to your Swift package:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/CanvasKit.git", from: "1.0.0")
]
```

## Quick Start

### Document Canvas with Data Binding

```swift
import SwiftUI
import CanvasKit

struct DocumentView: View {
    @State private var canvasData = createDocumentCanvasData(title: "My Document", paperSize: .a4)
    
    var body: some View {
        DocumentCanvasDataView(canvasData: $canvasData)
    }
}
```

### Whiteboard Canvas with Data Binding

```swift
import SwiftUI
import CanvasKit

struct WhiteboardView: View {
    @State private var canvasData = createWhiteboardCanvasData(title: "My Whiteboard")
    
    var body: some View {
        WhiteboardCanvasDataView(canvasData: $canvasData)
    }
}
```

### Generic Canvas View (Auto-detects type)

```swift
import SwiftUI
import CanvasKit

struct CanvasView: View {
    @State private var canvasData = createCanvasData(title: "My Canvas", type: .document)
    
    var body: some View {
        CanvasDataView(canvasData: $canvasData)
    }
}
```

## Data Management

CanvasKit uses `Data` bindings for maximum flexibility. You can integrate with any storage solution:

### SwiftData Integration

```swift
import SwiftUI
import SwiftData
import CanvasKit

struct SwiftDataCanvasView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var canvasData = createDocumentCanvasData(title: "SwiftData Document")
    
    var body: some View {
        DocumentCanvasDataView(canvasData: $canvasData)
            .onChange(of: canvasData) { _, newData in
                // Save to SwiftData when data changes
                saveToSwiftData(newData)
            }
    }
    
    private func saveToSwiftData(_ data: Data) {
        // Convert Data to your SwiftData model
        // Implementation depends on your data model
    }
}
```

### Core Data Integration

```swift
import SwiftUI
import CoreData
import CanvasKit

struct CoreDataCanvasView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var canvasData = createWhiteboardCanvasData(title: "Core Data Whiteboard")
    
    var body: some View {
        WhiteboardCanvasDataView(canvasData: $canvasData)
            .onChange(of: canvasData) { _, newData in
                // Save to Core Data when data changes
                saveToCoreData(newData)
            }
    }
    
    private func saveToCoreData(_ data: Data) {
        // Save data to Core Data
        // Implementation depends on your Core Data model
    }
}
```

### File System Storage

```swift
import SwiftUI
import CanvasKit

struct FileSystemCanvasView: View {
    @State private var canvasData = createDocumentCanvasData(title: "File Document")
    private let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("canvas.data")
    
    var body: some View {
        DocumentCanvasDataView(canvasData: $canvasData)
            .onChange(of: canvasData) { _, newData in
                // Save to file system when data changes
                saveToFile(newData)
            }
            .onAppear {
                loadFromFile()
            }
    }
    
    private func saveToFile(_ data: Data) {
        try? data.write(to: fileURL)
    }
    
    private func loadFromFile() {
        if let data = try? Data(contentsOf: fileURL) {
            canvasData = data
        }
    }
}
```

## Canvas Types

### Document Canvas

Multi-page documents with standard paper sizes and templates.

```swift
// Create document canvas data
let documentData = createDocumentCanvasData(
    title: "My Document",
    paperSize: .a4
)

// Extract and modify document
var document = getDocumentData(from: documentData)!
document.addPage(template: .lined)
document.setTitle("Updated Title")

// Convert back to data
let updatedData = document.toData()
```

### Whiteboard Canvas

Infinite scrollable canvas with grid support.

```swift
// Create whiteboard canvas data
let whiteboardData = createWhiteboardCanvasData(title: "My Whiteboard")

// Extract and modify whiteboard
var whiteboard = getWhiteboardData(from: whiteboardData)!
whiteboard.setGridVisible(true)
whiteboard.setGridSize(25.0)
whiteboard.expandContentSizeIfNeeded()

// Convert back to data
let updatedData = whiteboard.toData()
```

## Paper Sizes and Templates

### Paper Sizes

```swift
enum PaperSize {
    case a4, a3, a2, a1, a0
    case letter, legal, tabloid
    case custom(width: Double, height: Double)
}
```

### Page Templates

```swift
enum PageTemplate {
    case blank, lined, grid, dotted, cornell
}
```

## Tools and Customization

### Creating Tools

```swift
#if canImport(UIKit)
// Create drawing tools
let pen = createPenTool(color: .black, width: 5.0)
let pencil = createPencilTool(color: .blue, width: 3.0)
let marker = createMarkerTool(color: .red, width: 8.0)
let eraser = createEraserTool()
let lasso = createLassoTool()
#endif
```

### Canvas Settings

```swift
let settings = CanvasSettings(
    zoomRange: 0.1...5.0,
    defaultZoom: 1.0,
    showRuler: false,
    enablePalmRejection: true,
    drawingPolicy: .anyInput
)
```

## Export and Conversion

### Export Drawings

```swift
#if canImport(UIKit)
// Export as image
if let image = exportDrawingAsImage(drawing) {
    // Save or share image
}

// Export with custom bounds and scale
if let image = exportDrawingAsImage(drawing, from: bounds, scale: 2.0) {
    // High-resolution export
}
#endif
```

### Data Conversion

```swift
// Convert drawing to data
let data = drawingToData(drawing)

// Create drawing from data
if let restoredDrawing = drawingFromData(data) {
    // Use restored drawing
}
```

## Advanced Usage

### Custom Canvas Data Wrapper

```swift
struct MyCanvasData {
    let id: UUID
    var title: String
    var canvasData: Data
    var metadata: [String: Any]
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.canvasData = createDocumentCanvasData(title: title)
        self.metadata = [:]
    }
    
    func updateCanvasData(_ newData: Data) {
        self.canvasData = newData
        // Update metadata, save to storage, etc.
    }
}
```

### Canvas with Toolbar

```swift
struct CanvasWithToolbar: View {
    @State private var canvasData = createDocumentCanvasData(title: "Document with Toolbar")
    #if canImport(UIKit)
    @State private var currentTool = createPenTool()
    @State private var inkColor = UIColor.black
    #endif
    @State private var inkWidth: CGFloat = 5.0
    
    var body: some View {
        VStack {
            #if canImport(UIKit)
            CanvasToolbarView(
                currentTool: $currentTool,
                inkColor: $inkColor,
                inkWidth: $inkWidth
            )
            #endif
            
            DocumentCanvasDataView(canvasData: $canvasData)
        }
    }
}
```

## Performance Considerations

- **Large Drawings**: CanvasKit automatically expands content size for infinite canvases
- **Memory Management**: Data bindings allow efficient memory usage
- **Zoom Performance**: Smooth zooming with optimized content size adjustments
- **Export Performance**: Efficient image export with customizable resolution

## Platform Support

- **iOS**: Full functionality with Apple Pencil support
- **visionOS**: Full functionality

## Requirements

- iOS 17.0+ / visionOS 1.0+
- Swift 6.0+

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests for any improvements.
