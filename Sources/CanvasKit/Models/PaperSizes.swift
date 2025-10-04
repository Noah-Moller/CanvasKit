import Foundation
import SwiftUI

/// Standard paper sizes and custom paper size support
public enum PaperSize: CaseIterable, Codable, Identifiable, Sendable, Equatable {
    case a4, a3, a2, a1, a0
    case letter, legal, tabloid
    case custom(width: Double, height: Double)
    
    public static var allCases: [PaperSize] {
        return [.a4, .a3, .a2, .a1, .a0, .letter, .legal, .tabloid]
    }
    
    public var id: String {
        switch self {
        case .a4: return "a4"
        case .a3: return "a3"
        case .a2: return "a2"
        case .a1: return "a1"
        case .a0: return "a0"
        case .letter: return "letter"
        case .legal: return "legal"
        case .tabloid: return "tabloid"
        case .custom(let width, let height):
            return "custom_\(width)_\(height)"
        }
    }
    
    /// Returns the size in points (72 DPI)
    public var cgSize: CGSize {
        switch self {
        case .a4: return CGSize(width: 595, height: 842) // A4 at 72 DPI
        case .a3: return CGSize(width: 842, height: 1191) // A3 at 72 DPI
        case .a2: return CGSize(width: 1191, height: 1684) // A2 at 72 DPI
        case .a1: return CGSize(width: 1684, height: 2384) // A1 at 72 DPI
        case .a0: return CGSize(width: 2384, height: 3370) // A0 at 72 DPI
        case .letter: return CGSize(width: 612, height: 792) // Letter at 72 DPI
        case .legal: return CGSize(width: 612, height: 1008) // Legal at 72 DPI
        case .tabloid: return CGSize(width: 792, height: 1224) // Tabloid at 72 DPI
        case .custom(let width, let height):
            return CGSize(width: width, height: height)
        }
    }
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .a4: return "A4"
        case .a3: return "A3"
        case .a2: return "A2"
        case .a1: return "A1"
        case .a0: return "A0"
        case .letter: return "Letter"
        case .legal: return "Legal"
        case .tabloid: return "Tabloid"
        case .custom(let width, let height):
            return "Custom (\(Int(width)) × \(Int(height)))"
        }
    }
    
    /// Aspect ratio of the paper
    public var aspectRatio: Double {
        let size = cgSize
        return size.width / size.height
    }
    
    /// Check if this is a landscape orientation
    public var isLandscape: Bool {
        return aspectRatio > 1.0
    }
}

/// Page templates for different use cases
public enum PageTemplate: CaseIterable, Codable, Identifiable, Sendable, Equatable {
    case blank, lined, grid, dotted, cornell
    
    public static var allCases: [PageTemplate] {
        return [.blank, .lined, .grid, .dotted, .cornell]
    }
    
    public var id: String {
        switch self {
        case .blank: return "blank"
        case .lined: return "lined"
        case .grid: return "grid"
        case .dotted: return "dotted"
        case .cornell: return "cornell"
        }
    }
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .blank: return "Blank"
        case .lined: return "Lined"
        case .grid: return "Grid"
        case .dotted: return "Dotted"
        case .cornell: return "Cornell"
        }
    }
    
    /// Line spacing for lined templates (in points)
    public var lineSpacing: CGFloat {
        switch self {
        case .blank, .grid, .dotted, .cornell: return 0
        case .lined: return 24 // Standard lined paper spacing
        }
    }
    
    /// Grid size for grid templates (in points)
    public var gridSize: CGFloat {
        switch self {
        case .blank, .lined, .dotted, .cornell: return 0
        case .grid: return 20 // Standard grid size
        }
    }
}