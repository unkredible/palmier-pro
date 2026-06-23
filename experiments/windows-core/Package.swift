// swift-tools-version: 6.0
//
// EXPERIMENT — not part of the macOS app build.
// Goal: probe how much of PalmierPro's non-UI logic compiles on a
// non-Apple platform (Windows/Linux) once the AppKit/SwiftUI/AVFoundation
// layers are removed. Builds an isolated `PalmierCore` library from the
// 69 source files that import no Apple-only framework.
//
// Expected: cross-references into the macOS-only files surface as
// "cannot find type ... in scope" errors. That error list quantifies the
// refactoring a real Windows port would need.

import PackageDescription

let package = Package(
    name: "PalmierCore",
    products: [
        .library(name: "PalmierCore", targets: ["PalmierCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.11.0"),
        .package(url: "https://github.com/huggingface/swift-transformers", from: "1.3.3"),
    ],
    targets: [
        .target(
            name: "PalmierCore",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "Tokenizers", package: "swift-transformers"),
            ],
            path: "Sources/PalmierCore"
        ),
    ]
)
