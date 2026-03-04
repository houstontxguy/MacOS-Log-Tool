# Architecture

## Overview

macOS Log Tool is structured as a Swift Package Manager monorepo with three targets that share a common core library.

## Target Layout

```
MacOSLogTool (Package)
├── LogTool          — CLI executable (swift-argument-parser)
├── LogToolApp       — SwiftUI GUI executable
└── LogToolCore      — Shared library (all business logic)
```

### LogToolCore (Library)

The core library contains all business logic, models, and services. It has no UI dependencies and is fully testable.

```
Sources/LogToolCore/
├── Models/
│   ├── LogEntry.swift          # Core log entry model (ndjson schema from /usr/bin/log)
│   ├── LogFilter.swift         # Filter configuration + time range parsing
│   ├── AnalysisResult.swift    # AI analysis result types
│   └── CrashReport.swift       # Crash report model (.ips format)
├── Services/
│   ├── LogCollector.swift      # Wraps /usr/bin/log for collect + stream
│   ├── LogParser.swift         # NDJSON parsing into LogEntry objects
│   ├── SubsystemDiscovery.swift # Aggregates subsystem/category/process info
│   ├── AnomalyDetector.swift   # Statistical anomaly detection
│   ├── CrashReportParser.swift # .ips crash report parser
│   ├── LogStore.swift          # GRDB + FTS5 SQLite storage
│   └── PredicateBuilder.swift  # Builds NSPredicate strings from LogFilter
├── AI/
│   ├── AIProvider.swift        # Protocol + factory + error types
│   ├── ClaudeProvider.swift    # Anthropic Claude API implementation
│   ├── OpenAIProvider.swift    # OpenAI API implementation
│   ├── OllamaProvider.swift    # Local Ollama API implementation
│   └── PromptTemplates.swift   # System prompts and prompt builders
├── Formatters/
│   └── JSONOutputFormatter.swift # JSON, CSV, NDJSON output formatting
└── Utilities/
    ├── Configuration.swift     # ~/.logtool/ config management
    ├── KeychainHelper.swift    # macOS Keychain storage for API keys
    └── ShellRunner.swift       # Subprocess execution + streaming
```

### LogToolApp (SwiftUI GUI)

The GUI follows the MVVM pattern using Swift's `@Observable` macro (macOS 14+).

```
Sources/LogToolApp/
├── LogToolApp.swift            # @main App entry point
├── ContentView.swift           # NavigationSplitView root + routing
├── Models/
│   └── DiagnosticPreset.swift  # 12 curated diagnostic presets
├── Views/
│   ├── Sidebar.swift           # Sidebar with views + diagnostics sections
│   ├── LogBrowserView.swift    # Historical log browser with Table
│   ├── StreamView.swift        # Real-time log streaming
│   ├── StatsView.swift         # Dashboard with Charts
│   ├── DiscoverView.swift      # Subsystem browser with drill-down
│   ├── CrashView.swift         # Crash report browser
│   ├── CaptureAnalyzeView.swift # One-click capture + analysis
│   ├── AnalysisView.swift      # AI analysis (NL query + log analysis)
│   ├── DiagnosticResultView.swift # Diagnostic preset results
│   ├── HealthCheckView.swift   # System health scanner
│   ├── SettingsView.swift      # App settings
│   └── Components/
│       ├── FilterBar.swift         # Reusable filter controls
│       ├── SuggestionTextField.swift # NSComboBox wrapper
│       ├── LogEntryRow.swift       # Single log entry display
│       ├── LogDetailView.swift     # Log entry detail pane
│       ├── LevelBadge.swift        # Colored level badge
│       └── CrashDetailView.swift   # Crash report detail
├── ViewModels/
│   ├── LogBrowserViewModel.swift
│   ├── StreamViewModel.swift
│   ├── StatsViewModel.swift
│   ├── DiscoverViewModel.swift
│   ├── CrashViewModel.swift
│   ├── CaptureAnalyzeViewModel.swift
│   ├── AnalysisViewModel.swift
│   ├── DiagnosticViewModel.swift
│   ├── HealthCheckViewModel.swift
│   └── SettingsViewModel.swift
├── Services/
│   └── ActiveSubsystemPoller.swift # Background subsystem polling
└── Utilities/
    └── LogLevelColor.swift     # LogLevel -> SwiftUI Color mapping
```

### LogTool (CLI)

The CLI uses swift-argument-parser to expose the same LogToolCore services via command-line subcommands.

```
Sources/LogTool/
├── LogTool.swift               # @main AsyncParsableCommand
└── Commands/
    ├── ExportCommand.swift
    ├── StreamCommand.swift
    ├── StatsCommand.swift
    ├── DiscoverCommand.swift
    ├── CrashCommand.swift
    ├── QueryCommand.swift
    ├── AnalyzeCommand.swift
    └── ConfigCommand.swift
```

## Design Patterns

### MVVM with @Observable

Each view has a corresponding `@Observable` view model:

```swift
@Observable
final class LogBrowserViewModel {
    var entries: [LogEntry] = []
    var isLoading = false
    // ... published state

    private let collector = LogCollector()

    func fetch() {
        Task { @MainActor in
            // async work, update state
        }
    }
}
```

Views use `@State` to own their view model:

```swift
struct LogBrowserView: View {
    @State private var viewModel = LogBrowserViewModel()
    // ...
}
```

### Environment Injection

Shared services like `ActiveSubsystemPoller` are injected via SwiftUI's environment:

```swift
// ContentView creates and injects
@State private var poller = ActiveSubsystemPoller()
// ...
.environment(poller)

// Child views consume optionally
@Environment(ActiveSubsystemPoller.self) private var poller: ActiveSubsystemPoller?
```

### Sidebar Routing

Navigation uses a discriminated enum:

```swift
enum SidebarSelection: Hashable {
    case view(SidebarItem)       // Built-in views
    case diagnostic(String)      // Diagnostic preset by ID
}
```

ContentView routes selection to the appropriate view.

### NavigationStack for Drill-Down

The Subsystem Discovery view uses `NavigationStack` with a typed path:

```swift
enum DrillDownLevel: Hashable {
    case subsystem(String)
    case category(subsystem: String, category: String)
    case process(subsystem: String, process: String)
    case errors(subsystem: String)
}
```

## Dependencies

| Dependency | Version | Used By | Purpose |
|-----------|---------|---------|---------|
| swift-argument-parser | 1.3+ | LogTool | CLI argument parsing |
| GRDB.swift | 6.24+ | LogToolCore | SQLite + FTS5 log storage |

## Platform Requirements

- **macOS 14+** (Sonoma) — required for `@Observable`, modern SwiftUI APIs
- **Swift 5.9+** — required for macros, modern concurrency
