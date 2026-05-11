// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "MarkdownEditor",
    platforms: [.macOS(.v14)],
    products: [
        .executable(
            name: "MarkdownEditor",
            targets: ["MarkdownEditor"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "MarkdownEditor"
        ),
        .testTarget(
            name: "MarkdownEditorTests",
            dependencies: ["MarkdownEditor"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
