import Foundation
import AppKit
import UniformTypeIdentifiers
@preconcurrency import WebKit

struct JPEGExporter: ExportEngine {
    let fileExtension = "jpg"
    let utType = UTType.jpeg

    func export(_ markdown: String) throws -> Data {
        let html = try HTMLExporter().export(markdown)
        let htmlString = String(data: html, encoding: .utf8)!

        nonisolated(unsafe) var result: Data?
        nonisolated(unsafe) var exportError: Error?
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.main.async {
            let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
            webView.loadHTMLString(htmlString, baseURL: nil)
            webView.evaluateJavaScript("document.readyState") { _, _ in
                webView.takeSnapshot(with: nil) { snap, _ in
                    guard let image = snap,
                          let tiff = image.tiffRepresentation,
                          let bitmap = NSBitmapImageRep(data: tiff),
                          let jpeg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
                    else {
                        exportError = NSError(domain: "JPEGExport", code: 1)
                        semaphore.signal()
                        return
                    }
                    result = jpeg
                    semaphore.signal()
                }
            }
        }

        semaphore.wait()
        if let error = exportError { throw error }
        return result ?? Data()
    }
}
