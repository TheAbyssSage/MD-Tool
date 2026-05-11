import Foundation
import UniformTypeIdentifiers

struct TextExporter: ExportEngine {
    let fileExtension = "txt"
    let utType = UTType.plainText

    func export(_ markdown: String) throws -> Data {
        let html = MarkdownParser.html(from: markdown)
        let text = html.strippedOfTags
        return text.data(using: .utf8)!
    }
}

private extension String {
    var strippedOfTags: String {
        self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
             .replacingOccurrences(of: "&lt;", with: "<")
             .replacingOccurrences(of: "&gt;", with: ">")
             .replacingOccurrences(of: "&amp;", with: "&")
    }
}
