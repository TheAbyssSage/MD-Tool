import Testing
@testable import MarkdownEditor

@Test func exporterRegistryHasFiveEngines() {
    #expect(ExporterRegistry.all.count == 5)
}

@Test func eachExporterHasUniqueExtension() {
    let extensions = ExporterRegistry.all.map(\.fileExtension)
    #expect(Set(extensions).count == extensions.count)
}

@Test func exporterExtensionsAreCorrect() {
    let extensions = Set(ExporterRegistry.all.map(\.fileExtension))
    #expect(extensions.contains("html"))
    #expect(extensions.contains("txt"))
    #expect(extensions.contains("pdf"))
    #expect(extensions.contains("docx"))
    #expect(extensions.contains("jpg"))
}
