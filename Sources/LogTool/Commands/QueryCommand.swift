import ArgumentParser
import Foundation
import LogToolCore

struct QueryCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "query",
        abstract: "Translate natural language to NSPredicate and execute."
    )

    @Argument(help: "Natural language query (e.g., 'bluetooth errors last hour').")
    var query: String

    @Flag(name: .long, help: "Only show the generated predicate without executing.")
    var dryRun: Bool = false

    @Option(name: .long, help: "Output format: table, json.")
    var format: String = "table"

    @Option(name: .long, help: "Maximum entries to return.")
    var maxEntries: Int = 100

    func run() async throws {
        let colorFormatter = ColorFormatter()

        print(colorFormatter.colorize("Translating query...", .dim))

        let provider = try AIProviderFactory.create()
        let prompts = PromptTemplates()

        let messages = [
            AIMessage(role: .system, content: PromptTemplates.nlToPredicateSystem),
            AIMessage(role: .user, content: prompts.buildNLQueryPrompt(query: query)),
        ]

        let response = try await provider.complete(messages: messages)
        let lines = response.content.split(separator: "\n", omittingEmptySubsequences: true)

        guard let predicateLine = lines.first else {
            print("AI could not generate a predicate for this query.")
            throw ExitCode.failure
        }

        let predicate = String(predicateLine).trimmingCharacters(in: .whitespaces)

        // Check for time range on second line
        var timeInterval: TimeInterval?
        if lines.count > 1 {
            let timeLine = String(lines[1]).trimmingCharacters(in: .whitespaces)
            if timeLine.hasPrefix("--last ") {
                let duration = String(timeLine.dropFirst("--last ".count))
                timeInterval = parseTimeInterval(duration)
            }
        }

        print("")
        print(colorFormatter.colorize("Generated predicate:", .bold))
        print(colorFormatter.colorize("  \(predicate)", .cyan))

        if let interval = timeInterval {
            let formatted = formatInterval(interval)
            print(colorFormatter.colorize("  Time range: last \(formatted)", .cyan))
        }

        if dryRun {
            return
        }

        print("")
        print(colorFormatter.colorize("Executing...", .dim))

        let filter = LogFilter(
            lastInterval: timeInterval ?? 3600, // Default 1 hour
            predicate: predicate
        )

        let collector = LogCollector()
        let entries = try await collector.collect(filter: filter, maxEntries: maxEntries)

        switch format.lowercased() {
        case "json":
            let jsonFormatter = JSONOutputFormatter()
            print(jsonFormatter.formatEntries(entries))
        default:
            let tableFormatter = TableFormatter()
            print(tableFormatter.formatEntries(entries))
        }

        if let usage = response.usage {
            print("")
            print(colorFormatter.colorize("AI tokens: \(usage.inputTokens) in, \(usage.outputTokens) out", .dim))
        }
    }

    private func formatInterval(_ interval: TimeInterval) -> String {
        if interval < 60 { return "\(Int(interval))s" }
        if interval < 3600 { return "\(Int(interval / 60))m" }
        if interval < 86400 { return "\(Int(interval / 3600))h" }
        return "\(Int(interval / 86400))d"
    }
}
