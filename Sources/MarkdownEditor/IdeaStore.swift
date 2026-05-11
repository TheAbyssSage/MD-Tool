import Foundation
import SwiftData

@MainActor
final class IdeaStore: ObservableObject {
    private let container: ModelContainer
    private let context: ModelContext

    @Published var ideas: [Idea] = []

    init(container: ModelContainer) {
        self.container = container
        self.context = ModelContext(container)
        fetch()
    }

    func add(title: String, detail: String = "") {
        let idea = Idea(title: title, detail: detail)
        context.insert(idea)
        try? context.save()
        fetch()
    }

    func delete(_ idea: Idea) {
        context.delete(idea)
        try? context.save()
        fetch()
    }

    func toggleDone(_ idea: Idea) {
        idea.isDone.toggle()
        try? context.save()
        fetch()
    }

    func fetch() {
        let descriptor = FetchDescriptor<Idea>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        ideas = (try? context.fetch(descriptor)) ?? []
    }
}
