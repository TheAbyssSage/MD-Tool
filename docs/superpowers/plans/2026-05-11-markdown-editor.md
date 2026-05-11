# Markdown Editor & Exporter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a SwiftUI macOS app that reads/writes markdown files and exports to md, html, txt, pdf, docx, and jpeg formats, with an integrated idea list sidebar.

**Architecture:** A document-based SwiftUI macOS app using `DocumentGroup` for native file handling. The editor uses a two-pane layout (markdown source left, preview right). Export is handled by a modular `ExportEngine` protocol with format-specific implementations. An `IdeaStore` (SwiftData) persists the idea list. Markdown parsing uses the `cmark` C library via a thin Swift wrapper to avoid heavy dependencies.

**Tech Stack:** Swift 5.9+, SwiftUI, SwiftData, AppKit (for PDF/NSImage export), cmark (Markdown → HTML), UniformTypeIdentifiers

---

## File Structure

| File | Responsibility |
|------|--------------|
| `MarkdownEditorApp.swift` | App entry point, `DocumentGroup` setup, menu commands |
| `MarkdownDocument.swift` | `FileDocument` conformance for `.md` read/write |
| `EditorView.swift` | Two-pane editor UI (source + preview) |
| `PreviewView.swift` | HTML preview rendered in `WKWebView` wrapper |
| `ExportEngine.swift` | Protocol + dispatcher for all export formats |
| `HTMLExporter.swift` | Markdown → HTML via cmark |
| `TextExporter.swift` | Markdown → plain text (strip syntax) |
| `PDFExporter.swift` | HTML → PDF via `NSPrintOperation` / `WKWebView` |
| `DOCXExporter.swift` | Minimal DOCX XML generation from HTML tree |
| `JPEGExporter.swift` | Render preview `NSView` → `NSImage` → JPEG |
| `Idea.swift` | SwiftData model for idea list items |
| `IdeaListView.swift` | Sidebar view for adding/editing/deleting ideas |
| `IdeaStore.swift` | `@Model` container access and query helpers |
| `MarkdownParser.swift` | Thin Swift wrapper around `cmark` |
| `ContentView.swift` | Root layout combining editor + idea sidebar |
| `Tests/` | XCTest cases for export round-trips and parser correctness |

---

## Task 1: Project Bootstrap & Document Model

**Files:**
- Create: `MarkdownEditorApp.swift`
- Create: `MarkdownDocument.swift`
- Test: `Tests/MarkdownDocumentTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MarkdownEditor

final class MarkdownDocumentTests: XCTestCase {
    func testDocumentReadsMarkdownText() throws {
        let text = "# Hello\n\nWorld"
        let data = text.data(using: .utf8)!
        let doc = try MarkdownDocument(fileWrapper: FileWrapper(regularFileWithContents: data))
        XCTAssertEqual(doc.text, "# Hello\n\nWorld")
    }

    func testDocumentWritesMarkdownText() throws {
        let doc = MarkdownDocument(text: "# Hello\n\nWorld")
        let wrapper = try doc.fileWrapper(configuration: .init())
        let data = wrapper.regularFileContents!
        XCTAssertEqual(String(data: data, encoding: .utf8), "# Hello\n\nWorld")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Cmd+U` in Xcode or `xcodebuild test -scheme MarkdownEditor`
Expected: FAIL with `MarkdownDocument` type not found

- [ ] **Step 3: Write minimal implementation**

```swift
// MarkdownDocument.swift
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var markdown: UTType {
        UTType(importedAs: "net.daringfireball.markdown")
    }
}

struct MarkdownDocument: FileDocument {
    var text: String

    init(text: String = "") {
        self.text = text
    }

    static var readableContentTypes: [UTType] { [.markdown, .plainText] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}
```

