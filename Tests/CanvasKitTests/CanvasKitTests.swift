import XCTest
@testable import CanvasKit
import PencilKit
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

final class CanvasKitTests: XCTestCase {
    
    // MARK: - Model Tests
    
    func testCanvasDocumentCreation() {
        let document = CanvasDocument(title: "Test Document", paperSize: .a4)
        
        XCTAssertEqual(document.title, "Test Document")
        XCTAssertEqual(document.paperSize, .a4)
        XCTAssertEqual(document.pages.count, 1)
        XCTAssertEqual(document.pageCount, 1)
    }
    
    func testCanvasPageCreation() {
        let page = CanvasPage(pageNumber: 1, paperSize: .a4, template: .lined)
        
        XCTAssertEqual(page.pageNumber, 1)
        XCTAssertEqual(page.paperSize, .a4)
        XCTAssertEqual(page.template, .lined)
        XCTAssertFalse(page.hasContent)
    }
    
    func testWhiteboardCanvasCreation() {
        let canvas = WhiteboardCanvas(title: "Test Whiteboard")
        
        XCTAssertEqual(canvas.title, "Test Whiteboard")
        XCTAssertEqual(canvas.contentSize, CGSize(width: 2000, height: 2000))
        XCTAssertFalse(canvas.showGrid)
        XCTAssertFalse(canvas.snapToGrid)
        XCTAssertEqual(canvas.gridSize, 20.0)
        XCTAssertFalse(canvas.hasContent)
    }
    
    // MARK: - Data Model Tests
    
    func testDocumentCanvasDataCreation() {
        let data = createDocumentCanvasData(title: "Test Document", paperSize: .a4)
        let document = getDocumentData(from: data)
        
        XCTAssertNotNil(document)
        XCTAssertEqual(document?.title, "Test Document")
        XCTAssertEqual(document?.paperSize, .a4)
        XCTAssertEqual(document?.pageCount, 1)
        XCTAssertFalse(document?.hasContent ?? true)
    }
    
    func testWhiteboardCanvasDataCreation() {
        let data = createWhiteboardCanvasData(title: "Test Whiteboard")
        let whiteboard = getWhiteboardData(from: data)
        
        XCTAssertNotNil(whiteboard)
        XCTAssertEqual(whiteboard?.title, "Test Whiteboard")
        XCTAssertEqual(whiteboard?.contentSize, CGSize(width: 2000, height: 2000))
        XCTAssertFalse(whiteboard?.showGrid ?? true)
        XCTAssertFalse(whiteboard?.hasContent ?? true)
    }
    
    func testCanvasDataCreation() {
        let data = createCanvasData(title: "Test Canvas", type: .document)
        let canvas = getCanvasData(from: data)
        
        XCTAssertNotNil(canvas)
        XCTAssertEqual(canvas?.title, "Test Canvas")
        XCTAssertEqual(canvas?.canvasType, .document)
    }
    
    func testDocumentCanvasDataOperations() {
        var data = createDocumentCanvasData(title: "Test Document")
        var document = getDocumentData(from: data)!
        
        XCTAssertEqual(document.pageCount, 1)
        
        // Add page
        document.addPage(template: .lined)
        XCTAssertEqual(document.pageCount, 2)
        XCTAssertEqual(document.pages[1].template, .lined)
        
        // Insert page
        document.insertPage(at: 1, template: .grid)
        XCTAssertEqual(document.pageCount, 3)
        XCTAssertEqual(document.pages[1].template, .grid)
        
        // Remove page
        document.removePage(at: 1)
        XCTAssertEqual(document.pageCount, 2)
        
        // Convert back to data
        data = document.toData()
        let restoredDocument = getDocumentData(from: data)
        XCTAssertEqual(restoredDocument?.pageCount, 2)
    }
    
