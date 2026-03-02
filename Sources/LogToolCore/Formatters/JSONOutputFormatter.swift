import Foundation

/// Machine-readable JSON output formatting.
public struct JSONOutputFormatter: Sendable {
    private let encoder: JSONEncoder

    public init(prettyPrint: Bool = true) {
        self.encoder = JSONEncoder()
        if prettyPrint {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        } else {
            encoder.outputFormatting = [.sortedKeys]
        }
    }

    /// Format log entries as a JSON array.
    public func formatEntries(_ entries: [LogEntry]) -> String {
        guard let data = try? encoder.encode(entries) else {
            return "[]"
        }
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    /// Format log entries as ndjson (one JSON object per line).
    public func formatEntriesNDJSON(_ entries: [LogEntry]) -> String {
        let lineEncoder = JSONEncoder()
        lineEncoder.outputFormatting = [.sortedKeys]
        return entries.compactMap { entry in
            guard let data = try? lineEncoder.encode(entry) else { return nil }
            return String(data: data, encoding: .utf8)
        }.joined(separator: "\n")
    }

    /// Format a single log entry as JSON.
    public func formatEntry(_ entry: LogEntry) -> String {
        guard let data = try? encoder.encode(entry) else {
            return "{}"
        }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    /// Format subsystem info as JSON.
    public func formatSubsystems(_ subsystems: [SubsystemInfo]) -> String {
        let dicts: [[String: Any]] = subsystems.map { info in
            [
                "subsystem": info.subsystem,
                "totalCount": info.totalCount,
                "errorCount": info.errorCount,
                "categories": info.categories.map { ["name": $0.name, "count": $0.count] },
                "processes": info.processes,
            ]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: dicts, options: [.prettyPrinted, .sortedKeys]) else {
            return "[]"
        }
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    /// Format log entries as CSV.
    public func formatEntriesCSV(_ entries: [LogEntry]) -> String {
        var lines: [String] = []
        lines.append("timestamp,level,process,pid,subsystem,category,message")
        for entry in entries {
            let message = entry.eventMessage
                .replacingOccurrences(of: "\"", with: "\"\"")
            lines.append("\"\(entry.timestamp)\",\"\(entry.level.rawValue)\",\"\(entry.processName)\",\(entry.processID),\"\(entry.subsystem)\",\"\(entry.category)\",\"\(message)\"")
        }
        return lines.joined(separator: "\n")
    }
}
