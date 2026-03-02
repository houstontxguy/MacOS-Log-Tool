import Foundation
import LogToolCore
import Observation

@Observable
final class StreamViewModel {
    var entries: [LogEntry] = []
    var isStreaming = false
    var process = ""
    var subsystem = ""
    var selectedLevel: LogLevel?
    var errorMessage: String?
    var autoScroll = true
    var maxEntries = 5000

    private let collector = LogCollector()
    private var streamTask: Task<Void, Never>?

    var entryCount: Int { entries.count }

    func toggleStream() {
        if isStreaming {
            stop()
        } else {
            start()
        }
    }

    func start() {
        guard !isStreaming else { return }
        isStreaming = true
        errorMessage = nil

        let filter = LogFilter(
            process: process.isEmpty ? nil : process,
            subsystem: subsystem.isEmpty ? nil : subsystem,
            level: selectedLevel
        )

        let stream = collector.stream(filter: filter)

        streamTask = Task { @MainActor in
            do {
                for try await entry in stream {
                    if Task.isCancelled { break }
                    entries.append(entry)
                    if entries.count > maxEntries {
                        entries.removeFirst(entries.count - maxEntries)
                    }
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }
            isStreaming = false
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }

    func clear() {
        entries.removeAll()
    }

    deinit {
        streamTask?.cancel()
    }
}
