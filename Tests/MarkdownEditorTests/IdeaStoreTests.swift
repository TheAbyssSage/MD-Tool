import Testing
import SwiftData
@testable import MarkdownEditor

@MainActor
@Test func insertAndFetchIdeas() throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: Idea.self, configurations: config)
    let store = IdeaStore(container: container)
    store.add(title: "Dark mode", detail: "Add system appearance support")
    #expect(store.ideas.count == 1)
    #expect(store.ideas.first?.title == "Dark mode")
}

@MainActor
@Test func toggleDoneChangesState() throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: Idea.self, configurations: config)
    let store = IdeaStore(container: container)
    store.add(title: "Test")
    let idea = store.ideas.first!
    #expect(idea.isDone == false)
    store.toggleDone(idea)
    #expect(store.ideas.first?.isDone == true)
}

@MainActor
@Test func deleteRemovesIdea() throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: Idea.self, configurations: config)
    let store = IdeaStore(container: container)
    store.add(title: "Test")
    #expect(store.ideas.count == 1)
    store.delete(store.ideas.first!)
    #expect(store.ideas.isEmpty)
}
