import ArgumentParser
import Foundation
import LogToolCore

struct AnalyzeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "analyze",
        abstract: "AI-powered log analysis for root cause identification."
    )

    @Option(name: .long, help: "Filter by process name.")
    var process: String?

    @Option(name: .long, help: "Filter by subsystem.")
    var subsystem: String?

    @Option(name: .long, help: "Time range (e.g., 5m, 1h, 30s, 2d).")
    var last: String = "5m"

    @Option(name: .long, help: "Minimum log level (debug, info, default, error, fault).")
    var level: String?

    @Option(name: .long, help: "Custom NSPredicate filter.")
    var predicate: String?

    @Option(name: .long, help: "Additional context for the AI analysis.")
    var context: String?

    @Option(name: .long, help: "Maximum log entries to include in analysis.")
    var maxEntries: Int = 500

    func run() async throws {
        guard let interval = parseTimeInterval(last) else {
            print("Invalid time range: \(last). Use formats like 5m, 1h, 30s, 2d.")
            throw ExitCode.failure
        }

        let colorFormatter = ColorFormatter()

        // Collect logs
        var logLevel: LogLevel?
        if let level {
            logLevel = LogLevel(rawValue: level.lowercased())
        }

        let filter = LogFilter(
            process: process,
            subsystem: subsystem,
            level: logLevel,
            lastInterval: interval,
            predicate: predicate
        )

        print(colorFormatter.colorize("Collecting logs...", .dim))
        let collector = LogCollector()
        let entries = try await collector.collect(filter: filter, maxEntries: maxEntries)

        guard !entries.isEmpty else {
            print("No log entries found for the given filters.")
            return
        }

        print(colorFormatter.colorize("Collected \(entries.count) entries. Analyzing...", .dim))

        // Local anomaly detection first
        let detector = AnomalyDetector()
        let anomalies = detector.detect(entries: entries)

        if !anomalies.isEmpty {
            let tableFormatter = TableFormatter(colorFormatter: colorFormatter)
            print("")
            print(tableFormatter.formatAnomalies(anomalies))
        }

        // AI analysis
        let provider: AIProvider
        do {
            provider = try AIProviderFactory.create()
        } catch {
            print("")
            print(colorFormatter.colorize("AI analysis unavailable: \(error.localizedDescription)", .yellow))
            print("Statistical analysis above is available without AI configuration.")
            return
        }

        let prompts = PromptTemplates()
        var analysisContext = context ?? ""
        if !anomalies.isEmpty {
            analysisContext += "\n\nStatistical anomalies detected: "
            analysisContext += anomalies.map(\.description).joined(separator: "; ")
        }

        let messages = [
            AIMessage(role: .system, content: PromptTemplates.logAnalysisSystem),
            AIMessage(role: .user, content: prompts.buildAnalysisPrompt(
                entries: entries,
                context: analysisContext.isEmpty ? nil : analysisContext
            )),
        ]

        print("")
        let response = try await provider.complete(messages: messages)
        print(response.content)

        if let usage = response.usage {
            print("")
            print(colorFormatter.colorize("Tokens: \(usage.inputTokens) in, \(usage.outputTokens) out", .dim))
        }
    }
}
