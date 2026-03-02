import Foundation
import LogToolCore
import Observation

@Observable
final class LogBrowserViewModel {
    var entries: [LogEntry] = []
    var selectedEntryID: UUID?

    var selectedEntry: LogEntry? {
        guard let id = selectedEntryID else { return nil }
        return entries.first { $0.id == id }
    }
    var process = ""
    var subsystem = ""
    var selectedLevel: LogLevel?
    var timeRange = "5m"
    var searchText = ""
    var isLoading = false
    var errorMessage: String?

    private let collector = LogCollector()

    var filteredEntries: [LogEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter {
            $0.eventMessage.localizedCaseInsensitiveContains(searchText)
        }
    }

    func fetch() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let interval = parseTimeInterval(timeRange) ?? 300
                let filter = LogFilter(
                    process: process.isEmpty ? nil : process,
                    subsystem: subsystem.isEmpty ? nil : subsystem,
                    level: selectedLevel,
                    lastInterval: interval
                )
                entries = try await collector.collect(filter: filter, maxEntries: 5000)
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