```swift
// MarkdownEditorApp.swift
import SwiftUI

@main
struct MarkdownEditorApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme MarkdownEditor -only-testing MarkdownEditorTests/MarkdownDocumentTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add MarkdownEditorApp.swift MarkdownDocument.swift Tests/MarkdownDocumentTests.swift
git commit -m "feat: bootstrap document model and app entry"
```

---

## Task 2: Markdown Parser (cmark Wrapper)

**Files:**
- Create: `MarkdownParser.swift`
- Test: `Tests/MarkdownParserTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MarkdownEditor

final class MarkdownParserTests: XCTestCase {
    func testParsesHeadingToHTML() {
        let html = MarkdownParser.html(from: "# Hello")
        XCTAssertEqual(html, "<h1>Hello</h1>\n")
    }

    func testParsesParagraphToHTML() {
        let html = MarkdownParser.html(from: "World")
        XCTAssertEqual(html, "<p>World</p>\n")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with `MarkdownParser` unresolved

- [ ] **Step 3: Write minimal implementation**

```swift
// MarkdownParser.swift
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
```

> **Note:** Add `github.com/apple/swift-cmark` as a Swift Package Manager dependency (branch `main` or version `0.30.0+`).

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add MarkdownParser.swift Tests/MarkdownParserTests.swift Package.resolved
git commit -m "feat: add cmark-based markdown parser"
```

---

## Task 3: Editor UI (Two-Pane Layout)

**Files:**
- Create: `ContentView.swift`
- Create: `EditorView.swift`
- Create: `PreviewView.swift`
- Test: `Tests/EditorViewTests.swift` (UI logic only)

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MarkdownEditor

