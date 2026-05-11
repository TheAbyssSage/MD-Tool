import Testing
import Foundation
@testable import MarkdownEditor

@Test func docxExporterHasCorrectExtension() {
    let exporter = DOCXExporter()
    #expect(exporter.fileExtension == "docx")
}

@Test func docxExporterProducesZIPArchive() throws {
    let exporter = DOCXExporter()
    let data = try exporter.export("# Hello")
    #expect(data.count > 0)
    // DOCX is a ZIP file starting with PK
    #expect(data[0] == 0x50)
    #expect(data[1] == 0x4B)
}
