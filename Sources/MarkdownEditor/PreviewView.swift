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
