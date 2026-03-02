import Foundation
import LogToolCore
import Observation

@Observable
final class StatsViewModel {
    var entries: [LogEntry] = []
    var levelCounts: [(level: LogLevel, count: Int)] = []
    var topSubsystems: [(name: String, count: Int)] = []
    var topProcesses: [(name: String, count: Int)] = []
    var anomalies: [Anomaly] = []
    var timeRange = "5m"
    var isLoading = false
    var errorMessage: String?

    private let collector = LogCollector()
    private let detector = AnomalyDetector()

    var totalEntries: Int { entries.count }

    func fetch() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let interval = parseTimeInterval(timeRange) ?? 300
                let filter = LogFilter(lastInterval: interval)
                entries = try await collector.collect(filter: filter, maxEntries: 10000)
                computeStats()
                anomalies = detector.detect(entries: entries)
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func computeStats() {
        // Level counts
        var counts: [LogLevel: Int] = [:]
        for entry in entries {
            counts[entry.level, default: 0] += 1
        }
        levelCounts = LogLevel.allCases.map { level in
            (level: level, count: counts[level] ?? 0)
        }

        // Top subsystems
        let subsystemGroups = Dictionary(grouping: entries, by: \.subsystem)
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
        topSubsystems = subsystemGroups.prefix(10).map { (name: $0.key.isEmpty ? "(none)" : $0.key, count: $0.value) }

        // Top processes
        let processGroups = Dictionary(grouping: entries, by: \.processName)
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
        topProcesses = processGroups.prefix(10).map { (name: $0.key, count: $0.value) }
    }
}