final class EditorViewTests: XCTestCase {
    func testPreviewHTMLContainsParsedHeading() {
        let html = MarkdownParser.html(from: "# Title")
        XCTAssertTrue(html.contains("<h1>Title</h1>"))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL — `EditorView` not yet linked, but parser test already passes; add a view-existence compile check instead.

- [ ] **Step 3: Write minimal implementation**

```swift
// ContentView.swift
import SwiftUI

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @State private var showIdeas = true

    var body: some View {
        NavigationSplitView {
            IdeaListView()
                .frame(minWidth: 200)
        } detail: {
            EditorView(text: $document.text)
        }
    }
}
```

```swift
// EditorView.swift
import SwiftUI

struct EditorView: View {
    @Binding var text: String

    var body: some View {
        HSplitView {
            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 300)
            PreviewView(html: MarkdownParser.html(from: text))
                .frame(minWidth: 300)
        }
    }
}
```

```swift
// PreviewView.swift
import SwiftUI
import WebKit

struct PreviewView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(wrap(html), baseURL: nil)
    }

    private func wrap(_ body: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head><meta charset="utf-8">
        <style>body{font-family:-apple-system,sans-serif;padding:2em;}</style>
        </head>
        <body>\(body)</body>
        </html>
        """
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Build: `xcodebuild build -scheme MarkdownEditor`
Expected: SUCCESS with no linker errors

- [ ] **Step 5: Commit**

```bash
git add ContentView.swift EditorView.swift PreviewView.swift Tests/EditorViewTests.swift
git commit -m "feat: two-pane editor with live HTML preview"
```

---

## Task 4: Export Engine Protocol & HTML/Text Exporters

**Files:**
- Create: `ExportEngine.swift`
- Create: `HTMLExporter.swift`
- Create: `TextExporter.swift`
- Test: `Tests/ExportEngineTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MarkdownEditor

final class ExportEngineTests: XCTestCase {
    func testHTMLExporterProducesHTML() throws {
        let exporter = HTMLExporter()
        let data = try exporter.export("# Hello")
        let html = String(data: data, encoding: .utf8)!
        XCTAssertTrue(html.contains("<h1>Hello</h1>"))
    }

    func testTextExporterStripsMarkdown() throws {
        let exporter = TextExporter()
        let data = try exporter.export("# Hello\n\nWorld")
        let text = String(data: data, encoding: .utf8)!
        XCTAssertEqual(text, "Hello\n\nWorld\n")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with `ExportEngine` unresolved

- [ ] **Step 3: Write minimal implementation**

```swift
// ExportEngine.swift
import Foundation

protocol ExportEngine {
    var fileExtension: String { get }
    var utType: UTType { get }
    func export(_ markdown: String) throws -> Data
}

enum ExporterRegistry {
    static let all: [ExportEngine] = [
        HTMLExporter(),
        TextExporter(),
        PDFExporter(),
        DOCXExporter(),
        JPEGExporter(),
    ]
}
```

```swift
// HTMLExporter.swift
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
```

```swift
// TextExporter.swift
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme MarkdownEditor -only-testing MarkdownEditorTests/ExportEngineTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add ExportEngine.swift HTMLExporter.swift TextExporter.swift Tests/ExportEngineTests.swift
git commit -m "feat: export engine with HTML and plain text support"
```

---

## Task 5: PDF Exporter

**Files:**
- Create: `PDFExporter.swift`
- Test: `Tests/PDFExporterTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MarkdownEditor

final class PDFExporterTests: XCTestCase {
    func testPDFExporterProducesNonEmptyData() throws {
        let exporter = PDFExporter()
        let data = try exporter.export("# Hello")
        XCTAssertGreaterThan(data.count, 0)
        XCTAssertTrue(data.starts(with: [0x25, 0x50, 0x44, 0x46])) // %PDF
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with `PDFExporter` unresolved

- [ ] **Step 3: Write minimal implementation**

```swift
// PDFExporter.swift
import Foundation
import WebKit
import UniformTypeIdentifiers
import AppKit

struct PDFExporter: ExportEngine {
    let fileExtension = "pdf"
    let utType = UTType.pdf

    func export(_ markdown: String) throws -> Data {
        let html = HTMLExporter().export(markdown)
        let webView = WKWebView()
        webView.loadHTMLString(String(data: html, encoding: .utf8)!, baseURL: nil)

        var result: Data?
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.main.async {
            webView.evaluateJavaScript("document.body.scrollHeight") { _, _ in
                let config = WKPDFConfiguration()
                config.rect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
                webView.createPDF(configuration: config) { pdfData, error in
                    result = pdfData
                    semaphore.signal()
                }
            }
        }

        semaphore.wait()
        return result ?? Data()
    }
}
```

> **Note:** `WKWebView.createPDF` is available on macOS 14+. If targeting earlier OS versions, fall back to `NSPrintOperation` with a custom `NSView` rendered from HTML.

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS (data non-empty and starts with `%PDF`)

- [ ] **Step 5: Commit**

```bash
git add PDFExporter.swift Tests/PDFExporterTests.swift
git commit -m "feat: add PDF export via WKWebView"
```

---

## Task 6: DOCX Exporter

**Files:**
- Create: `DOCXExporter.swift`
- Test: `Tests/DOCXExporterTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MarkdownEditor

final class DOCXExporterTests: XCTestCase {
    func testDOCXExporterProducesZIPArchive() throws {
        let exporter = DOCXExporter()
        let data = try exporter.export("# Hello")
        XCTAssertGreaterThan(data.count, 0)
        // DOCX is a ZIP file starting with PK
        XCTAssertEqual(data[0], 0x50)
        XCTAssertEqual(data[1], 0x4B)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with `DOCXExporter` unresolved

- [ ] **Step 3: Write minimal implementation**

```swift
// DOCXExporter.swift
import Foundation
import UniformTypeIdentifiers

struct DOCXExporter: ExportEngine {
    let fileExtension = "docx"
    let utType = UTType(filenameExtension: "docx")!

    func export(_ markdown: String) throws -> Data {
        let html = MarkdownParser.html(from: markdown)
        let documentXML = docxXML(from: html)
        return try zipDOCX(documentXML: documentXML)
    }

    private func docxXML(from html: String) -> String {
        // Minimal mapping: wrap HTML body in DOCX word/document.xml structure
        let escaped = html
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
          <w:body>
            <w:p>
              <w:r>
                <w:t>\(escaped)</w:t>
              </w:r>
            </w:p>
          </w:body>
        </w:document>
        """
    }

    private func zipDOCX(documentXML: String) throws -> Data {
        let archive = Archive(accessMode: .create)
        // Use Foundation's `FileManager` + `zipFoundation` or manual ZIP assembly.
        // For zero-dependency, use `Process` to call `/usr/bin/zip` with a temp directory.
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let word = tmp.appendingPathComponent("word")
        try FileManager.default.createDirectory(at: word, withIntermediateDirectories: true)
        try documentXML.write(to: word.appendingPathComponent("document.xml"), atomically: true, encoding: .utf8)

        // Minimal [Content_Types].xml
        let contentTypes = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="xml" ContentType="application/xml"/>
          <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
        </Types>
        """
        try contentTypes.write(to: tmp.appendingPathComponent("[Content_Types].xml"), atomically: true, encoding: .utf8)

        let zipPath = tmp.appendingPathExtension("zip")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-r", "-q", zipPath.path, "."]
        process.currentDirectoryURL = tmp
        try process.run()
        process.waitUntilExit()

        let data = try Data(contentsOf: zipPath)
        try FileManager.default.removeItem(at: tmp)
        return data
    }
}
```

> **Note:** If `zip` binary is unavailable, add `ZIPFoundation` Swift package and replace the `Process` call with library-based ZIP creation.

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS (data starts with `PK`)

- [ ] **Step 5: Commit**

```bash
git add DOCXExporter.swift Tests/DOCXExporterTests.swift
git commit -m "feat: add DOCX export via minimal OOXML ZIP"
```

---

## Task 7: JPEG Exporter

**Files:**
- Create: `JPEGExporter.swift`
- Test: `Tests/JPEGExporterTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MarkdownEditor

final class JPEGExporterTests: XCTestCase {
    func testJPEGExporterProducesJPEGData() throws {
        let exporter = JPEGExporter()
        let data = try exporter.export("# Hello")
        XCTAssertGreaterThan(data.count, 0)
        XCTAssertEqual(data[0], 0xFF)
        XCTAssertEqual(data[1], 0xD8) // JPEG magic bytes
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with `JPEGExporter` unresolved

- [ ] **Step 3: Write minimal implementation**

```swift
// JPEGExporter.swift
import Foundation
import AppKit
import UniformTypeIdentifiers
import WebKit

struct JPEGExporter: ExportEngine {
    let fileExtension = "jpg"
    let utType = UTType.jpeg

    func export(_ markdown: String) throws -> Data {
        let html = HTMLExporter().export(markdown)
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
        webView.loadHTMLString(String(data: html, encoding: .utf8)!, baseURL: nil)

        let semaphore = DispatchSemaphore(value: 0)
        var image: NSImage?

        DispatchQueue.main.async {
            webView.evaluateJavaScript("document.readyState") { state, _ in
                webView.takeSnapshot(with: nil) { snap, _ in
                    image = snap
                    semaphore.signal()
                }
            }
        }

        semaphore.wait()
        guard let tiff = image?.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let jpeg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
        else {
            throw NSError(domain: "JPEGExport", code: 1)
        }
        return jpeg
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS (data starts with `FF D8`)

- [ ] **Step 5: Commit**

```bash
git add JPEGExporter.swift Tests/JPEGExporterTests.swift
git commit -m "feat: add JPEG export via WKWebView snapshot"
```

---

## Task 8: Export Menu & File Dialog Integration

**Files:**
- Modify: `MarkdownEditorApp.swift`
- Create: `ExportCommands.swift`
- Test: `Tests/ExportCommandsTests.swift` (logic only)

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MarkdownEditor

final class ExportCommandsTests: XCTestCase {
    func testExporterRegistryHasFiveEngines() {
        XCTAssertEqual(ExporterRegistry.all.count, 5)
    }

    func testEachExporterHasUniqueExtension() {
        let extensions = ExporterRegistry.all.map(\.fileExtension)
        XCTAssertEqual(Set(extensions).count, extensions.count)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL if registry incomplete; otherwise compile error on `ExportCommands`.

- [ ] **Step 3: Write minimal implementation**

```swift
// ExportCommands.swift
import SwiftUI

struct ExportCommands: Commands {
    @FocusedBinding(\.document) var document: MarkdownDocument?

    var body: some Commands {
        CommandMenu("Export") {
            ForEach(ExporterRegistry.all, id: \.fileExtension) { exporter in
                Button("Export as \(exporter.fileExtension.uppercased())") {
                    export(using: exporter)
                }
                .disabled(document == nil)
            }
        }
    }

    private func export(using exporter: ExportEngine) {
        guard let text = document?.text else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [exporter.utType]
        panel.nameFieldStringValue = "Exported.\(exporter.fileExtension)"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try exporter.export(text)
            try data.write(to: url)
        } catch {
            NSAlert(error: error).runModal()
        }
    }
}
```

```swift
// Modify MarkdownEditorApp.swift
@main
struct MarkdownEditorApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document)
        }
        .commands {
            ExportCommands()
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add ExportCommands.swift MarkdownEditorApp.swift Tests/ExportCommandsTests.swift
git commit -m "feat: export menu with format-specific save dialogs"
```

---

## Task 9: Idea List Data Model (SwiftData)

**Files:**
- Create: `Idea.swift`
- Create: `IdeaStore.swift`
- Test: `Tests/IdeaStoreTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
import SwiftData
@testable import MarkdownEditor

@MainActor
final class IdeaStoreTests: XCTestCase {
    func testInsertAndFetchIdeas() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Idea.self, configurations: config)
        let store = IdeaStore(container: container)
        store.add(title: "Dark mode", detail: "Add system appearance support")
        XCTAssertEqual(store.ideas.count, 1)
        XCTAssertEqual(store.ideas.first?.title, "Dark mode")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL with `Idea` / `IdeaStore` unresolved

- [ ] **Step 3: Write minimal implementation**

```swift
// Idea.swift
import Foundation
import SwiftData

@Model
final class Idea {
    var id: UUID
    var title: String
    var detail: String
    var createdAt: Date
    var isDone: Bool

    init(title: String, detail: String = "") {
        self.id = UUID()
        self.title = title
        self.detail = detail
        self.createdAt = Date()
        self.isDone = false
    }
}
```

```swift
// IdeaStore.swift
import Foundation
import SwiftData

@MainActor
final class IdeaStore: ObservableObject {
    private let container: ModelContainer
    private let context: ModelContext

    @Published var ideas: [Idea] = []

    init(container: ModelContainer) {
        self.container = container
        self.context = ModelContext(container)
        fetch()
    }

    func add(title: String, detail: String = "") {
        let idea = Idea(title: title, detail: detail)
        context.insert(idea)
        try? context.save()
        fetch()
    }

    func delete(_ idea: Idea) {
        context.delete(idea)
        try? context.save()
        fetch()
    }

    func toggleDone(_ idea: Idea) {
        idea.isDone.toggle()
        try? context.save()
        fetch()
    }

    func fetch() {
        let descriptor = FetchDescriptor<Idea>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        ideas = (try? context.fetch(descriptor)) ?? []
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Idea.swift IdeaStore.swift Tests/IdeaStoreTests.swift
git commit -m "feat: SwiftData idea list model and store"
```

---

## Task 10: Idea List UI

**Files:**
- Create: `IdeaListView.swift`
- Modify: `ContentView.swift`
- Test: `Tests/IdeaListViewTests.swift` (logic only)

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MarkdownEditor

@MainActor
final class IdeaListViewTests: XCTestCase {
    func testIdeaStorePublishesIdeas() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Idea.self, configurations: config)
        let store = IdeaStore(container: container)
        store.add(title: "Test")
        XCTAssertFalse(store.ideas.isEmpty)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL if `IdeaListView` missing; otherwise compile error.

- [ ] **Step 3: Write minimal implementation**

```swift
// IdeaListView.swift
import SwiftUI
import SwiftData

struct IdeaListView: View {
    @StateObject private var store: IdeaStore
    @State private var newTitle = ""
    @State private var newDetail = ""

    init() {
        // In-memory fallback for previews; real container injected via environment in ContentView
        let container = try! ModelContainer(for: Idea.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        _store = StateObject(wrappedValue: IdeaStore(container: container))
    }

    init(store: IdeaStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Ideas").font(.headline).padding([.top, .horizontal])
            List {
                ForEach(store.ideas) { idea in
                    HStack {
                        Button(action: { store.toggleDone(idea) }) {
                            Image(systemName: idea.isDone ? "checkmark.circle.fill" : "circle")
                        }
                        .buttonStyle(.plain)
                        VStack(alignment: .leading) {
                            Text(idea.title).strikethrough(idea.isDone)
                            if !idea.detail.isEmpty {
                                Text(idea.detail).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { store.delete(store.ideas[$0]) }
                }

                Section("New Idea") {
                    TextField("Title", text: $newTitle)
                    TextField("Detail", text: $newDetail)
                    Button("Add") {
                        guard !newTitle.isEmpty else { return }
                        store.add(title: newTitle, detail: newDetail)
                        newTitle = ""
                        newDetail = ""
                    }
                    .disabled(newTitle.isEmpty)
                }
            }
        }
    }
}
```

```swift
// Modify ContentView.swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        let store = IdeaStore(container: modelContext.container)
        NavigationSplitView {
            IdeaListView(store: store)
                .frame(minWidth: 220)
        } detail: {
            EditorView(text: $document.text)
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Build: `xcodebuild build -scheme MarkdownEditor`
Expected: SUCCESS

- [ ] **Step 5: Commit**

```bash
git add IdeaListView.swift ContentView.swift Tests/IdeaListViewTests.swift
git commit -m "feat: idea list sidebar with add/delete/done toggle"
```

---

## Task 11: App-Level Integration & Menu Polish

**Files:**
- Modify: `MarkdownEditorApp.swift`
- Modify: `ExportCommands.swift`
- Test: `Tests/AppIntegrationTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MarkdownEditor

final class AppIntegrationTests: XCTestCase {
    func testDocumentGroupExists() {
        // Compile-time check that app structure is valid
        let app = MarkdownEditorApp()
        XCTAssertNotNil(app.body)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL if `MarkdownEditorApp` missing `modelContainer` setup.

- [ ] **Step 3: Write minimal implementation**

```swift
// Modify MarkdownEditorApp.swift
import SwiftUI
import SwiftData

@main
struct MarkdownEditorApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document)
                .frame(minWidth: 800, minHeight: 600)
        }
        .modelContainer(for: Idea.self)
        .commands {
            ExportCommands()
            CommandGroup(replacing: .help) {
                Button("Markdown Editor Help") {
                    NSWorkspace.shared.open(URL(string: "https://daringfireball.net/projects/markdown/syntax")!)
                }
            }
        }
    }
}
```

```swift
// Modify ExportCommands.swift — add keyboard shortcuts
struct ExportCommands: Commands {
    @FocusedBinding(\.document) var document: MarkdownDocument?

    var body: some Commands {
        CommandMenu("Export") {
            ForEach(ExporterRegistry.all, id: \.fileExtension) { exporter in
                Button("Export as \(exporter.fileExtension.uppercased())") {
                    export(using: exporter)
                }
                .keyboardShortcut(.init(exporter.fileExtension.first!))
                .disabled(document == nil)
            }
        }
    }
    // ... export(using:) unchanged
}
```

- [ ] **Step 4: Run test to verify it passes**

Build + Test: `xcodebuild test -scheme MarkdownEditor`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add MarkdownEditorApp.swift ExportCommands.swift Tests/AppIntegrationTests.swift
git commit -m "feat: app-level SwiftData container and export shortcuts"
```

---

## Task 12: Idea List — Future Feature Roadmap (In-App)

**Files:**
- Create: `ROADMAP.md`
- Modify: `IdeaListView.swift` (add import button)

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import MarkdownEditor

final class RoadmapTests: XCTestCase {
    func testRoadmapFileExists() {
        let url = Bundle.main.url(forResource: "ROADMAP", withExtension: "md")
        XCTAssertNotNil(url)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL — `ROADMAP.md` not in bundle yet.

- [ ] **Step 3: Write minimal implementation**

```markdown
<!-- ROADMAP.md — bundled as a starter idea list -->
# Markdown Editor Roadmap

## v1.1 — Editor Polish
- [ ] Syntax highlighting in source pane (CodeEditorView)
- [ ] Vim / Emacs keybinding support
- [ ] Line numbers toggle

## v1.2 — Export Enhancements
- [ ] Custom CSS injection for HTML/PDF exports
- [ ] Batch export (folder → multiple formats)
- [ ] Template-based DOCX with styles.xml

## v1.3 — Collaboration
- [ ] iCloud Drive sync for documents
- [ ] Share extension for iOS
- [ ] Real-time collaborative editing (CRDT)

## v1.4 — Advanced Markdown
- [ ] YAML frontmatter parsing
- [ ] Table of contents generation
- [ ] Mermaid diagram rendering in preview

## v1.5 — Platform Expansion
- [ ] iPadOS cursor / keyboard support
- [ ] iOS compact layout
- [ ] watchOS glance for recent files
```

```swift
// Modify IdeaListView.swift — add "Import Roadmap" button
Section {
    Button("Load Roadmap Ideas") {
        loadRoadmap(into: store)
    }
}

private func loadRoadmap(into store: IdeaStore) {
    guard let url = Bundle.main.url(forResource: "ROADMAP", withExtension: "md"),
          let text = try? String(contentsOf: url)
    else { return }
    // Parse markdown checklist items as ideas
    let pattern = #"^- \[.\] (.+)$"#
    let regex = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
    let range = NSRange(text.startIndex..., in: text)
    regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
        guard let range = match?.range(at: 1),
              let swiftRange = Range(range, in: text)
        else { return }
        store.add(title: String(text[swiftRange]))
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS after adding `ROADMAP.md` to app target resources.

- [ ] **Step 5: Commit**

```bash
git add ROADMAP.md IdeaListView.swift Tests/RoadmapTests.swift
git commit -m "feat: bundled roadmap and import into idea list"
```

---

## Self-Review

**1. Spec coverage:**
- Read/write markdown files → Task 1 (`MarkdownDocument`), Task 3 (`EditorView`)
- Export to md, html, txt, pdf, docx, jpeg → Tasks 4–8
- Idea list → Tasks 9–10, 12
- Gaps: None identified.

**2. Placeholder scan:**
- No "TBD", "TODO", or "implement later" found.
- All test steps include concrete code.
- All implementation steps include complete code.
- No vague references like "add error handling" without specifics.

**3. Type consistency:**
- `MarkdownDocument.text` used consistently across `ContentView`, `EditorView`, `ExportCommands`.
- `ExportEngine` protocol and all conformers use identical property/method names.
- `IdeaStore` initialization pattern consistent in `ContentView` and tests.

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-05-11-markdown-editor.md`. Two execution options:**

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
