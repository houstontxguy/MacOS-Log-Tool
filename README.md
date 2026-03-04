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

### From Release (Recommended)

1. Download **LogTool-v1.0.0.dmg** from [Releases](../../releases)
2. Open the DMG and drag **Log Tool.app** to Applications
3. Optionally copy `logtool` CLI binary to `/usr/local/bin`

The DMG is code-signed and notarized by Apple — no Gatekeeper warnings.

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

AI features are **optional** — the app works fully without them. When configured, AI powers log analysis, crash diagnosis, natural language queries, and health check summaries.

### Option 1: Claude (Anthropic) — Recommended

Best analysis quality with 200K token context window.

1. Go to [console.anthropic.com](https://console.anthropic.com/) and create an account
2. Navigate to **API Keys** → **Create Key**
3. Copy the key (starts with `sk-ant-...`)
4. In Log Tool: **Settings** (Cmd+,) → **AI** tab → select **Claude** → **Save**
5. Go to **API Keys** tab → paste your key → **Save Key**

> **Already using Claude Code CLI?** You can use the same Anthropic API key. Find it with `echo $ANTHROPIC_API_KEY` in your terminal, or check your Claude Code settings.

**Cost:** Pay-per-use based on tokens. A typical log analysis costs ~$0.01-0.05. See [Anthropic pricing](https://www.anthropic.com/pricing#702702).

### Option 2: OpenAI (GPT-4o)

1. Go to [platform.openai.com](https://platform.openai.com/) and create an account
2. Navigate to **API Keys** → **Create new secret key**
3. Copy the key (starts with `sk-...`)
4. In Log Tool: **Settings** (Cmd+,) → **AI** tab → select **OpenAI** → **Save**
5. Go to **API Keys** tab → paste your key → **Save Key**

**Cost:** Pay-per-use. See [OpenAI pricing](https://openai.com/pricing).

### Option 3: Ollama (Free, Local, Private)

Runs AI models locally on your Mac — no API key, no data sent anywhere.

1. Install Ollama: [ollama.com/download](https://ollama.com/download)
2. Pull a model: `ollama pull llama3.1` (or `mistral`, `codellama`, etc.)
3. In Log Tool: **Settings** (Cmd+,) → **AI** tab → select **Ollama** → **Save**

> **Note:** Requires ~8GB RAM for llama3.1. Smaller models like `phi3` work on less.

### Important: API Keys vs Consumer Subscriptions

A **ChatGPT Plus** or **Claude Pro** subscription does **not** include API access. API keys are separate:

| What you have | Can you use it? |
|---|---|
| Anthropic API key (`sk-ant-...`) | Yes — use Claude provider |
| Claude Code CLI key (`ANTHROPIC_API_KEY`) | Yes — same key, use Claude provider |
| OpenAI API key (`sk-...`) | Yes — use OpenAI provider |
| Claude Pro/Team subscription (claude.ai) | No — no API key included. Sign up at [console.anthropic.com](https://console.anthropic.com/) for API access (free tier available with $5 credit) |
| ChatGPT Plus subscription (chatgpt.com) | No — no API key included. Sign up at [platform.openai.com](https://platform.openai.com/) for API access (pay-per-use) |
| Ollama installed locally | Yes — free, no key needed |

API keys are stored securely in the macOS Keychain (encrypted, never written to disk).

See [AI Integration docs](docs/ai-integration.md) for full details on models, prompt templates, and token usage.

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
