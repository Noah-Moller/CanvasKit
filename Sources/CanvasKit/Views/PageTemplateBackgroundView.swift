import SwiftUI

/// Renders page template backgrounds (ruled, grid, dotted, Cornell)
/// beneath the PencilKit canvas for a paper-like writing experience
public struct PageTemplateBackgroundView: View {
    let template: PageTemplate
    let pageSize: CGSize
    
    // Colors for template elements
    private let lineColor = Color.blue.opacity(0.15)
    private let gridColor = Color.gray.opacity(0.2)
    private let dotColor = Color.gray.opacity(0.3)
    
    public init(template: PageTemplate, pageSize: CGSize) {
        self.template = template
        self.pageSize = pageSize
    }
    
    public var body: some View {
        ZStack {
            // White background
            Color.white
            
            // Template-specific pattern
            switch template {
            case .blank:
                EmptyView()
            case .lined:
                ruledLines
            case .grid:
                gridLines
            case .dotted:
                dottedPattern
            case .cornell:
                cornellLayout
            }
        }
        .frame(width: pageSize.width, height: pageSize.height)
    }
    
    // MARK: - Ruled Lines (Standard Notebook Paper)
    
    private var ruledLines: some View {
        GeometryReader { geometry in
            let lineSpacing: CGFloat = 28 // Standard ruled paper spacing
            let marginLeft: CGFloat = 50  // Left margin
            
            ZStack {
                // Horizontal lines
                Path { path in
                    var y: CGFloat = lineSpacing
                    while y < geometry.size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        y += lineSpacing
                    }
                }
                .stroke(lineColor, lineWidth: 1)
                
                // Left margin line
                Path { path in
                    path.move(to: CGPoint(x: marginLeft, y: 0))
                    path.addLine(to: CGPoint(x: marginLeft, y: geometry.size.height))
                }
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
            }
        }
    }
    
    // MARK: - Grid Pattern
    
    private var gridLines: some View {
        GeometryReader { geometry in
            let gridSize: CGFloat = 20 // Grid cell size
            
            Path { path in
                // Vertical lines
                var x: CGFloat = gridSize
                while x < geometry.size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    x += gridSize
                }
                
                // Horizontal lines
                var y: CGFloat = gridSize
                while y < geometry.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    y += gridSize
                }
            }
            .stroke(gridColor, lineWidth: 0.5)
        }
    }
    
    // MARK: - Dotted Pattern
    
    private var dottedPattern: some View {
        GeometryReader { geometry in
            let dotSpacing: CGFloat = 15 // Space between dots
            let dotSize: CGFloat = 1.5   // Dot diameter
            
            Canvas { context, size in
                var y: CGFloat = dotSpacing
                while y < size.height {
                    var x: CGFloat = dotSpacing
                    while x < size.width {
                        let rect = CGRect(x: x - dotSize/2, y: y - dotSize/2, 
                                        width: dotSize, height: dotSize)
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(dotColor)
                        )
                        x += dotSpacing
                    }
                    y += dotSpacing
                }
            }
        }
    }
    
    // MARK: - Cornell Notes Layout
    
    private var cornellLayout: some View {
        GeometryReader { geometry in
            let lineSpacing: CGFloat = 28
            let cueColumnWidth: CGFloat = geometry.size.width * 0.3
            let summaryHeight: CGFloat = 80
            
            ZStack {
                // Horizontal lines (in both cue and notes area)
                Path { path in
                    var y: CGFloat = lineSpacing
                    let endY = geometry.size.height - summaryHeight
                    while y < endY {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        y += lineSpacing
                    }
                }
                .stroke(lineColor, lineWidth: 1)
                
                // Vertical divider between cue column and notes area
                Path { path in
                    path.move(to: CGPoint(x: cueColumnWidth, y: 0))
                    path.addLine(to: CGPoint(x: cueColumnWidth, 
                                           y: geometry.size.height - summaryHeight))
                }
                .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
                
                // Horizontal divider for summary area
                Path { path in
                    let summaryY = geometry.size.height - summaryHeight
                    path.move(to: CGPoint(x: 0, y: summaryY))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: summaryY))
                }
                .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
                
                // Labels (subtle)
                VStack {
                    HStack(alignment: .top, spacing: 0) {
                        Text("Cues")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.6))
                            .frame(width: cueColumnWidth, alignment: .center)
                            .padding(.top, 4)
                        
                        Text("Notes")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    Text("Summary")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                        .frame(height: summaryHeight, alignment: .top)
                }
            }
        }
    }
}

#Preview("Ruled Lines") {
    PageTemplateBackgroundView(template: .lined, pageSize: CGSize(width: 595, height: 842))
}

#Preview("Grid") {
    PageTemplateBackgroundView(template: .grid, pageSize: CGSize(width: 595, height: 842))
}

#Preview("Dotted") {
    PageTemplateBackgroundView(template: .dotted, pageSize: CGSize(width: 595, height: 842))
}

#Preview("Cornell") {
    PageTemplateBackgroundView(template: .cornell, pageSize: CGSize(width: 595, height: 842))
}

