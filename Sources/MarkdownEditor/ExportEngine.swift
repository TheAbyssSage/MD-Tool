import Foundation
import UniformTypeIdentifiers

protocol ExportEngine: Sendable {
    var fileExtension: String { get }
    var utType: UTType { get }
    func export(_ markdown: String) throws -> Data
}

enum ExporterRegistry {
    static let all: [any ExportEngine] = [
        HTMLExporter(),
        TextExporter(),
        PDFExporter(),
        DOCXExporter(),
        JPEGExporter(),
    ]
}
