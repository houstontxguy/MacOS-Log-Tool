import Foundation

/// Collects logs from the macOS unified logging system via the `log` command.
public final class LogCollector: Sendable {
    private let shell: ShellRunner
    private let parser: LogParser
    private let predicateBuilder: PredicateBuilder

    public init(
        shell: ShellRunner = ShellRunner(),
        parser: LogParser = LogParser(),
        predicateBuilder: PredicateBuilder = PredicateBuilder()
    ) {
        self.shell = shell
        self.parser = parser
        self.predicateBuilder = predicateBuilder
    }

    /// The path to the `log` command.
    private static let logCommand = "/usr/bin/log"

    /// Collect log entries matching the given filter using `log show`.
    public func collect(filter: LogFilter, maxEntries: Int? = nil) async throws -> [LogEntry] {
        var args = ["show", "--style", "ndjson"]

        // Time range
        if let lastInterval = filter.lastInterval {
            args += ["--last", formatDuration(lastInterval)]
        } else {
            if let start = filter.startTime {
                args += ["--start", Self.formatDate(start)]
            }
            if let end = filter.endTime {
                args += ["--end", Self.formatDate(end)]
            }
        }

        // Info and debug level messages need explicit flags
        if let level = filter.level {
            switch level {
            case .debug:
                args += ["--debug", "--info"]
            case .info:
                args += ["--info"]
            default:
                break
            }
        }

        // Predicate filter
        let predArgs = predicateBuilder.buildArguments(from: filter)
        args += predArgs

        let result = try await shell.run(Self.logCommand, arguments: args, timeout: 120)

        guard result.succeeded else {
            throw LogCollectorError.commandFailed(result.stderr)
        }

        var entries = parser.parseNDJSON(result.stdout)

        if let maxEntries, entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }

        return entries
    }

    /// Stream log entries in real-time using `log stream`.
    public func stream(filter: LogFilter) -> AsyncThrowingStream<LogEntry, Error> {
        var args = ["stream", "--style", "ndjson"]

        if let level = filter.level {
            switch level {
            case .debug:
                args += ["--level", "debug"]
            case .info:
                args += ["--level", "info"]
            case .default:
                args += ["--level", "default"]
            case .error:
                args += ["--level", "error"]
            case .fault:
                args += ["--level", "fault"]
            }
        }

        let predArgs = predicateBuilder.buildArguments(from: filter)
        args += predArgs

        let lines = shell.stream(Self.logCommand, arguments: args)
        return parser.parseStream(lines)
    }

    /// Format a TimeInterval as a duration string for `log show --last`.
    private func formatDuration(_ interval: TimeInterval) -> String {
        if interval < 60 {
            return "\(Int(interval))s"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h"
        } else {
            return "\(Int(interval / 86400))d"
        }
    }

    /// Format a Date for `log show --start/--end`.
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}

/// Errors from log collection.
public enum LogCollectorError: Error, LocalizedError {
    case commandFailed(String)
    case parseError(String)

    public var errorDescription: String? {
        switch self {
        case .commandFailed(let msg): return "Log command failed: \(msg)"
        case .parseError(let msg): return "Failed to parse log output: \(msg)"
        }
    }
}
