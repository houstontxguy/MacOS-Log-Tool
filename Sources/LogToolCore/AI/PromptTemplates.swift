import Foundation

/// Structured prompt templates for AI-powered analysis.
public struct PromptTemplates: Sendable {
    public init() {}

    /// System prompt for log analysis.
    public static let logAnalysisSystem = """
    You are an expert macOS system diagnostics engineer. You analyze unified log entries \
    to identify issues, patterns, and root causes.

    When analyzing logs:
    1. Identify error patterns and their likely causes
    2. Look for correlations between subsystems
    3. Note any timing patterns (bursts, periodic issues)
    4. Distinguish between symptoms and root causes
    5. Provide actionable recommendations

    Format your response as:
    ## Summary
    Brief overview of what you found.

    ## Findings
    Numbered list of findings, each with:
    - Title
    - Category (Root Cause / Symptom / Pattern / Anomaly / Observation)
    - Description
    - Related log entries (quote relevant messages)

    ## Recommendations
    Bulleted list of actionable recommendations.

    ## Severity
    Overall severity: Critical / Warning / Info / OK
    """

    /// Build a log analysis prompt from entries.
    public func buildAnalysisPrompt(entries: [LogEntry], context: String? = nil) -> String {
        var prompt = "Analyze the following macOS unified log entries:\n\n"

        if let context {
            prompt += "Context: \(context)\n\n"
        }

        // Summarize the log data
        let errorCount = entries.filter { $0.level >= .error }.count
        let subsystems = Set(entries.map(\.subsystem))
        let processes = Set(entries.map(\.processName))

        prompt += "Overview: \(entries.count) entries, \(errorCount) errors/faults, "
        prompt += "\(subsystems.count) subsystems, \(processes.count) processes\n\n"

        // Include entries, prioritizing errors
        let errors = entries.filter { $0.level >= .error }
        let others = entries.filter { $0.level < .error }

        prompt += "--- Error/Fault Entries ---\n"
        for entry in errors.prefix(200) {
            prompt += formatEntryForPrompt(entry)
        }

        if !others.isEmpty {
            prompt += "\n--- Other Entries (sample) ---\n"
            // Include a sample of non-error entries for context
            let sampleSize = min(100, others.count)
            let stride = max(1, others.count / sampleSize)
            for i in Swift.stride(from: 0, to: others.count, by: stride).prefix(sampleSize) {
                prompt += formatEntryForPrompt(others[i])
            }
        }

        return prompt
    }

    /// System prompt for natural language to NSPredicate translation.
    public static let nlToPredicateSystem = """
    You are a macOS log expert. Convert natural language queries into NSPredicate filter \
    strings for the macOS `log` command.

    Available predicate fields:
    - process: Process name (e.g., process == "Finder")
    - subsystem: Subsystem identifier (e.g., subsystem == "com.apple.bluetooth")
    - category: Category within subsystem
    - eventMessage: Log message text (use CONTAINS[c] for case-insensitive search)
    - messageType: Log level (0=default, 1=info, 2=debug, 16=error, 17=fault)
    - senderImagePath: Path to sending framework/library

    Operators: ==, !=, CONTAINS, CONTAINS[c], BEGINSWITH, ENDSWITH, IN, AND, OR, NOT

    Respond with ONLY the predicate string, nothing else. If you also detect a time range, \
    add it on a second line as: --last <duration> (e.g., --last 1h, --last 30m, --last 2d)

    Examples:
    Query: "bluetooth errors in the last hour"
    subsystem BEGINSWITH "com.apple.bluetooth" AND messageType IN {16, 17}
    --last 1h

    Query: "kernel panics from WindowServer"
    process == "WindowServer" AND messageType == 17

    Query: "network connection failures"
    eventMessage CONTAINS[c] "connection" AND eventMessage CONTAINS[c] "fail" AND messageType IN {16, 17}
    """

    /// Build a natural language query prompt.
    public func buildNLQueryPrompt(query: String) -> String {
        "Convert this to an NSPredicate for macOS log filtering: \"\(query)\""
    }

    /// System prompt for crash report analysis.
    public static let crashAnalysisSystem = """
    You are an expert macOS crash report analyst. You analyze .ips crash reports and \
    correlated unified log entries to determine root causes.

    When analyzing crash reports:
    1. Identify the crash type (EXC_BAD_ACCESS, EXC_CRASH, etc.) and signal
    2. Analyze the faulting thread's stack trace
    3. Look for common patterns (null dereference, use-after-free, assertion failure)
    4. Correlate with surrounding log entries for context
    5. Check if third-party code is involved

    Provide:
    - A clear explanation of what caused the crash
    - Whether it's likely a bug in the app, OS, or third-party library
    - Suggestions for reproducing or fixing the issue
    """

    /// Build a crash analysis prompt.
    public func buildCrashAnalysisPrompt(crash: CrashReport, logs: [LogEntry]) -> String {
        var prompt = "Analyze this macOS crash report:\n\n"
        prompt += "Process: \(crash.processName)\n"
        prompt += "Exception: \(crash.body.exception?.type ?? "Unknown") (\(crash.body.exception?.signal ?? "?"))\n"

        if let termination = crash.body.termination {
            prompt += "Termination: \(termination.namespace ?? "?") code \(termination.code ?? 0)\n"
        }

        if let faultingThread = crash.body.faultingThread,
           let threads = crash.body.threads,
           faultingThread < threads.count {
            let thread = threads[faultingThread]
            prompt += "\nFaulting Thread \(faultingThread)"
            if let queue = thread.queue { prompt += " (\(queue))" }
            prompt += ":\n"
            if let frames = thread.frames {
                for (idx, frame) in frames.prefix(20).enumerated() {
                    let symbol = frame.symbol ?? "???"
                    prompt += "  \(idx): \(symbol)"
                    if let offset = frame.symbolLocation { prompt += " + \(offset)" }
                    prompt += "\n"
                }
            }
        }

        if !logs.isEmpty {
            prompt += "\n--- Correlated Log Entries (around crash time) ---\n"
            for entry in logs.prefix(100) {
                prompt += formatEntryForPrompt(entry)
            }
        }

        return prompt
    }

    private func formatEntryForPrompt(_ entry: LogEntry) -> String {
        let ts = String(entry.timestamp.suffix(15))
        return "[\(ts)] [\(entry.level.rawValue.uppercased())] \(entry.processName) " +
            "(\(entry.subsystem):\(entry.category)) \(entry.eventMessage)\n"
    }
}
