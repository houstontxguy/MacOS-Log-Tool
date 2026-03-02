import Foundation

/// ASCII timeline rendering for log density visualization.
public struct TimelineFormatter: Sendable {
    private let colorFormatter: ColorFormatter
    private let width: Int

    public init(width: Int = 60, colorFormatter: ColorFormatter = ColorFormatter()) {
        self.width = width
        self.colorFormatter = colorFormatter
    }

    /// Render a timeline showing log entry density over time.
    public func renderTimeline(entries: [LogEntry], bucketCount: Int? = nil) -> String {
        guard !entries.isEmpty else { return "No entries to visualize." }

        let dates = entries.compactMap(\.date)
        guard let minDate = dates.min(), let maxDate = dates.max() else {
            return "Cannot parse timestamps."
        }

        let totalDuration = maxDate.timeIntervalSince(minDate)
        guard totalDuration > 0 else {
            return "All entries at same timestamp."
        }

        let numBuckets = bucketCount ?? min(width, 60)
        let bucketDuration = totalDuration / Double(numBuckets)

        // Count entries per bucket, split by severity
        var normalBuckets = [Int](repeating: 0, count: numBuckets)
        var errorBuckets = [Int](repeating: 0, count: numBuckets)

        for entry in entries {
            guard let date = entry.date else { continue }
            let offset = date.timeIntervalSince(minDate)
            let bucket = min(Int(offset / bucketDuration), numBuckets - 1)
            if entry.level >= .error {
                errorBuckets[bucket] += 1
            } else {
                normalBuckets[bucket] += 1
            }
        }

        let totalBuckets = zip(normalBuckets, errorBuckets).map(+)
        let maxCount = totalBuckets.max() ?? 1
        let barHeight = 8

        var lines: [String] = []
        lines.append(colorFormatter.colorize("Log Timeline", .bold))
        lines.append(colorFormatter.colorize(
            "\(formatDate(minDate)) → \(formatDate(maxDate))", .dim))
        lines.append("")

        // Render bars top-down
        for row in stride(from: barHeight, through: 1, by: -1) {
            let threshold = Double(row) / Double(barHeight) * Double(maxCount)
            var line = ""
            for i in 0..<numBuckets {
                let total = totalBuckets[i]
                let hasError = errorBuckets[i] > 0
                if Double(total) >= threshold {
                    if hasError {
                        line += colorFormatter.colorize("█", .boldRed)
                    } else {
                        line += colorFormatter.colorize("█", .blue)
                    }
                } else {
                    line += " "
                }
            }

            // Y-axis label for top and middle
            if row == barHeight {
                line += colorFormatter.colorize("  \(maxCount)", .dim)
            } else if row == barHeight / 2 {
                line += colorFormatter.colorize("  \(maxCount / 2)", .dim)
            }

            lines.append(line)
        }

        // X-axis
        lines.append(String(repeating: "─", count: numBuckets))

        // Legend
        lines.append("")
        lines.append(colorFormatter.colorize("█", .blue) + " Normal  " +
            colorFormatter.colorize("█", .boldRed) + " Error/Fault  " +
            colorFormatter.colorize("Total: \(entries.count) entries", .dim))

        return lines.joined(separator: "\n")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
