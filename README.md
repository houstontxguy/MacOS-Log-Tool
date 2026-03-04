# macOS Log Tool

A native macOS application and CLI for unified log analysis with optional AI-powered insights. Browse, stream, search, and diagnose system logs with built-in anomaly detection, crash report analysis, and 12 curated diagnostic presets for common troubleshooting scenarios.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

### GUI Application (LogToolApp)

- **Log Browser** — Filter and browse historical log entries with a sortable table and detail pane
- **Live Stream** — Real-time log streaming with auto-scroll and live filtering
- **Dashboard** — Visual statistics with Swift Charts: level breakdown, top subsystems/processes, anomaly detection
- **Subsystem Discovery** — Browse active subsystems with multi-level drill-down into categories, processes, and error entries
- **Crash Reports** — List, inspect, and AI-analyze crash reports from DiagnosticReports with log correlation
- **Capture & Analyze** — One-click log capture with summary stats, anomaly detection, export (JSON/CSV/NDJSON), and AI analysis
- **AI Analysis** — Natural language log queries and AI-powered log analysis (Claude, OpenAI, Ollama)
- **Health Check** — Automated system health scanner that checks 12 diagnostic areas and reports issues by severity
- **Quick Diagnostics** — 12 pre-built investigation presets (Wi-Fi, Bluetooth, Sleep/Wake, Network, etc.) accessible from the sidebar
- **Smart Suggestions** — Combo-box text fields with curated + dynamically discovered subsystem/process suggestions
- **Settings** — AI provider configuration, API key management via Keychain, general preferences

### CLI Tool (logtool)

- `export` — Export filtered logs to JSON, CSV, or NDJSON
- `stream` — Stream logs in real-time with filters
- `stats` — Display log level statistics and top subsystems/processes
- `discover` — Discover active subsystems and their categories
- `crash` — List, show, correlate, and analyze crash reports
- `query` — Query logs with NSPredicate expressions
- `analyze` — AI-powered log analysis with configurable providers
- `config` — Manage tool configuration

## Requirements

- macOS 14.0 (Sonoma) or later
- Swift 5.9+
- Xcode 15+ (for building)
- Full Disk Access (recommended, for complete log visibility)

## Installation

### From Release

Download the latest `LogToolApp.zip` from [Releases](../../releases), unzip, and drag to `/Applications`.

### Build from Source

```bash
# Clone the repository
git clone https://github.com/houstontxguy/MacOS-Log-Tool.git
cd MacOS-Log-Tool

# Build the GUI app
swift build

# Run the GUI app
swift run LogToolApp

# Run the CLI tool
swift run logtool --help
```

### Create App Bundle

```bash
# Build release
swift build -c release

# The executable is at:
.build/release/LogToolApp
```

## Quick Start

### GUI App

1. Launch LogToolApp
2. The **Log Browser** opens by default — set filters and click Fetch
3. Use **Quick Diagnostics** in the sidebar to investigate specific areas (Wi-Fi, Bluetooth, etc.)
4. Run a **Health Check** to scan all 12 diagnostic areas at once
5. Configure an AI provider in **Settings** (Cmd+,) for AI-powered analysis

### CLI

```bash
# View last 5 minutes of error logs
swift run logtool export --level error --last 5m

# Stream logs from a specific process
swift run logtool stream --process Safari

# Discover active subsystems
swift run logtool discover --last 10m

# AI analysis of recent logs
swift run logtool analyze --last 15m --context "investigating slowness"
```

## AI Provider Setup

The tool supports three AI providers for log analysis:

| Provider | Model | Setup |
|----------|-------|-------|
| **Claude** | claude-sonnet-4-20250514 | `logtool config set ai-provider claude` + API key in Settings |
| **OpenAI** | gpt-4o | `logtool config set ai-provider openai` + API key in Settings |
| **Ollama** | llama3.1 (local) | `logtool config set ai-provider ollama` — no API key needed |

API keys are stored securely in the macOS Keychain.

## Documentation

Comprehensive documentation is available in the [`docs/`](docs/) folder:

- [Architecture](docs/architecture.md) — Project structure, MVVM patterns, target layout
- [Features Guide](docs/features.md) — Detailed walkthrough of all GUI and CLI features
- [Diagnostic Presets](docs/diagnostic-presets.md) — All 12 built-in diagnostic presets
- [Health Scanner](docs/health-scanner.md) — System health check feature
- [AI Integration](docs/ai-integration.md) — AI provider setup, prompt templates, usage
- [CLI Reference](docs/cli-reference.md) — Complete CLI command reference
- [Development Guide](docs/development.md) — Building, testing, project conventions

## Project Structure

```
Sources/
├── LogTool/              # CLI executable (ArgumentParser)
├── LogToolApp/           # SwiftUI GUI application
│   ├── Models/           # DiagnosticPreset
│   ├── Views/            # All SwiftUI views
│   │   └── Components/   # Reusable components
│   ├── ViewModels/       # @Observable view models
│   ├── Services/         # ActiveSubsystemPoller
│   └── Utilities/        # LogLevel color extension
└── LogToolCore/          # Shared library
    ├── Models/           # LogEntry, LogFilter, CrashReport, etc.
    ├── Services/         # LogCollector, SubsystemDiscovery, AnomalyDetector
    ├── AI/               # AIProvider protocol, Claude/OpenAI/Ollama providers
    ├── Formatters/       # JSON/CSV/NDJSON output formatting
    └── Utilities/        # Configuration, KeychainHelper, ShellRunner
```

## License

MIT License — see [LICENSE](LICENSE) for details.
