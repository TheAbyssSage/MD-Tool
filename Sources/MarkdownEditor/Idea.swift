import Foundation
import SwiftData

@Model
final class Idea {
    var id: UUID
    var title: String
    var detail: String
    var createdAt: Date
    var isDone: Bool

    init(title: String, detail: String = "") {
        self.id = UUID()
        self.title = title
        self.detail = detail
        self.createdAt = Date()
        self.isDone = false
    }
}
