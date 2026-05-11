import SwiftUI

struct ContentView: View {
    @Binding var document: MarkdownDocument

    var body: some View {
        TextEditor(text: $document.text)
            .font(.system(.body, design: .monospaced))
            .padding()
    }
}
