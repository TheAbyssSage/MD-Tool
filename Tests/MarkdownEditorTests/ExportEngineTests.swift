import Testing
import Foundation
@testable import MarkdownEditor

@Test func htmlExporterProducesHTML() throws {
    let exporter = HTMLExporter()
    let data = try exporter.export("# Hello")
    let html = String(data: data, encoding: .utf8)!
    #expect(html.contains("<h1>Hello</h1>"))
}

@Test func htmlExporterWrapsInDocType() throws {
    let exporter = HTMLExporter()
    let data = try exporter.export("test")
    let html = String(data: data, encoding: .utf8)!
    #expect(html.hasPrefix("<!DOCTYPE html>"))
}

@Test func textExporterStripsMarkdown() throws {
    let exporter = TextExporter()
    let data = try exporter.export("# Hello\n\nWorld")
    let text = String(data: data, encoding: .utf8)!
    #expect(text == "Hello\nWorld\n")
}

@Test func textExporterStripsBoldTags() throws {
    let exporter = TextExporter()
    let data = try exporter.export("**bold** text")
    let text = String(data: data, encoding: .utf8)!
    #expect(text == "bold text\n")
}
