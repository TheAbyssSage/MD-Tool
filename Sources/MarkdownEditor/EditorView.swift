import SwiftUI

struct EditorView: View {
    @Binding var text: String

    var body: some View {
        HSplitView {
            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 300)
            PreviewView(html: MarkdownParser.html(from: text))
                .frame(minWidth: 300)
        }
    }
}
