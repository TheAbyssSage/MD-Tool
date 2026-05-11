import SwiftUI
import SwiftData

@main
struct MarkdownEditorApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document)
        }
        .modelContainer(for: Idea.self)
        .commands {
            ExportCommands()
        }
    }
}
