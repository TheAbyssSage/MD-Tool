import Testing
@testable import MarkdownEditor

@Test func previewHTMLContainsParsedHeading() {
    let html = MarkdownParser.html(from: "# Title")
    #expect(html.contains("<h1>Title</h1>"))
}

@Test func previewHTMLContainsParsedParagraph() {
    let html = MarkdownParser.html(from: "Hello world")
    #expect(html.contains("<p>Hello world</p>"))
}
