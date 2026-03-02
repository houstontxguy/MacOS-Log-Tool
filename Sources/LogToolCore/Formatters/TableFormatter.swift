import Foundation

/// Formats log entries and other data as aligned CLI tables.
public struct TableFormatter: Sendable {
    private let colorFormatter: ColorFormatter

    public init(colorFormatter: ColorFormatter = ColorFormatter()) {
        self.colorFormatter = colorFormatter
    }

    /// Format log entries as a table.
    public func formatEntries(_ entries: [LogEntry], columns: [Column] = Column.defaultColumns) -> String {
        guard !entries.isEmpty else { return "No log entries found." }

        var lines: [String] = []

        // Header
        let header = columns.map { col in
            col.title.padding(toLength: col.width, withPad: " ", startingAt: 0)
        }.joined(separator: "  ")
        lines.append(colorFormatter.colorize(header, .bold))
        lines.append(String(repeating: "─", count: columns.map(\.width).reduce(0, +) + (columns.count - 1) * 2))

        // Rows
        for entry in entries {
            let row = columns.map { col in
                let value = col.extract(entry)
                return truncate(value, to: col.width)
                    .padding(toLength: col.width, withPad: " ", startingAt: 0)
            }.joined(separator: "  ")
            lines.append(row)
        }

        lines.append("\n\(entries.count) entries")
        return lines.joined(separator: "\n")
    }

    /// Format subsystem discovery results as a table.
    public func formatSubsystems(_ subsystems: [SubsystemInfo], detailed: Bool = false) -> String {
        guard !subsystems.isEmpty else { return "No subsystems found." }

        var lines: [String] = []

        let header = "Subsystem".padding(toLength: 45, withPad: " ", startingAt: 0) +
            "  " + "Count".padding(toLength: 8, withPad: " ", startingAt: 0) +
            "  " + "Errors".padding(toLength: 8, withPad: " ", startingAt: 0) +
            "  " + "Categories"
        lines.append(colorFormatter.colorize(header, .bold))
        lines.append(String(repeating: "─", count: 90))

        for info in subsystems {
            let subsystem = truncate(info.subsystem, to: 45)
                .padding(toLength: 45, withPad: " ", startingAt: 0)
            let count = String(info.totalCount).padding(toLength: 8, withPad: " ", startingAt: 0)
            let errors = info.errorCount > 0
                ? colorFormatter.colorize(String(info.errorCount).padding(toLength: 8, withPad: " ", startingAt: 0), .yellow)
                : String(info.errorCount).padding(toLength: 8, withPad: " ", startingAt: 0)
            let categories = info.categories.prefix(3).map(\.name).joined(separator: ", ")

            lines.append("\(subsystem)  \(count)  \(errors)  \(categories)")

            if detailed {
                for cat in info.categories {
                    lines.append("  └─ \(cat.name): \(cat.count)")
                }
            }
        }

        lines.append("\n\(subsystems.count) subsystems")
        return lines.joined(separator: "\n")
    }

    /// Format crash report list.
    public func formatCrashList(_ reports: [(url: URL, summary: String)]) -> String {
        guard !reports.isEmpty else { return "No crash reports found." }

        var lines: [String] = []
        let header = "#".padding(toLength: 4, withPad: " ", startingAt: 0) +
            "  " + "File".padding(toLength: 40, withPad: " ", startingAt: 0) +
            "  " + "Summary"
        lines.append(colorFormatter.colorize(header, .bold))
        lines.append(String(repeating: "─", count: 100))

        for (idx, report) in reports.enumerated() {
            let num = String(idx + 1).padding(toLength: 4, withPad: " ", startingAt: 0)
            let file = truncate(report.url.lastPathComponent, to: 40)
                .padding(toLength: 40, withPad: " ", startingAt: 0)
            lines.append("\(num)  \(file)  \(report.summary)")
        }

        lines.append("\n\(reports.count) crash reports")
        return lines.joined(separator: "\n")
    }

    /// Format anomaly detection results.
    public func formatAnomalies(_ anomalies: [Anomaly]) -> String {
        guard !anomalies.isEmpty else { return "No anomalies detected." }

        var lines: [String] = []
        lines.append(colorFormatter.colorize("Anomalies Detected", .bold))
        lines.append(String(repeating: "─", count: 80))

        for anomaly in anomalies {
            let severity = colorFormatter.severityBar(anomaly.severity)
            let type = colorFormatter.colorize(anomaly.type.rawValue, .cyan)
            lines.append("\(severity) \(type)")
            lines.append("   \(anomaly.description)")
            if !anomaly.relatedSubsystems.isEmpty {
                lines.append("   Subsystems: \(anomaly.relatedSubsystems.joined(separator: ", "))")
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    /// Format an analysis result.
    public func formatAnalysis(_ result: AnalysisResult) -> String {
        var lines: [String] = []

        let severity = colorFormatter.severityIndicator(for: result.severity)
        lines.append("\(severity) \(colorFormatter.colorize("Analysis Result", .bold)) [\(result.severity.rawValue)]")
        lines.append(String(repeating: "─", count: 60))
        lines.append("")
        lines.append(colorFormatter.colorize("Summary", .bold))
        lines.append(result.summary)
        lines.append("")

        if !result.findings.isEmpty {
            lines.append(colorFormatter.colorize("Findings", .bold))
            for (idx, finding) in result.findings.enumerated() {
                lines.append("\(idx + 1). [\(finding.category.rawValue)] \(finding.title)")
                lines.append("   \(finding.description)")
                if !finding.relatedEntries.isEmpty {
                    lines.append("   Related: \(finding.relatedEntries.joined(separator: ", "))")
                }
            }
            lines.append("")
        }

        if !result.recommendations.isEmpty {
            lines.append(colorFormatter.colorize("Recommendations", .bold))
            for rec in result.recommendations {
                lines.append("  • \(rec)")
            }
        }

        return lines.joined(separator: "\n")
    }

    /// Truncate a string to a maximum width, adding "…" if truncated.
    private func truncate(_ string: String, to width: Int) -> String {
        guard string.count > width else { return string }
        return String(string.prefix(width - 1)) + "…"
    }

    /// Column definition for table output.
    public struct Column: Sendable {
        public let title: String
        public let width: Int
        public let extract: @Sendable (LogEntry) -> String

        public init(title: String, width: Int, extract: @escaping @Sendable (LogEntry) -> String) {
            self.title = title
            self.width = width
            self.extract = extract
        }

        public static let defaultColumns: [Column] = [
            Column(title: "TIME", width: 15) { formatTime($0.timestamp) },
            Column(title: "LEVEL", width: 7) { $0.level.rawValue.uppercased() },
            Column(title: "PROCESS", width: 20) { $0.processName },
            Column(title: "SUBSYSTEM", width: 30) { $0.subsystem },
            Column(title: "MESSAGE", width: 60) { $0.eventMessage },
        ]

        private static func formatTime(_ timestamp: String) -> String {
            let parts = timestamp.split(separator: " ")
            if parts.count >= 2 {
                return String(parts[1].prefix(15))
            }
            return String(timestamp.prefix(15))
        }
    }
}
