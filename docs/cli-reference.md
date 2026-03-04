# CLI Reference

The `logtool` CLI provides command-line access to all log analysis features.

## Usage

```bash
swift run logtool <command> [options]
```

Or after building:
```bash
.build/release/logtool <command> [options]
```

## Global Options

| Option | Description |
|--------|-------------|
| `--help` | Show help information |
| `--version` | Show version (0.1.0) |

## Commands

### export

Export filtered log entries.

```bash
logtool export [options]
```

| Option | Description | Default |
|--------|-------------|---------|
| `--process <name>` | Filter by process name | — |
| `--subsystem <name>` | Filter by subsystem | — |
| `--category <name>` | Filter by category | — |
| `--level <level>` | Minimum log level | — |
| `--last <duration>` | Time range (e.g., `5m`, `1h`, `2d`) | `5m` |
| `--format <format>` | Output format: `json`, `csv`, `ndjson` | `json` |
| `--max-entries <n>` | Maximum entries to return | — |
| `--output <file>` | Output file path (stdout if omitted) | — |
| `--message <text>` | Filter by message content | — |
| `--predicate <expr>` | Raw NSPredicate expression | — |

**Examples:**
```bash
# Last 5 minutes of error-level logs
logtool export --level error --last 5m

# Safari logs in CSV format
logtool export --process Safari --last 1h --format csv --output safari.csv

# Custom predicate
logtool export --predicate 'subsystem == "com.apple.bluetooth"' --last 10m
```

### stream

Stream log entries in real-time.

```bash
logtool stream [options]
```

| Option | Description |
|--------|-------------|
| `--process <name>` | Filter by process name |
| `--subsystem <name>` | Filter by subsystem |
| `--level <level>` | Minimum log level |
| `--format <format>` | Output format |

**Examples:**
```bash
# Stream all error logs
logtool stream --level error

# Stream specific process
logtool stream --process WindowServer
```

Press Ctrl+C to stop streaming.

### stats

Display log statistics.

```bash
logtool stats [options]
```

| Option | Description | Default |
|--------|-------------|---------|
| `--last <duration>` | Time range | `5m` |
| `--process <name>` | Filter by process | — |

**Output includes:**
- Log level distribution
- Top subsystems by entry count
- Top processes by entry count
- Detected anomalies

### discover

Discover active subsystems.

```bash
logtool discover [options]
```

| Option | Description | Default |
|--------|-------------|---------|
| `--last <duration>` | Time range to scan | `5m` |

**Output includes:**
- Subsystem name
- Total entry count
- Categories with counts
- Log level breakdown
- Processes using the subsystem
- Error count

### crash

Crash report operations with subcommands.

#### crash list

```bash
logtool crash list [--since <date>]
```

Lists all crash reports from `~/Library/Logs/DiagnosticReports` and `/Library/Logs/DiagnosticReports`.

#### crash show

```bash
logtool crash show <path>
```

Display parsed crash report details.

#### crash correlate

```bash
logtool crash correlate <path> [--window <minutes>]
```

Fetch log entries around the crash time (default ±5 minute window).

#### crash analyze

```bash
logtool crash analyze <path>
```

AI-powered crash analysis (requires configured AI provider).

### query

Query logs with NSPredicate expressions.

```bash
logtool query <predicate> [--last <duration>]
```

**Examples:**
```bash
# Bluetooth errors
logtool query 'subsystem == "com.apple.bluetooth" AND messageType == "Error"'

# Process with message content
logtool query 'process == "Safari" AND eventMessage CONTAINS "timeout"' --last 1h
```

### analyze

AI-powered log analysis.

```bash
logtool analyze [options]
```

| Option | Description | Default |
|--------|-------------|---------|
| `--last <duration>` | Time range | `5m` |
| `--process <name>` | Filter by process | — |
| `--subsystem <name>` | Filter by subsystem | — |
| `--context <text>` | Context for analysis | — |

**Example:**
```bash
logtool analyze --last 15m --context "Mac is running slow after update"
```

### config

Manage configuration stored in `~/.logtool/config.json`.

#### config get

```bash
logtool config get <key>
```

#### config set

```bash
logtool config set <key> <value>
```

#### config list

```bash
logtool config list
```

#### config remove

```bash
logtool config remove <key>
```

**Common keys:**

| Key | Values | Description |
|-----|--------|-------------|
| `ai-provider` | `claude`, `openai`, `ollama` | AI provider to use |
| `claude-model` | Model ID | Claude model name |
| `openai-model` | Model ID | OpenAI model name |
| `ollama-model` | Model name | Ollama model name |
| `ollama-url` | URL | Ollama API endpoint |
| `default-format` | `json`, `csv`, `ndjson` | Default export format |
| `default-time-range` | Duration string | Default time range |

## Time Duration Format

All duration strings use this format:

| Suffix | Unit | Example |
|--------|------|---------|
| `s` | Seconds | `30s` |
| `m` | Minutes | `5m` |
| `h` | Hours | `1h` |
| `d` | Days | `2d` |
| `w` | Weeks | `1w` |

## Log Levels

From least to most severe:

1. `debug` — Detailed debugging information
2. `info` — Informational messages
3. `default` — Default level messages
4. `error` — Error conditions
5. `fault` — Critical faults (system-level)

When filtering by level, you get entries at that level and above.
