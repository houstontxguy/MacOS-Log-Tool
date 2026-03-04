# Features Guide

## GUI Application

### Log Browser

The Log Browser provides a filterable table view of historical log entries.

**Controls:**
- **Process** — Filter by process name (combo-box with suggestions)
- **Subsystem** — Filter by subsystem (combo-box with suggestions)
- **Level** — Filter by log level (All, Debug, Info, Default, Error, Fault)
- **Time Range** — Duration string (e.g., `5m`, `1h`, `2d`)
- **Fetch** — Execute the query (Cmd+Return)

**Features:**
- Sortable Table columns: Time, Level, Process, Subsystem, Message
- Full-text search bar to filter loaded entries
- Selection-based detail pane showing all entry metadata
- Entry count in toolbar

### Live Stream

Real-time log streaming with play/stop controls.

**Controls:**
- **Start/Stop** — Toggle streaming (filters locked while streaming)
- **Process/Subsystem/Level** — Pre-stream filters
- **Auto-scroll** — Toggle automatic scroll-to-bottom
- **Clear** — Remove all buffered entries

**Features:**
- Circular buffer (5,000 entry max) prevents memory growth
- Live entry count display
- Entries render as they arrive via AsyncThrowingStream

### Dashboard

Visual statistics dashboard using Swift Charts.

**Displays:**
- Bar chart of log level distribution
- Top 10 subsystems by entry count
- Top 10 processes by entry count
- Detected anomalies with severity indicators
- Total entry count

### Subsystem Discovery

Multi-level subsystem browser with drill-down navigation.

**Level 0 — Subsystem List:**
- All active subsystems with total counts
- Clickable error badges jump directly to error entries
- Expandable disclosure groups showing categories, levels, and processes

**Level 1 — Subsystem Detail (click subsystem):**
- All log entries for the subsystem in a table
- Detail pane on entry selection

**Level 2 — Filtered View (click category/process/error badge):**
- Filtered entries matching the specific category, process, or error level
- Back button via NavigationStack

### Crash Reports

Browse, inspect, and analyze macOS crash reports.

**Features:**
- Lists all .ips crash reports from DiagnosticReports directories
- Split view: crash list + detail pane
- Crash detail shows: exception type, termination reason, faulting thread stack
- **Correlate Logs** — Fetches log entries within ±5 minutes of the crash
- **AI Analysis** — AI-powered crash report analysis with correlated logs

### Capture & Analyze

One-click log capture with comprehensive analysis.

**Workflow:**
1. Set time range (minutes stepper) and optional filters
2. Click **Capture Logs** (Cmd+Return)
3. View results:
   - Summary cards (total, errors, subsystems, processes)
   - Level distribution chart
   - Top 5 subsystems and processes
   - Anomaly detection results
4. **Export** captured logs as JSON, CSV, or NDJSON
5. **AI Analysis** with optional context prompt

### AI Analysis

Dedicated AI analysis view with two modes.

**Natural Language Query:**
- Describe what you're looking for in plain English
- Generates an NSPredicate and executes it
- Displays matching log entries

**Log Analysis:**
- Filter by process and time range
- Provide optional context for the analysis
- AI analyzes the logs and provides insights
- Token usage tracking

### Health Check

Automated system health scanner.

See [Health Scanner](health-scanner.md) for details.

### Quick Diagnostics

12 pre-built diagnostic presets accessible from the sidebar.

See [Diagnostic Presets](diagnostic-presets.md) for details.

### Settings

Application configuration with four tabs:

- **General** — Default time range, max entries
- **AI** — Provider selection (Claude/OpenAI/Ollama), model configuration
- **API Keys** — Secure API key storage via macOS Keychain
- **About** — App information

---

## CLI Tool

### export

Export filtered logs to stdout or file.

```bash
logtool export [--process <name>] [--subsystem <name>] [--level <level>]
               [--last <duration>] [--format json|csv|ndjson]
               [--max-entries <n>] [--output <file>]
```

### stream

Stream logs in real-time.

```bash
logtool stream [--process <name>] [--subsystem <name>] [--level <level>]
```

### stats

Display log statistics.

```bash
logtool stats [--last <duration>] [--process <name>]
```

### discover

Discover active subsystems.

```bash
logtool discover [--last <duration>]
```

### crash

Crash report operations.

```bash
logtool crash list [--since <date>]
logtool crash show <path>
logtool crash correlate <path> [--window <minutes>]
logtool crash analyze <path>
```

### query

Query logs with NSPredicate.

```bash
logtool query <predicate> [--last <duration>]
```

### analyze

AI-powered log analysis.

```bash
logtool analyze [--last <duration>] [--process <name>]
                [--context <description>]
```

### config

Manage configuration.

```bash
logtool config get <key>
logtool config set <key> <value>
logtool config list
logtool config remove <key>
```
