import Foundation
import UniformTypeIdentifiers

struct JPEGExporter: ExportEngine {
    let fileExtension = "jpg"
    let utType = UTType.jpeg

    func export(_ markdown: String) throws -> Data {
        return Data() // stub — implemented in Task 7
    }
}
