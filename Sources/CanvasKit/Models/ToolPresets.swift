import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Preset colors and stroke widths for minimal, quick-access toolbars
public struct ToolPresets {
    // MARK: - Color Presets
    
    #if canImport(UIKit)
    /// Curated color presets optimized for note-taking and sketching
    /// Matches GoodNotes-style quick color access
    public static let colors: [UIColor] = [
        .black,                    // Primary writing color
        UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0), // Dark gray
        UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0), // Blue
        UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0), // Red
        UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0),  // Orange
        UIColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1.0), // Green
        UIColor(red: 0.69, green: 0.32, blue: 0.87, alpha: 1.0), // Purple
        UIColor(red: 1.0, green: 0.18, blue: 0.33, alpha: 1.0), // Pink
    ]
    
    /// Color preset names for accessibility
    public static let colorNames: [String] = [
        "Black", "Gray", "Blue", "Red", 
        "Orange", "Green", "Purple", "Pink"
    ]
    #endif
    
    // MARK: - Stroke Width Presets
    
    /// Stroke width presets for quick selection
    /// Fine-grained control without overwhelming sliders
    public enum StrokeWidth: CGFloat, CaseIterable, Identifiable {
        case fine = 2.0
        case medium = 5.0
        case thick = 10.0
        
        public var id: CGFloat { rawValue }
        
        /// Display name for the width preset
        public var displayName: String {
            switch self {
            case .fine: return "Fine"
            case .medium: return "Medium"
            case .thick: return "Thick"
            }
        }
        
        /// Icon representation (using stroke circles)
        public var iconSize: CGFloat {
            switch self {
            case .fine: return 4.0
            case .medium: return 8.0
            case .thick: return 12.0
            }
        }
    }
    
    // MARK: - Helper Methods
    
    #if canImport(UIKit)
    /// Get SwiftUI Color from UIColor preset
    public static func swiftUIColor(at index: Int) -> Color {
        guard index >= 0 && index < colors.count else { return Color.black }
        return Color(colors[index])
    }
    
    /// Find closest color preset index for a given color
    public static func closestColorIndex(for color: UIColor) -> Int {
        var closestIndex = 0
        var minDistance = CGFloat.greatestFiniteMagnitude
        
        for (index, preset) in colors.enumerated() {
            let distance = colorDistance(color, preset)
            if distance < minDistance {
                minDistance = distance
                closestIndex = index
            }
        }
        
        return closestIndex
    }
    
    /// Calculate simple Euclidean distance between two colors
    private static func colorDistance(_ c1: UIColor, _ c2: UIColor) -> CGFloat {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return sqrt(pow(r1 - r2, 2) + pow(g1 - g2, 2) + pow(b1 - b2, 2))
    }
    #endif
    
    /// Find closest stroke width preset for a given width
    public static func closestWidth(for width: CGFloat) -> StrokeWidth {
        var closestWidth = StrokeWidth.medium
        var minDistance = CGFloat.greatestFiniteMagnitude
        
        for preset in StrokeWidth.allCases {
            let distance = abs(preset.rawValue - width)
            if distance < minDistance {
                minDistance = distance
                closestWidth = preset
            }
        }
        
        return closestWidth
    }
}

