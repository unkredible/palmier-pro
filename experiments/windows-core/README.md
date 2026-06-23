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

`Sources/PalmierCore/` contains the 69 source files (of 216) that import no
Apple-only framework — the candidate cross-platform core (~10.6k LOC):
agent tools, editor view-models, generation catalog/submission, search,
transcription, models, utilities.

Excluded from the macOS app's 71 import-clean files:
- `Generation/Edit/EditAction.swift` — references `AVAsset`
- `Agent/Clients/PalmierClient.swift` — imports `ClerkKit` (Apple-only)

Dependencies kept (both cross-platform): `MCP` (swift-sdk), `Tokenizers`
(swift-transformers).

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