    func testWhiteboardCanvasDataExpansion() {
        var data = createWhiteboardCanvasData(title: "Test Whiteboard")
        var whiteboard = getWhiteboardData(from: data)!
        
        let initialSize = whiteboard.contentSize
        
        // Test with empty drawing - should not change content size
        whiteboard.expandContentSizeIfNeeded()
        XCTAssertEqual(whiteboard.contentSize, initialSize)
        
        // Convert back to data
        data = whiteboard.toData()
        let restoredWhiteboard = getWhiteboardData(from: data)
        XCTAssertEqual(restoredWhiteboard?.contentSize, initialSize)
    }
    
    func testDataSerialization() {
        // Test document data serialization
        let documentData = createDocumentCanvasData(title: "Serialization Test")
        let document = getDocumentData(from: documentData)!
        
        let serializedData = document.toData()
        let deserializedDocument = getDocumentData(from: serializedData)
        
        XCTAssertEqual(document.title, deserializedDocument?.title)
        XCTAssertEqual(document.pageCount, deserializedDocument?.pageCount)
        
        // Test whiteboard data serialization
        let whiteboardData = createWhiteboardCanvasData(title: "Whiteboard Test")
        let whiteboard = getWhiteboardData(from: whiteboardData)!
        
        let serializedWhiteboardData = whiteboard.toData()
        let deserializedWhiteboard = getWhiteboardData(from: serializedWhiteboardData)
        
        XCTAssertEqual(whiteboard.title, deserializedWhiteboard?.title)
        XCTAssertEqual(whiteboard.contentSize, deserializedWhiteboard?.contentSize)
    }
    
    // MARK: - Paper Size Tests
    
    func testPaperSizes() {
        let a4 = PaperSize.a4
        XCTAssertEqual(a4.displayName, "A4")
        XCTAssertFalse(a4.isLandscape)
        XCTAssertGreaterThan(a4.aspectRatio, 0.5)
        
        let letter = PaperSize.letter
        XCTAssertEqual(letter.displayName, "Letter")
        XCTAssertFalse(letter.isLandscape)
    }
    
    func testPageTemplates() {
        let blank = PageTemplate.blank
        XCTAssertEqual(blank.displayName, "Blank")
        XCTAssertEqual(blank.lineSpacing, 0)
        
        let lined = PageTemplate.lined
        XCTAssertEqual(lined.displayName, "Lined")
        XCTAssertEqual(lined.lineSpacing, 24)
    }
    
    // MARK: - Extension Tests
    
    func testPKDrawingExtensions() {
        let drawing = PKDrawing()
        XCTAssertFalse(drawing.hasContent)
        XCTAssertEqual(drawing.strokeCount, 0)
        
        let data = drawing.toData()
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data.count, 0)
        
