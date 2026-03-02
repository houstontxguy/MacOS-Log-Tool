import Foundation

/// Detects statistical anomalies in log data without AI.
/// Identifies error spikes, unusual subsystem activity, and frequency changes.
public struct AnomalyDetector: Sendable {
    public init() {}

    /// Detect anomalies in a collection of log entries.
    public func detect(entries: [LogEntry], windowSize: TimeInterval = 60) -> [Anomaly] {
        var anomalies: [Anomaly] = []

        anomalies += detectErrorSpikes(entries: entries, windowSize: windowSize)
        anomalies += detectRepetitiveMessages(entries: entries)
        anomalies += detectSubsystemBursts(entries: entries, windowSize: windowSize)

        return anomalies.sorted { $0.severity > $1.severity }
    }

    /// Detect spikes in error/fault rate.
    private func detectErrorSpikes(entries: [LogEntry], windowSize: TimeInterval) -> [Anomaly] {
        let errorEntries = entries.filter { $0.level >= .error }
        guard errorEntries.count >= 3 else { return [] }

        let windows = bucketByTime(entries: errorEntries, windowSize: windowSize)
        guard windows.count >= 2 else { return [] }

        let counts = windows.map { Double($0.value.count) }
        let mean = counts.reduce(0, +) / Double(counts.count)
        let variance = counts.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(counts.count)
        let stddev = sqrt(variance)

        guard stddev > 0 else { return [] }

        var anomalies: [Anomaly] = []
        for (windowStart, windowEntries) in windows {
            let count = Double(windowEntries.count)
            let zScore = (count - mean) / stddev
            if zScore > 2.0 {
                let subsystems = Set(windowEntries.map(\.subsystem))
                anomalies.append(Anomaly(
                    type: .errorSpike,
                    description: "Error spike: \(windowEntries.count) errors in \(Int(windowSize))s window (avg: \(String(format: "%.1f", mean)))",
                    timestamp: windowStart,
                    severity: min(zScore / 3.0, 1.0),
                    relatedSubsystems: Array(subsystems),
                    entryCount: windowEntries.count
                ))
            }
        }

        return anomalies
    }

    /// Detect highly repetitive log messages.
    private func detectRepetitiveMessages(entries: [LogEntry]) -> [Anomaly] {
        var messageCounts: [String: Int] = [:]
        for entry in entries {
            let normalized = normalizeMessage(entry.eventMessage)
            messageCounts[normalized, default: 0] += 1
        }

        let threshold = max(10, entries.count / 20) // 5% of total or at least 10

        return messageCounts.compactMap { message, count in
            guard count >= threshold else { return nil }
            let ratio = Double(count) / Double(entries.count)
            return Anomaly(
                type: .repetitiveMessage,
                description: "Repetitive message (\(count)x, \(String(format: "%.0f", ratio * 100))%): \(message.prefix(100))",
                timestamp: nil,
                severity: min(ratio * 2, 1.0),
                relatedSubsystems: [],
                entryCount: count
            )
        }
    }

    /// Detect unusual bursts of activity from specific subsystems.
    private func detectSubsystemBursts(entries: [LogEntry], windowSize: TimeInterval) -> [Anomaly] {
        let bySubsystem = Dictionary(grouping: entries, by: \.subsystem)
        var anomalies: [Anomaly] = []

        for (subsystem, subEntries) in bySubsystem {
            guard subEntries.count >= 5 else { continue }
            let windows = bucketByTime(entries: subEntries, windowSize: windowSize)
            guard windows.count >= 2 else { continue }

            let counts = windows.map { Double($0.value.count) }
            let mean = counts.reduce(0, +) / Double(counts.count)
            let variance = counts.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(counts.count)
            let stddev = sqrt(variance)

            guard stddev > 0 else { continue }

            for (windowStart, windowEntries) in windows {
                let count = Double(windowEntries.count)
                let zScore = (count - mean) / stddev
                if zScore > 2.5 {
                    anomalies.append(Anomaly(
                        type: .subsystemBurst,
                        description: "Burst from \(subsystem): \(windowEntries.count) entries in \(Int(windowSize))s (avg: \(String(format: "%.1f", mean)))",
                        timestamp: windowStart,
                        severity: min(zScore / 4.0, 1.0),
                        relatedSubsystems: [subsystem],
                        entryCount: windowEntries.count
                    ))
                }
            }
        }

        return anomalies
    }

    /// Bucket entries into time windows.
    private func bucketByTime(entries: [LogEntry], windowSize: TimeInterval) -> [(key: Date, value: [LogEntry])] {
        var buckets: [Date: [LogEntry]] = [:]

        for entry in entries {
            guard let date = entry.date else { continue }
            let windowStart = Date(timeIntervalSinceReferenceDate:
                (date.timeIntervalSinceReferenceDate / windowSize).rounded(.down) * windowSize
            )
            buckets[windowStart, default: []].append(entry)
        }

        return buckets.sorted { $0.key < $1.key }
    }

    /// Normalize a message for deduplication (strip numbers, UUIDs, timestamps).
    private func normalizeMessage(_ message: String) -> String {
        var result = message
        // Replace UUIDs
        result = result.replacingOccurrences(
            of: "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}",
            with: "<UUID>",
            options: .regularExpression
        )
        // Replace hex addresses
        result = result.replacingOccurrences(
            of: "0x[0-9a-fA-F]+",
            with: "<HEX>",
            options: .regularExpression
        )
        // Replace standalone numbers
        result = result.replacingOccurrences(
            of: "\\b\\d{4,}\\b",
            with: "<NUM>",
            options: .regularExpression
        )
        return result
    }
}

/// Represents a detected anomaly in log data.
public struct Anomaly: Sendable {
    public let type: AnomalyType
    public let description: String
    public let timestamp: Date?
    public let severity: Double // 0.0 - 1.0
    public let relatedSubsystems: [String]
    public let entryCount: Int

    public enum AnomalyType: String, Sendable {
        case errorSpike = "Error Spike"
        case repetitiveMessage = "Repetitive Message"
        case subsystemBurst = "Subsystem Burst"
        case frequencyChange = "Frequency Change"
    }
}
