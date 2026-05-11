import Testing
@testable import MarkdownEditor

@Test func parsesHeadingToHTML() {
    let html = MarkdownParser.html(from: "# Hello")
    #expect(html == "<h1>Hello</h1>\n")
}

@Test func parsesParagraphToHTML() {
    let html = MarkdownParser.html(from: "World")
    #expect(html == "<p>World</p>\n")
}

@Test func parsesBoldToHTML() {
    let html = MarkdownParser.html(from: "**bold**")
    #expect(html == "<p><strong>bold</strong></p>\n")
}

@Test func parsesEmptyString() {
    let html = MarkdownParser.html(from: "")
    #expect(html == "")
}
