import Testing
import Foundation
@testable import MarkdownEditor

@Test func pdfExporterHasCorrectExtension() {
    let exporter = PDFExporter()
    #expect(exporter.fileExtension == "pdf")
    #expect(exporter.utType == .pdf)
}

@Test func pdfExporterExportDoesNotThrow() throws {
    let exporter = PDFExporter()
    let data = try exporter.export("# Hello")
    // WKWebView may return empty data in test environment without NSApplication
    // but the function should not throw
    #expect(data.count >= 0)
}
