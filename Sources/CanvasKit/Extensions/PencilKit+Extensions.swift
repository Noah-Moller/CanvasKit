import Foundation
import PencilKit

/// Extensions for PencilKit integration with SwiftData
public extension PKDrawing {
    /// Convert PKDrawing to Data for SwiftData storage
    func toData() -> Data {
        return self.dataRepresentation()
    }
    
    /// Create PKDrawing from Data
    static func fromData(_ data: Data) -> PKDrawing? {
        return try? PKDrawing(data: data)
    }
    
    /// Get the bounding rect of all strokes
    var boundingRect: CGRect {
        return self.bounds
    }
    
    /// Check if drawing has content
    var hasContent: Bool {
        return !self.strokes.isEmpty
    }
    
    /// Get the total number of strokes
    var strokeCount: Int {
        return self.strokes.count
    }
    
    /// Get the total stroke length in points (simplified calculation)
    var totalStrokeLength: CGFloat {
        return strokes.reduce(0) { total, stroke in
            total + stroke.renderBounds.width + stroke.renderBounds.height
        }
    }
    
    /// Create a copy of the drawing
    func copy() -> PKDrawing {
        let data = self.dataRepresentation()
        return (try? PKDrawing(data: data)) ?? PKDrawing()
    }
}

/// Extensions for PKStroke
public extension PKStroke {
    /// Get the stroke length in points (simplified calculation)
    var length: CGFloat {
        return self.renderBounds.width + self.renderBounds.height
    }
    
    /// Check if stroke is a dot (very small stroke)
    var isDot: Bool {
        return self.renderBounds.width < 5 && self.renderBounds.height < 5
    }
}

/// Extensions for PKTool
public extension PKTool {
    /// Get tool type as string
    var toolType: String {
        switch self {
        case is PKInkingTool:
            return "ink"
        case is PKEraserTool:
            return "eraser"
        case is PKLassoTool:
            return "lasso"
        default:
            return "unknown"
        }
    }
}