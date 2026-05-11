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
                .focusedValue(\.document, $document)
        }
    }
}