        let restoredDrawing = PKDrawing.fromData(data)
        XCTAssertNotNil(restoredDrawing)
        XCTAssertEqual(restoredDrawing?.strokeCount, 0)
    }
    
    #if canImport(UIKit)
    func testUIColorExtensions() {
        let color = UIColor.red
        let data = color.toData()
        XCTAssertNotNil(data)
        
        let restoredColor = UIColor.fromData(data)
        XCTAssertNotNil(restoredColor)
        
        let components1 = color.rgbComponents
        let components2 = restoredColor!.rgbComponents
        
        XCTAssertEqual(components1.red, components2.red, accuracy: 0.01)
        XCTAssertEqual(components1.green, components2.green, accuracy: 0.01)
        XCTAssertEqual(components1.blue, components2.blue, accuracy: 0.01)
        XCTAssertEqual(components1.alpha, components2.alpha, accuracy: 0.01)
    }
    #endif
    
    func testCGSizeExtensions() {
        let size = CGSize(width: 100, height: 200)
        let data = size.toData()
        XCTAssertNotNil(data)
        
        let restoredSize = CGSize.fromData(data)
        XCTAssertNotNil(restoredSize)
        XCTAssertEqual(restoredSize?.width, 100)
        XCTAssertEqual(restoredSize?.height, 200)
        XCTAssertTrue(restoredSize!.isPortrait)
    }
    
    // MARK: - Utility Function Tests
    
    #if canImport(UIKit)
    func testToolCreation() {
        let pen = createPenTool(color: .red, width: 5.0)
        XCTAssertTrue(pen is PKInkingTool)
        XCTAssertEqual((pen as? PKInkingTool)?.color, UIColor.red)
        XCTAssertEqual((pen as? PKInkingTool)?.width, 5.0)
        
        let pencil = createPencilTool(color: .blue, width: 3.0)
        XCTAssertTrue(pencil is PKInkingTool)
        XCTAssertEqual((pencil as? PKInkingTool)?.color, UIColor.blue)
        XCTAssertEqual((pencil as? PKInkingTool)?.width, 3.0)
        
        let eraser = createEraserTool()
        XCTAssertTrue(eraser is PKEraserTool)
        
        let lasso = createLassoTool()
        XCTAssertTrue(lasso is PKLassoTool)
    }
    #endif
    
    func testPaperSizeByName() {
        let a4 = paperSize(named: "A4")
        XCTAssertNotNil(a4)
        XCTAssertEqual(a4, .a4)
        
        let letter = paperSize(named: "letter")
        XCTAssertNotNil(letter)
        XCTAssertEqual(letter, .letter)
        
        let invalid = paperSize(named: "Invalid")
        XCTAssertNil(invalid)
    }
    
    func testPageTemplateByName() {
        let blank = pageTemplate(named: "Blank")
        XCTAssertNotNil(blank)
        XCTAssertEqual(blank, .blank)
        
        let lined = pageTemplate(named: "lined")
        XCTAssertNotNil(lined)
        XCTAssertEqual(lined, .lined)
        
        let invalid = pageTemplate(named: "Invalid")
        XCTAssertNil(invalid)
    }
    
    // MARK: - Document Operations Tests
    
    func testDocumentPageOperations() {
        let document = CanvasDocument(title: "Test Document")
        XCTAssertEqual(document.pageCount, 1)
        
        // Add page
        document.addPage(template: .lined)
        XCTAssertEqual(document.pageCount, 2)
        XCTAssertEqual(document.pages[1].template, .lined)
        
        // Insert page
        document.insertPage(at: 1, template: .grid)
        XCTAssertEqual(document.pageCount, 3)
        XCTAssertEqual(document.pages[1].template, .grid)
        
        // Remove page
        document.removePage(at: 1)
        XCTAssertEqual(document.pageCount, 2)
        
        // Can't remove last page
        document.removePage(at: 0)
        XCTAssertEqual(document.pageCount, 1) // Should still have 1 page
    }
    
    func testWhiteboardContentExpansion() {
        let canvas = WhiteboardCanvas(title: "Test")
        let initialSize = canvas.contentSize
        
        // Test with empty drawing - should not change content size
        canvas.expandContentSizeIfNeeded()
        XCTAssertEqual(canvas.contentSize, initialSize)
        
        // Test that the method handles infinity bounds gracefully
        let drawing = PKDrawing()
        canvas.drawing = drawing
        canvas.expandContentSizeIfNeeded()
        // Should still be the same as initial size since empty drawing has infinite bounds
        XCTAssertEqual(canvas.contentSize, initialSize)
    }
    
    // MARK: - Performance Tests
    
    func testDrawingDataConversionPerformance() {
        let drawing = PKDrawing()
        // Add some strokes to make it more realistic
        // Note: This would require creating actual strokes in a real implementation
        
        measure {
            for _ in 0..<1000 {
                let data = drawing.toData()
                _ = PKDrawing.fromData(data)
            }
        }
    }
    
    #if canImport(UIKit)
    func testColorDataConversionPerformance() {
        let color = UIColor.red
        
        measure {
            for _ in 0..<1000 {
                let data = color.toData()
                _ = UIColor.fromData(data)
            }
        }
    }
    #endif
    
    func testSizeDataConversionPerformance() {
        let size = CGSize(width: 100, height: 200)
        
        measure {
            for _ in 0..<1000 {
                let data = size.toData()
                _ = CGSize.fromData(data)
            }
        }
    }
}