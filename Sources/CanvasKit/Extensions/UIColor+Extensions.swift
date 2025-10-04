import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit

/// Extensions for UIColor to support SwiftData storage
public extension UIColor {
    /// Convert UIColor to Data for SwiftData storage
    func toData() -> Data {
        return try! NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
    }
    
    /// Create UIColor from Data
    static func fromData(_ data: Data) -> UIColor? {
        return try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor
    }
    
    /// Convert to SwiftUI Color
    var swiftUIColor: Color {
        return Color(self)
    }
    
    /// Get RGB components (0-1 range)
    var rgbComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// Check if color is dark (useful for determining text color)
    var isDark: Bool {
        let components = rgbComponents
        let brightness = (components.red * 299 + components.green * 587 + components.blue * 114) / 1000
        return brightness < 0.5
    }
    
    /// Create a lighter version of the color
    func lighter(by percentage: CGFloat = 0.3) -> UIColor {
        return self.blend(with: UIColor.white, intensity: percentage)
    }
    
    /// Create a darker version of the color
    func darker(by percentage: CGFloat = 0.3) -> UIColor {
        return self.blend(with: UIColor.black, intensity: percentage)
    }
    
    /// Blend two colors
    private func blend(with color: UIColor, intensity: CGFloat) -> UIColor {
        let components1 = self.rgbComponents
        let components2 = color.rgbComponents
        
        let red = components1.red + (components2.red - components1.red) * intensity
        let green = components1.green + (components2.green - components1.green) * intensity
        let blue = components1.blue + (components2.blue - components1.blue) * intensity
        let alpha = components1.alpha + (components2.alpha - components1.alpha) * intensity
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
#endif

/// Extensions for CGSize to support SwiftData storage
public extension CGSize {
    /// Convert CGSize to Data for SwiftData storage
    func toData() -> Data {
        let dict = ["width": width, "height": height]
        return try! JSONSerialization.data(withJSONObject: dict)
    }
    
    /// Create CGSize from Data
    static func fromData(_ data: Data) -> CGSize? {
        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: CGFloat],
              let width = dict["width"],
              let height = dict["height"] else { return nil }
        return CGSize(width: width, height: height)
    }
    
    /// Check if size is landscape
    var isLandscape: Bool {
        return width > height
    }
    
    /// Check if size is portrait
    var isPortrait: Bool {
        return height > width
    }
    
    /// Check if size is square
    var isSquare: Bool {
        return abs(width - height) < 0.001
    }
    
    /// Get aspect ratio
    var aspectRatio: CGFloat {
        return width / height
    }
}