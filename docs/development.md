# Development Guide

## Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15+ with Swift 5.9+
- Full Disk Access for your terminal (System Settings > Privacy & Security > Full Disk Access)

## Building

```bash
# Debug build
swift build

# Release build
swift build -c release

# Run the GUI app
swift run LogToolApp

# Run the CLI
swift run logtool --help
```

## Testing

```bash
# Run all tests
swift test

# Run specific test
swift test --filter LogToolCoreTests
```

Tests are located in `Tests/LogToolCoreTests/` and use fixture data from `Tests/LogToolCoreTests/Fixtures/`.

## Project Structure

```
MacOS-Log-Tool/
├── Package.swift                 # SPM manifest
├── README.md
├── LICENSE
├── docs/                         # Documentation
├── Sources/
│   ├── LogTool/                  # CLI target
│   ├── LogToolApp/               # GUI target
│   └── LogToolCore/              # Shared library
└── Tests/
    └── LogToolCoreTests/         # Unit tests
```

## Targets

| Target | Type | Dependencies |
|--------|------|-------------|
| `LogTool` | Executable | LogToolCore, ArgumentParser |
| `LogToolApp` | Executable | LogToolCore |
| `LogToolCore` | Library | GRDB |
| `LogToolCoreTests` | Test | LogToolCore |

## Conventions

### Code Style

- MVVM architecture for SwiftUI views
- `@Observable` macro for view models (not ObservableObject)
- `@State private var viewModel = ...` for view-owned state
- `@Environment` for shared services
- `Sendable` conformance on all core types
- Async/await for all asynchronous operations
- `Task { @MainActor in ... }` for UI updates in view models

### File Organization

- One view per file, one view model per file
- Components in `Views/Components/`
- Reusable services in `Services/`
- Models in `Models/`
- View model naming: `FooView.swift` + `FooViewModel.swift`

### Error Handling

- View models expose `errorMessage: String?` for UI display
- Core services throw typed errors
- AI providers use `AIProviderError` enum
- Keychain operations use `KeychainError` enum

### Naming

- View models: `FooViewModel`
- Views: `FooView`
- Services: `FooService` or descriptive name (`LogCollector`, `AnomalyDetector`)
- Models: Descriptive name (`LogEntry`, `CrashReport`, `DiagnosticPreset`)

## Adding a New Feature

### New View

1. Create `Views/NewFeatureView.swift`
2. Create `ViewModels/NewFeatureViewModel.swift`
3. Add case to `SidebarItem` enum in `Sidebar.swift`
4. Add routing in `ContentView.swift`

### New Diagnostic Preset

Add to the `allPresets` array in `Sources/LogToolApp/Models/DiagnosticPreset.swift`:

```swift
static let myPreset = DiagnosticPreset(
    id: "my_preset",
    name: "My Preset",
    icon: "sf.symbol.name",
    subsystems: ["com.apple.something"],
    processes: ["processName"],
    keywords: [],
    defaultLevel: nil
)
```

### New CLI Command

1. Create `Sources/LogTool/Commands/NewCommand.swift`
2. Register in `LogTool.swift`'s subcommands list

### New AI Provider

1. Create `Sources/LogToolCore/AI/NewProvider.swift` implementing `AIProvider`
2. Add case to `AIProviderFactory.create()`
3. Add configuration keys to `Configuration.swift`

## Debugging Tips

- SourceKit may show "No such module" errors — `swift build` is the source of truth
- If log commands return no data, ensure Full Disk Access is granted
- Use `--level debug` cautiously — can return extremely large result sets
- Ollama must be running locally before selecting it as a provider
- API keys are in Keychain — use Keychain Access.app to inspect if needed

## Configuration Files

| File | Location | Purpose |
|------|----------|---------|
| Config | `~/.logtool/config.json` | App configuration |
| Database | `~/.logtool/store.db` | FTS5 log storage |
| Predicates | `~/.logtool/predicates.json` | Saved predicates |
| API Keys | macOS Keychain | Encrypted API keys |
