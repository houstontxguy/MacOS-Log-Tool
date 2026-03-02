import ArgumentParser
import Foundation
import LogToolCore

struct StreamCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stream",
        abstract: "Real-time log streaming with filters and pattern highlighting."
    )

    @Option(name: .long, help: "Filter by process name.")
    var process: String?

    @Option(name: .long, help: "Filter by subsystem.")
    var subsystem: String?

    @Option(name: .long, help: "Filter by category.")
    var category: String?

    @Option(name: .long, help: "Minimum log level (debug, info, default, error, fault).")
    var level: String?

    @Option(name: .long, help: "Filter messages containing this text.")
    var messageContains: String?

    @Option(name: .long, help: "Custom NSPredicate filter.")
    var predicate: String?

    @Option(name: .long, help: "Highlight pattern (text to highlight in output).")
    var highlight: String?

    func run() async throws {
        let filter = buildFilter()
        let collector = LogCollector()
        let colorFormatter = ColorFormatter()

        print(colorFormatter.colorize("Streaming logs... (Ctrl+C to stop)", .dim))
        print("")

        let stream = collector.stream(filter: filter)
        for try await entry in stream {
            var line = colorFormatter.formatEntry(entry)

            // Highlight matching text
            if let highlight, !highlight.isEmpty {
                line = line.replacingOccurrences(
                    of: highlight,
                    with: colorFormatter.colorize(highlight, .boldYellow)
                )
            }

            print(line)
        }
    }

    private func buildFilter() -> LogFilter {
        var logLevel: LogLevel?
        if let level {
            logLevel = LogLevel(rawValue: level.lowercased())
        }

        return LogFilter(
            process: process,
            subsystem: subsystem,
            category: category,
            level: logLevel,
            messageContains: messageContains,
            predicate: predicate
        )
    }
}
