import Foundation

/// Discovers and enumerates active subsystems and categories from macOS logs.
public struct SubsystemDiscovery: Sendable {
    private let collector: LogCollector

    public init(collector: LogCollector = LogCollector()) {
        self.collector = collector
    }

    /// Discover subsystems and their categories from recent logs.
    public func discover(lastInterval: TimeInterval = 300) async throws -> [SubsystemInfo] {
        let filter = LogFilter(lastInterval: lastInterval)
        let entries = try await collector.collect(filter: filter)
        return aggregate(entries: entries)
    }

    /// Aggregate log entries into subsystem info.
    public func aggregate(entries: [LogEntry]) -> [SubsystemInfo] {
        var subsystems: [String: SubsystemAccumulator] = [:]

        for entry in entries {
            let key = entry.subsystem.isEmpty ? "(none)" : entry.subsystem
            var acc = subsystems[key, default: SubsystemAccumulator(subsystem: key)]
            acc.totalCount += 1
            acc.categories[entry.category, default: 0] += 1
            acc.levelCounts[entry.level, default: 0] += 1
            acc.processes.insert(entry.processName)
            subsystems[key] = acc
        }

        return subsystems.values
            .map { acc in
                SubsystemInfo(
                    subsystem: acc.subsystem,
                    totalCount: acc.totalCount,
                    categories: acc.categories.map { CategoryInfo(name: $0.key, count: $0.value) }
                        .sorted { $0.count > $1.count },
                    levelBreakdown: acc.levelCounts,
                    processes: Array(acc.processes).sorted()
                )
            }
            .sorted { $0.totalCount > $1.totalCount }
    }

    private struct SubsystemAccumulator {
        let subsystem: String
        var totalCount: Int = 0
        var categories: [String: Int] = [:]
        var levelCounts: [LogLevel: Int] = [:]
        var processes: Set<String> = []
    }
}

/// Information about a discovered subsystem.
public struct SubsystemInfo: Sendable {
    public let subsystem: String
    public let totalCount: Int
    public let categories: [CategoryInfo]
    public let levelBreakdown: [LogLevel: Int]
    public let processes: [String]

    /// Number of error and fault entries.
    public var errorCount: Int {
        (levelBreakdown[.error] ?? 0) + (levelBreakdown[.fault] ?? 0)
    }
}

/// Information about a category within a subsystem.
public struct CategoryInfo: Sendable {
    public let name: String
    public let count: Int
}
