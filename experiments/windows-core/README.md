# Windows Core — feasibility experiment

**Not a port. A measurement.**

PalmierPro is a native macOS app (`platforms: [.macOS(.v26)]`): the UI is
SwiftUI + AppKit, the media pipeline is AVFoundation, and 5 of its 9
dependencies (Sparkle, sentry-cocoa, clerk-ios, lottie-ios, DSWaveformImage)
are Apple-only. A literal Windows build is not feasible without a near-total
rewrite of the UI and media layers.

This experiment asks a narrower, useful question: **how much of the non-UI
logic is already platform-portable?**

## What's here

`Sources/PalmierCore/` contains the 61 source files (of 216) that import only
Foundation + Observation — the candidate cross-platform core (~9k LOC):
agent logic, editor view-models, generation catalog/submission, search,
transcription, models, utilities. **No third-party dependencies** — compiled
against Foundation + the Swift stdlib only, so a green build means the logic
itself is portable.

Excluded from the macOS app's 71 import-clean files:
- `Generation/Edit/EditAction.swift` — references `AVAsset`
- `Agent/Clients/PalmierClient.swift` — imports `ClerkKit` (Apple-only)
- `Search/Models/TextTokenizer.swift` — imports `Tokenizers`; its transitive C
  dep `yyjson` tripped a Swift 6.0.x Windows toolchain bug (cyclic `ucrt`).
- `Agent/MCP/MCPService.swift`, `Agent/Tools/ToolDefinitions.swift`,
  `Agent/Tools/ToolResult.swift` — import `MCP` (swift-sdk), which fails to
  build on Windows (`import EventSource` gated `#if !os(Linux)` → missing
  module). Upstream swift-sdk bug, not ours.
- `Generation/GenerationService.swift` — `@preconcurrency import Combine`.
  Combine is Apple-only (cross-platform substitute: OpenCombine).
- `Search/Indexing/EmbeddingStore.swift`, `Transcription/TranscriptCache.swift`
  — import `CryptoKit` (Apple-only; substitute: swift-crypto's `Crypto`).
- `Telemetry/Telemetry.swift` — imports `Sentry` (sentry-cocoa, Apple-only).

The kept files were selected by a strict rule: every `import` must be either
`Foundation` or `Observation`. Each substitute above is a one-line import swap,
not a rewrite — so the portable surface is effectively a few files larger than
the 61 built here.

Toolchain pinned to Swift 6.1.2 — 6.0.3 hit the `ucrt` cycle above.

## Running it

CI builds this on a real Windows runner — see
`.github/workflows/windows-core.yml`. Locally (Windows/Linux with Swift 6):

```bash
cd experiments/windows-core
swift build
```

## Reading the result

Files here still live in one module today, so their mutual references are
intact. Any `cannot find type … in scope` error therefore points at a symbol
defined in one of the 145 macOS-only files — i.e. a real coupling that a
Windows port would have to break out behind a platform abstraction. The error
count is the size of the refactor.

## Findings (Swift 6.1.2, windows-latest)

The probe ran in five iterations. What each one taught:

1. **Toolchain works, deps mostly don't.** Swift itself builds fine on Windows.
   But `swift package resolve` died on Swift 6.0.3 (cyclic `ucrt` module while
   compiling `yyjson`'s manifest — a Tokenizers transitive dep; fixed by 6.1.2).
   `MCP` (swift-sdk) then failed to compile: `import EventSource` is gated
   `#if !os(Linux)`, so Windows wrongly imports a missing module. Net: of the 9
   dependencies, 5 are Apple-only by construction and at least 1 more
   (swift-sdk) has a live Windows portability bug.

2. **The "import-clean" subset is not a separable core.** Stripping every
   third-party dep and keeping only the 61 files whose imports are
   `Foundation`/`Observation`, the build reaches type-checking and produces
   **~16,800 errors** — **8,022** of them `cannot find type … in scope`.

3. **The coupling is concentrated but structural.** Those 8,022 errors come
   from just **28 distinct types**, dominated by two: `EditorViewModel` (2,738
   refs) and `MediaAsset` (2,142). And the core data model itself is fused to
   Apple frameworks — `MediaAsset` is declared in a file that
   `import`s AppKit **and** AVFoundation; `EditorViewModel` imports AppKit;
   `TextStyle` imports AppKit + SwiftUI. There is no Apple-free domain layer to
   lift out: the model types carry `NSImage`/`AVAsset`/`NSColor` directly.

4. **Minor, mechanical gaps too.** ~136 errors are `URLSession`/
   `URLSessionDownloadTask` needing `import FoundationNetworking` off Apple
   platforms — a one-line platform shim, not a redesign.

### Verdict

A clean cross-platform core **does not exist today**. Making one means first
abstracting ~28 types — above all `MediaAsset` and `EditorViewModel` — behind
platform-neutral protocols, then re-homing their AppKit/AVFoundation guts
behind `#if canImport(AppKit)`. That is real porting work, not a build-config
change, and it touches the structural center of the app. This experiment's
value is the number on it: the Windows port is gated on decoupling a
**bounded but central** set of types, not on a long tail.
