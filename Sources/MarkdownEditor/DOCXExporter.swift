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
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let word = tmp.appendingPathComponent("word")
        try FileManager.default.createDirectory(at: word, withIntermediateDirectories: true)
        try documentXML.write(to: word.appendingPathComponent("document.xml"), atomically: true, encoding: .utf8)

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
