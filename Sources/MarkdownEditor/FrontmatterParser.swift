import Foundation

struct Frontmatter {
    var properties: [String: String] = [:]

    var isEmpty: Bool { properties.isEmpty }

    func displayString() -> String {
        properties.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
    }
}

enum FrontmatterParser {
    static func parse(_ text: String) -> (frontmatter: Frontmatter, body: String) {
        guard text.hasPrefix("---") else {
            return (Frontmatter(), text)
        }

        let lines = text.components(separatedBy: .newlines)
        guard lines.count > 2 else {
            return (Frontmatter(), text)
        }

        var frontmatterLines: [String] = []
        var inFrontmatter = false
        var bodyStartIndex = 0

        for (index, line) in lines.enumerated() {
            if line.trimmingCharacters(in: .whitespaces) == "---" {
                if !inFrontmatter {
                    inFrontmatter = true
                    continue
                } else {
                    bodyStartIndex = index + 1
                    break
                }
            }
            if inFrontmatter {
                frontmatterLines.append(line)
            }
        }

        var properties: [String: String] = [:]
        for line in frontmatterLines {
            let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1].trimmingCharacters(in: .whitespaces)
                properties[key] = value
            }
        }

        let body = lines[bodyStartIndex...].joined(separator: "\n")
        return (Frontmatter(properties: properties), body)
    }
}
