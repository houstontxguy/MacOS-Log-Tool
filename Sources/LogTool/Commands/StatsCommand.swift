import ArgumentParser
import Foundation
import LogToolCore

struct StatsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stats",
        abstract: "Log volume breakdown by level, subsystem, and process."
    )

    @Option(name: .long, help: "Time range (e.g., 5m, 1h, 30s, 2d).")
    var last: String = "5m"

    @Option(name: .long, help: "Filter by process name.")
    var process: String?

    @Option(name: .long, help: "Filter by subsystem.")
    var subsystem: String?

    @Option(name: .long, help: "Output format: table, json.")
    var format: String = "table"

    @Flag(name: .long, help: "Show anomaly detection results.")
    var anomalies: Bool = false

    @Flag(name: .long, help: "Show timeline visualization.")
    var timeline: Bool = false

    func run() async throws {
        guard let interval = parseTimeInterval(last) else {
            print("Invalid time range: \(last). Use formats like 5m, 1h, 30s, 2d.")
            throw ExitCode.failure
        }

        let filter = LogFilter(
            process: process,
            subsystem: subsystem,
            lastInterval: interval
        )
        let collector = LogCollector()
        let entries = try await collector.collect(filter: filter)

        guard !entries.isEmpty else {
            print("No log entries found for the given filters.")
            return
        }

        let colorFormatter = ColorFormatter()

        // Level breakdown
        var levelCounts: [LogLevel: Int] = [:]
        for entry in entries {
            levelCounts[entry.level, default: 0] += 1
        }

        print(colorFormatter.colorize("Log Statistics (last \(last))", .bold))
        print(String(repeating: "─", count: 50))
        print("Total entries: \(entries.count)")
        print("")

        print(colorFormatter.colorize("By Level:", .bold))
        for level in LogLevel.allCases {
            let count = levelCounts[level] ?? 0
            let pct = entries.isEmpty ? 0 : Double(count) / Double(entries.count) * 100
            let color = colorFormatter.color(for: level)
            let bar = String(repeating: "█", count: min(40, Int(pct / 2.5)))
            print("  \(colorFormatter.colorize(level.rawValue.uppercased().padding(toLength: 8, withPad: " ", startingAt: 0), color)) \(String(count).padding(toLength: 8, withPad: " ", startingAt: 0)) \(String(format: "%5.1f%%", pct)) \(colorFormatter.colorize(bar, color))")
        }

        // Top subsystems
        print("")
        print(colorFormatter.colorize("Top Subsystems:", .bold))
        let subsystemCounts = Dictionary(grouping: entries, by: \.subsystem)
            .mapValues(\.count)
            .sorted { $0.value > $1.value }

        for (subsystem, count) in subsystemCounts.prefix(10) {
            let name = subsystem.isEmpty ? "(none)" : subsystem
            print("  \(name.padding(toLength: 45, withPad: " ", startingAt: 0)) \(count)")
        }

        // Top processes
        print("")
        print(colorFormatter.colorize("Top Processes:", .bold))
        let processCounts = Dictionary(grouping: entries, by: \.processName)
            .mapValues(\.count)
            .sorted { $0.value > $1.value }

        for (processName, count) in processCounts.prefix(10) {
            print("  \(processName.padding(toLength: 30, withPad: " ", startingAt: 0)) \(count)")
        }

        // Timeline
        if timeline {
            print("")
            let timelineFormatter = TimelineFormatter(colorFormatter: colorFormatter)
            print(timelineFormatter.renderTimeline(entries: entries))
        }

        // Anomalies
        if anomalies {
            print("")
            let detector = AnomalyDetector()
            let detected = detector.detect(entries: entries)
            let tableFormatter = TableFormatter(colorFormatter: colorFormatter)
            print(tableFormatter.formatAnomalies(detected))
        }
    }
}
