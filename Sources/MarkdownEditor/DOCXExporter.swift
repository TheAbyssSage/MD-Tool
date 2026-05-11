import Foundation
import UniformTypeIdentifiers

struct DOCXExporter: ExportEngine {
    let fileExtension = "docx"
    let utType = UTType(filenameExtension: "docx")!

    func export(_ markdown: String) throws -> Data {
        return Data() // stub — implemented in Task 6
    }
}
