import Foundation
import UniformTypeIdentifiers

struct HTMLExporter: ExportEngine {
    let fileExtension = "html"
    let utType = UTType.html

    func export(_ markdown: String) throws -> Data {
        let body = MarkdownParser.html(from: markdown)
        let full = """
        <!DOCTYPE html>
        <html><head><meta charset="utf-8"></head><body>\(body)</body></html>
        """
        return full.data(using: .utf8)!
    }
}
