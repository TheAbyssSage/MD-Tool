import SwiftUI
import SwiftData

struct IdeaListView: View {
    @StateObject private var store: IdeaStore
    @State private var newTitle = ""
    @State private var newDetail = ""

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
