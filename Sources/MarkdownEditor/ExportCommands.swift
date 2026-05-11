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
                .keyboardShortcut(shortcut(for: exporter.fileExtension))
                .disabled(document == nil)
            }
        }
    }

    private func shortcut(for ext: String) -> KeyboardShortcut? {
        switch ext {
        case "html": return KeyboardShortcut(.init("h"), modifiers: [.command, .shift])
        case "txt":  return KeyboardShortcut(.init("t"), modifiers: [.command, .shift])
        case "pdf":  return KeyboardShortcut(.init("p"), modifiers: [.command, .shift])
        case "docx": return KeyboardShortcut(.init("d"), modifiers: [.command, .shift])
        case "jpg":  return KeyboardShortcut(.init("j"), modifiers: [.command, .shift])
        default: return nil
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
