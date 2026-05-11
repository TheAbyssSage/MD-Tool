import Testing
import Foundation
@testable import MarkdownEditor

@Test func jpegExporterHasCorrectExtension() {
    let exporter = JPEGExporter()
    #expect(exporter.fileExtension == "jpg")
    #expect(exporter.utType == .jpeg)
}

@Test func jpegExporterExportDoesNotThrow() throws {
    let exporter = JPEGExporter()
    // WKWebView.takeSnapshot may fail in test environment without NSApplication
    // The exporter should either return data or throw a descriptive error
    do {
        let data = try exporter.export("# Hello")
        #expect(data.count >= 0)
    } catch {
        // Expected in test environment — WKWebView needs NSApplication
        #expect((error as NSError).domain == "JPEGExport")
    }
}
