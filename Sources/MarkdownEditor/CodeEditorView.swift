import SwiftUI
import AppKit

struct CodeEditorView: NSViewRepresentable {
    @Binding var text: String
    @Binding var showLineNumbers: Bool

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        textView.delegate = context.coordinator
        textView.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.string = text
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.textColor
        textView.selectedTextAttributes = [.backgroundColor: NSColor.selectedTextBackgroundColor]

        // Line numbers
        if showLineNumbers {
            let lineNumberView = LineNumberRulerView(textView: textView)
            scrollView.verticalRulerView = lineNumberView
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
        }

        context.coordinator.textView = textView
        context.coordinator.applySyntaxHighlighting()

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            textView.setSelectedRange(selectedRange)
            context.coordinator.applySyntaxHighlighting()
        }

        // Update line numbers visibility
        if showLineNumbers {
            if nsView.verticalRulerView == nil {
                let lineNumberView = LineNumberRulerView(textView: textView)
                nsView.verticalRulerView = lineNumberView
                nsView.hasVerticalRuler = true
                nsView.rulersVisible = true
            }
        } else {
            nsView.hasVerticalRuler = false
            nsView.rulersVisible = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeEditorView
        weak var textView: NSTextView?

        init(_ parent: CodeEditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = textView else { return }
            parent.text = textView.string
            applySyntaxHighlighting()
        }

        @MainActor
        func applySyntaxHighlighting() {
            guard let textView = textView else { return }
            let text = textView.string
            let attributed = NSMutableAttributedString(string: text)
            let fullRange = NSRange(location: 0, length: text.utf16.count)

            // Base font
            attributed.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular), range: fullRange)
            attributed.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)

            // Markdown patterns
            let patterns: [(NSRegularExpression, NSColor)] = [
                (try! NSRegularExpression(pattern: "^#{1,6} .*$", options: .anchorsMatchLines), NSColor.systemBlue),       // Headers
                (try! NSRegularExpression(pattern: "\\*\\*[^*]+\\*\\*", options: []), NSColor.systemPurple),      // Bold
                (try! NSRegularExpression(pattern: "\\*[^*]+\\*", options: []), NSColor.systemOrange),          // Italic
                (try! NSRegularExpression(pattern: "`[^`]+`", options: []), NSColor.systemGreen),              // Inline code
                (try! NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)", options: []), NSColor.systemTeal), // Links
                (try! NSRegularExpression(pattern: "^> .*$", options: .anchorsMatchLines), NSColor.systemGray),       // Blockquotes
                (try! NSRegularExpression(pattern: "^[-*+] .*$", options: .anchorsMatchLines), NSColor.systemIndigo),   // Lists
                (try! NSRegularExpression(pattern: "^```.*$", options: .anchorsMatchLines), NSColor.systemPink),       // Code blocks
            ]

            for (regex, color) in patterns {
                regex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
                    guard let range = match?.range else { return }
                    attributed.addAttribute(.foregroundColor, value: color, range: range)
                }
            }

            // Preserve selection
            let selectedRange = textView.selectedRange()
            textView.textStorage?.setAttributedString(attributed)
            textView.setSelectedRange(selectedRange)
        }
    }
}

// MARK: - Line Numbers

class LineNumberRulerView: NSRulerView {
    weak var textView: NSTextView?

    init(textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: textView.enclosingScrollView!, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 40
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        let visibleRect = self.scrollView?.documentVisibleRect ?? .zero
        let visibleRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor
        ]

        layoutManager.enumerateLineFragments(forGlyphRange: visibleRange) { rect, _, _, _, _ in
            let lineNumber = self.lineNumberForCharacterIndex(layoutManager.characterIndexForGlyph(at: visibleRange.location))
            let lineString = "\(lineNumber)" as NSString
            let stringSize = lineString.size(withAttributes: attributes)
            let y = rect.origin.y - visibleRect.origin.y + (rect.height - stringSize.height) / 2
            lineString.draw(at: NSPoint(x: self.ruleThickness - stringSize.width - 5, y: y), withAttributes: attributes)
        }
    }

    private func lineNumberForCharacterIndex(_ index: Int) -> Int {
        guard let textView = textView else { return 1 }
        let text = textView.string
        let substring = text.prefix(index)
        return substring.components(separatedBy: .newlines).count
    }
}
