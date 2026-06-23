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
        // swift-transformers (Tokenizers) dropped for this probe: its transitive
        // C dep yyjson tripped a Swift 6.0.x Windows toolchain bug (cyclic 'ucrt'
        // module) while compiling its manifest, before our sources were reached.
        // Its single consumer (Search/Models/TextTokenizer.swift) is excluded too.
    ],
    targets: [
        .target(
            name: "PalmierCore",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
            ],
            path: "Sources/PalmierCore"
        ),
    ]
)
