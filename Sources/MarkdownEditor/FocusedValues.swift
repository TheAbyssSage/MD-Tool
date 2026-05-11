import SwiftUI

struct DocumentFocusedValueKey: FocusedValueKey {
    typealias Value = Binding<MarkdownDocument>
}

extension FocusedValues {
    var document: Binding<MarkdownDocument>? {
        get { self[DocumentFocusedValueKey.self] }
        set { self[DocumentFocusedValueKey.self] = newValue }
    }
}
