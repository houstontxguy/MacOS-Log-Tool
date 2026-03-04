import Foundation
import LogToolCore
import Observation

enum DrillDownLevel: Hashable {
    case subsystem(String)
    case category(subsystem: String, category: String)
    case process(subsystem: String, process: String)
    case errors(subsystem: String)
}

@Observable
final class DiscoverViewModel {
    var subsystems: [SubsystemInfo] = []
    var filterText = ""
    var timeRange = "5m"
    var isLoading = false
    var errorMessage: String?

    // Drill-down state
    var navigationPath: [DrillDownLevel] = []
    var drillDownEntries: [LogEntry] = []
    var selectedEntryID: UUID?
    var isLoadingEntries = false

    private let discovery = SubsystemDiscovery()
    private let collector = LogCollector()

    var filteredSubsystems: [SubsystemInfo] {
        guard !filterText.isEmpty else { return subsystems }
        return subsystems.filter {
            $0.subsystem.localizedCaseInsensitiveContains(filterText)
        }
    }

    var selectedEntry: LogEntry? {
        guard let id = selectedEntryID else { return nil }
        return drillDownEntries.first { $0.id == id }
    }

    private var currentInterval: TimeInterval {
        parseTimeInterval(timeRange) ?? 300
    }

    func fetch() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            do {
                subsystems = try await discovery.discover(lastInterval: currentInterval)
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    func fetchEntriesForSubsystem(_ subsystem: String) {
        loadEntries(filter: LogFilter(
            subsystem: subsystem,
            lastInterval: currentInterval
        ))
        navigationPath.append(.subsystem(subsystem))
    }

    func drillIntoCategory(subsystem: String, category: String) {
        loadEntries(filter: LogFilter(
            subsystem: subsystem,
            category: category,
            lastInterval: currentInterval
        ))
        navigationPath.append(.category(subsystem: subsystem, category: category))
    }

    func drillIntoProcess(subsystem: String, process: String) {
        loadEntries(filter: LogFilter(
            process: process,
            subsystem: subsystem,
            lastInterval: currentInterval
        ))
        navigationPath.append(.process(subsystem: subsystem, process: process))
    }

    func drillIntoErrors(subsystem: String) {
        loadEntries(filter: LogFilter(
            subsystem: subsystem,
            level: .error,
            lastInterval: currentInterval
        ))
        navigationPath.append(.errors(subsystem: subsystem))
    }

    private func loadEntries(filter: LogFilter) {
        isLoadingEntries = true
        selectedEntryID = nil
        drillDownEntries = []

        Task { @MainActor in
            do {
                drillDownEntries = try await collector.collect(filter: filter, maxEntries: 5000)
                isLoadingEntries = false
            } catch {
                errorMessage = error.localizedDescription
                isLoadingEntries = false
            }
        }
    }
}
