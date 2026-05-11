import SwiftUI
import AppKit

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

    private func export(using exporter: any ExportEngine) {
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
