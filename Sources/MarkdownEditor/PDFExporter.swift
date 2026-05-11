import Foundation
import UniformTypeIdentifiers

struct PDFExporter: ExportEngine {
    let fileExtension = "pdf"
    let utType = UTType.pdf

    func export(_ markdown: String) throws -> Data {
        return Data() // stub — implemented in Task 5
    }
}
