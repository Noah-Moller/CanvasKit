import SwiftUI

#if canImport(UIKit)
import UIKit

/// Page navigation view with dots indicator and swipe gestures
public struct PageNavigationView: View {
    // MARK: - Properties
    
    /// Current page index (0-based)
    @Binding public var currentPageIndex: Int
    
    /// Total number of pages
    public var pageCount: Int
    
    /// Callback when page changes
    public var onPageChanged: ((Int) -> Void)?
    
    /// Configuration
    public var showPageNumbers: Bool = true
    public var showPageDots: Bool = true
    public var enableSwipeGestures: Bool = true
    
    // MARK: - Initialization
    
    public init(
        currentPageIndex: Binding<Int>,
        pageCount: Int,
        showPageNumbers: Bool = true,
        showPageDots: Bool = true,
        enableSwipeGestures: Bool = true,
        onPageChanged: ((Int) -> Void)? = nil
    ) {
        self._currentPageIndex = currentPageIndex
        self.pageCount = pageCount
        self.showPageNumbers = showPageNumbers
        self.showPageDots = showPageDots
        self.enableSwipeGestures = enableSwipeGestures
        self.onPageChanged = onPageChanged
    }
    
    // MARK: - Body
    
    public var body: some View {
        if pageCount > 1 {
            VStack(spacing: 8) {
                // Page dots indicator
                if showPageDots {
                    HStack(spacing: 8) {
                        ForEach(0..<min(pageCount, 10), id: \.self) { index in
                            Circle()
                                .fill(index == currentPageIndex ? Color.primary : Color.secondary.opacity(0.3))
                                .frame(width: index == currentPageIndex ? 8 : 6, height: index == currentPageIndex ? 8 : 6)
                                .animation(.easeInOut(duration: 0.2), value: currentPageIndex)
                        }
                        
                        if pageCount > 10 {
                            Text("...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Page number indicator
                if showPageNumbers {
                    Text("Page \(currentPageIndex + 1) of \(pageCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

/// Swipe gesture modifier for page navigation
public struct PageSwipeModifier: ViewModifier {
    @Binding var currentPageIndex: Int
    let pageCount: Int
    let onPageChanged: ((Int) -> Void)?
    
    public func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        
                        if horizontalAmount > 50 && currentPageIndex > 0 {
                            // Swipe right - go to previous page
                            let newIndex = currentPageIndex - 1
                            currentPageIndex = newIndex
                            onPageChanged?(newIndex)
                        } else if horizontalAmount < -50 && currentPageIndex < pageCount - 1 {
                            // Swipe left - go to next page
                            let newIndex = currentPageIndex + 1
                            currentPageIndex = newIndex
                            onPageChanged?(newIndex)
                        }
                    }
            )
    }
}

public extension View {
    /// Add page swipe navigation to a view
    func pageSwipeNavigation(
        currentPageIndex: Binding<Int>,
        pageCount: Int,
        onPageChanged: ((Int) -> Void)? = nil
    ) -> some View {
        modifier(PageSwipeModifier(
            currentPageIndex: currentPageIndex,
            pageCount: pageCount,
            onPageChanged: onPageChanged
        ))
    }
}

#else
// macOS placeholder
public struct PageNavigationView: View {
    public var body: some View {
        Text("Page Navigation - iOS only")
            .foregroundColor(.secondary)
    }
    
    public init(
        currentPageIndex: Binding<Int>,
        pageCount: Int,
        showPageNumbers: Bool = true,
        showPageDots: Bool = true,
        enableSwipeGestures: Bool = true,
        onPageChanged: ((Int) -> Void)? = nil
    ) {}
}
#endif

