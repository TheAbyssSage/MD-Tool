import Foundation
import cmark

enum MarkdownParser {
    static func html(from markdown: String) -> String {
        guard let cString = cmark_markdown_to_html(markdown, markdown.utf8.count, CMARK_OPT_DEFAULT)
        else { return "" }
        let html = String(cString: cString)
        free(cString)
        return html
    }
}
