// swift-tools-version: 6.0
//
// EXPERIMENT — not part of the macOS app build.
// Goal: probe how much of PalmierPro's non-UI logic compiles on a
// non-Apple platform (Windows/Linux) once the AppKit/SwiftUI/AVFoundation
// layers are removed. Builds an isolated `PalmierCore` library from the
// import-clean source files, with NO third-party dependencies.
//
// Earlier iterations were blocked outside our code:
//   - swift-transformers (Tokenizers) pulled yyjson, which tripped a Swift
//     6.0.x Windows toolchain bug (cyclic 'ucrt' module) at manifest compile.
//   - MCP (swift-sdk) failed to build on Windows: `import EventSource` is
//     gated `#if !os(Linux)`, so it (wrongly) imports a missing module on
//     Windows. That's an upstream swift-sdk portability bug, not ours.
// Both deps and their consumer files are excluded so this probe compiles
// only PalmierPro's own logic against Foundation + the Swift stdlib.

import PackageDescription

let package = Package(
    name: "PalmierCore",
    products: [
        .library(name: "PalmierCore", targets: ["PalmierCore"]),
    ],
    targets: [
        .target(
            name: "PalmierCore",
            path: "Sources/PalmierCore"
        ),
    ]
)
