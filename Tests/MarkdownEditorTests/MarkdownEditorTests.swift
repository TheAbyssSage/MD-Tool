import Testing
import Foundation
@testable import MarkdownEditor

@Test func documentInitializesWithText() {
    let doc = MarkdownDocument(text: "# Hello\n\nWorld")
    #expect(doc.text == "# Hello\n\nWorld")
}

@Test func documentDefaultInitializerHasEmptyText() {
    let doc = MarkdownDocument()
    #expect(doc.text == "")
}

@Test func documentTextIsMutable() {
    var doc = MarkdownDocument(text: "initial")
    doc.text = "modified"
    #expect(doc.text == "modified")
}

@Test func documentReadableContentTypesIncludesMarkdown() {
    let types = MarkdownDocument.readableContentTypes
    #expect(types.contains(.markdown))
    #expect(types.contains(.plainText))
}
