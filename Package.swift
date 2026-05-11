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
    dependencies: [
        .package(url: "https://github.com/apple/swift-cmark.git", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "MarkdownEditor",
            dependencies: [
                .product(name: "cmark", package: "swift-cmark"),
            ]
        ),
        .testTarget(
            name: "MarkdownEditorTests",
            dependencies: ["MarkdownEditor"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
