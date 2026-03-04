# AI Integration

macOS Log Tool supports optional AI-powered log analysis through a pluggable provider system. AI features are available in both the GUI app and CLI tool. **AI is completely optional** — all other features work without it.

## Quick Setup

### GUI App

1. Open **Settings** (Cmd+,)
2. Go to the **AI** tab → select a provider → click **Save**
3. Go to the **API Keys** tab → enter your key → click **Save Key**

### CLI

```bash
logtool config set ai-provider claude   # or: openai, ollama
# API keys are managed in the GUI Settings > API Keys tab
```

## Supported Providers

### Claude (Anthropic) — Recommended

Best analysis quality with the largest context window. Ideal for analyzing large log sets.

| | |
|---|---|
| **Default model** | claude-sonnet-4-20250514 |
| **Max context** | 200,000 tokens |
| **Tool use** | Yes |
| **API** | https://api.anthropic.com/v1/messages |

**Getting an API key:**

1. Go to [console.anthropic.com](https://console.anthropic.com/)
2. Create an account (or sign in)
3. Navigate to **Settings** → **API Keys** → **Create Key**
4. Copy the key — it starts with `sk-ant-api03-...`

> **Using Claude Code CLI?** You already have an Anthropic API key. Find it with:
> ```bash
> echo $ANTHROPIC_API_KEY
> ```
> Use this same key in Log Tool.

**Pricing:** Pay-per-use. A typical log analysis (sending ~2,000 entries) costs approximately $0.01-0.05. New accounts receive $5 in free credits. See [anthropic.com/pricing](https://www.anthropic.com/pricing#702702).

**Custom model:**
```bash
logtool config set claude-model claude-sonnet-4-20250514
```

### OpenAI (GPT-4o)

Strong general-purpose analysis with wide model selection.

| | |
|---|---|
| **Default model** | gpt-4o |
| **Max context** | 128,000 tokens |
| **Tool use** | Yes |
| **API** | https://api.openai.com/v1/chat/completions |

**Getting an API key:**

1. Go to [platform.openai.com](https://platform.openai.com/)
2. Create an account (or sign in)
3. Navigate to **API Keys** → **Create new secret key**
4. Copy the key — it starts with `sk-...`

**Pricing:** Pay-per-use. See [openai.com/pricing](https://openai.com/pricing).

**Custom model:**
```bash
logtool config set openai-model gpt-4o
```

### Ollama (Local / Free / Private)

Runs AI models entirely on your Mac. No API key needed, no data leaves your machine.

| | |
|---|---|
| **Default model** | llama3.1 |
| **Max context** | 32,000 tokens |
| **Tool use** | No |
| **API** | http://localhost:11434/api/chat |

**Setup:**

1. Download and install Ollama: [ollama.com/download](https://ollama.com/download)
2. Pull a model:
   ```bash
   ollama pull llama3.1        # 8B params, ~4.7GB, needs ~8GB RAM
   # or for smaller machines:
   ollama pull phi3             # 3.8B params, ~2.3GB, needs ~4GB RAM
   ollama pull mistral          # 7B params, ~4.1GB, needs ~8GB RAM
   ```
3. In Log Tool Settings → AI tab → select **Ollama** → Save

**Custom URL/model:**
```bash
logtool config set ollama-url http://localhost:11434
logtool config set ollama-model llama3.1
```

## API Keys vs Consumer Subscriptions

A **ChatGPT Plus** or **Claude Pro** subscription does **not** include API access. These are separate products:

| What you have | Works with Log Tool? | What to do |
|---|---|---|
| Anthropic API key (`sk-ant-...`) | **Yes** | Use Claude provider |
| Claude Code CLI key (`ANTHROPIC_API_KEY`) | **Yes** | Same Anthropic API key |
| OpenAI API key (`sk-...`) | **Yes** | Use OpenAI provider |
| Claude Pro/Team sub (claude.ai login) | **No** | Get API key at [console.anthropic.com](https://console.anthropic.com/) — free $5 credit for new accounts |
| ChatGPT Plus sub (chatgpt.com login) | **No** | Get API key at [platform.openai.com](https://platform.openai.com/) — pay-per-use |
| Ollama installed locally | **Yes** | Free, no key needed |

This is a limitation of how Anthropic and OpenAI structure their products — consumer chat subscriptions and API access are separate billing systems. There is no way to authenticate with a username/password from a chat subscription.

**Cheapest options:**
- **Free:** Use Ollama (runs locally, no account needed)
- **Almost free:** Anthropic API (new accounts get $5 free credit, enough for hundreds of analyses)

## API Key Storage

API keys are stored securely in the **macOS Keychain** under the service identifier `com.logtool.apikeys`. Keys are:

- Encrypted at rest by the Keychain
- Accessible only when the device is unlocked
- Bound to the current device (not synced via iCloud Keychain)
- **Never written to config files** — only the provider name and model are stored in `~/.logtool/config.json`

You can manage keys in the GUI via **Settings > API Keys** tab.

## AI Features

### Log Analysis

Available in: Capture & Analyze, Diagnostic Results, AI Analysis tab

The AI receives a structured prompt containing:
- Log entries (truncated to fit context window)
- Summary statistics
- Optional user-provided context

The system prompt positions the AI as "an expert macOS system diagnostics engineer" and asks for:
- Root cause identification
- Pattern analysis
- Actionable recommendations

### Crash Analysis

Available in: Crash Reports

Sends the crash report details along with correlated log entries (±5 minute window) to the AI for analysis of:
- Exception type and cause
- Faulting thread analysis
- Contributing system conditions from logs

### Natural Language Query

Available in: AI Analysis tab

Converts natural language descriptions into NSPredicate expressions:
- Input: "Show me all Bluetooth errors from the last hour"
- Output: `subsystem == "com.apple.bluetooth" AND messageType == "Error"`
- Executes the generated predicate and displays results

### Health Check Summary

Available in: Health Check

After scanning all 12 diagnostic areas, the AI receives a summary of all findings and generates a holistic plain-English overview with prioritized recommendations.

## Prompt Templates

Prompts are defined in `Sources/LogToolCore/AI/PromptTemplates.swift`:

| Template | Purpose |
|----------|---------|
| `logAnalysisSystem` | System prompt for log analysis |
| `crashAnalysisSystem` | System prompt for crash analysis |
| `nlToPredicateSystem` | System prompt for NL-to-predicate conversion |
| `buildAnalysisPrompt()` | Formats log entries + context for analysis |
| `buildCrashAnalysisPrompt()` | Formats crash report + logs for analysis |
| `buildNLQueryPrompt()` | Formats NL query for predicate generation |

## Configuration

### GUI

Settings > AI tab:
- Select provider (None / Claude / OpenAI / Ollama)
- Configure model name
- Set Ollama URL (if using custom endpoint)

Settings > API Keys tab:
- Enter Claude API key
- Enter OpenAI API key
- See Keychain storage status

### CLI

```bash
# Set provider
logtool config set ai-provider claude

# Set custom model
logtool config set claude-model claude-sonnet-4-20250514
logtool config set openai-model gpt-4o
logtool config set ollama-model llama3.1

# Set Ollama URL
logtool config set ollama-url http://localhost:11434

# View current config
logtool config list
```

## Token Usage

AI responses include token usage information displayed in the UI:
- **Input tokens:** Tokens sent to the API (log data + prompts)
- **Output tokens:** Tokens generated by the AI (analysis response)

This helps track API costs. Log entries are automatically truncated to fit within the provider's context window.
