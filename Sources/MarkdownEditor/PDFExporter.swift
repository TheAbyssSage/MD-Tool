import Foundation
@preconcurrency import WebKit
import UniformTypeIdentifiers

struct PDFExporter: ExportEngine {
    let fileExtension = "pdf"
    let utType = UTType.pdf

    func export(_ markdown: String) throws -> Data {
        let html = try HTMLExporter().export(markdown)
        let htmlString = String(data: html, encoding: .utf8)!

        nonisolated(unsafe) var result: Data?
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.main.async {
            let webView = WKWebView()
            webView.loadHTMLString(htmlString, baseURL: nil)
            webView.evaluateJavaScript("document.body.scrollHeight") { _, _ in
                let config = WKPDFConfiguration()
                config.rect = CGRect(x: 0, y: 0, width: 612, height: 792)
                webView.createPDF(configuration: config) { pdfResult in
                    switch pdfResult {
                    case .success(let data): result = data
                    case .failure: result = nil
                    }
                    semaphore.signal()
                }
            }
        }

        semaphore.wait()
        return result ?? Data()
    }
}
