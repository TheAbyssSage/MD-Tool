import Foundation

enum ExportSettings {
    static var customCSS: String {
        get {
            UserDefaults.standard.string(forKey: "customExportCSS") ?? defaultCSS
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "customExportCSS")
        }
    }

    static let defaultCSS = """
    body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        line-height: 1.6;
        max-width: 800px;
        margin: 0 auto;
        padding: 2em;
        color: #333;
    }
    h1, h2, h3, h4, h5, h6 { color: #2c3e50; margin-top: 1.5em; }
    code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; }
    pre { background: #f4f4f4; padding: 1em; border-radius: 6px; overflow-x: auto; }
    blockquote { border-left: 4px solid #ddd; margin: 0; padding-left: 1em; color: #666; }
    a { color: #3498db; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background: #f4f4f4; }
    """
}
