import ArgumentParser
import Foundation
import LogToolCore

struct ExportCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export",
        abstract: "Export logs filtered by process, subsystem, time range, and level."
    )

    @Option(name: .long, help: "Filter by process name.")
    var process: String?

    @Option(name: .long, help: "Filter by subsystem (e.g., com.apple.bluetooth).")
    var subsystem: String?

    @Option(name: .long, help: "Filter by category.")
    var category: String?

    @Option(name: .long, help: "Minimum log level (debug, info, default, error, fault).")
    var level: String?

    @Option(name: .long, help: "Filter messages containing this text.")
    var messageContains: String?

    @Option(name: .long, help: "Time range (e.g., 5m, 1h, 30s, 2d).")
    var last: String?

    @Option(name: .long, help: "Custom NSPredicate filter.")
    var predicate: String?

    @Option(name: .long, help: "Output format: table, json, csv, ndjson.")
    var format: String = "table"

    @Option(name: .long, help: "Maximum number of entries to return.")
    var maxEntries: Int?

    func run() async throws {
        let filter = buildFilter()
        let collector = LogCollector()
        let entries = try await collector.collect(filter: filter, maxEntries: maxEntries)

        switch format.lowercased() {
        case "json":
            let formatter = JSONOutputFormatter()
            print(formatter.formatEntries(entries))
        case "csv":
            let formatter = JSONOutputFormatter()
            print(formatter.formatEntriesCSV(entries))
        case "ndjson":
            let formatter = JSONOutputFormatter(prettyPrint: false)
            print(formatter.formatEntriesNDJSON(entries))
        default:
            let formatter = TableFormatter()
            print(formatter.formatEntries(entries))
        }
    }

    private func buildFilter() -> LogFilter {
        var logLevel: LogLevel?
        if let level {
            logLevel = LogLevel(rawValue: level.lowercased())
        }

        var interval: TimeInterval?
        if let last {
            interval = parseTimeInterval(last)
        }

        return LogFilter(
            process: process,
            subsystem: subsystem,
            category: category,
            level: logLevel,
            messageContains: messageContains,
            lastInterval: interval,
            predicate: predicate
        )
    }
}
