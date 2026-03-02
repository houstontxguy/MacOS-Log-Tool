import Foundation

/// Parses log output from the macOS `log` command in various formats.
public struct LogParser: Sendable {
    private let decoder: JSONDecoder

    public init() {
        self.decoder = JSONDecoder()
    }

    /// Parse a single ndjson line into a LogEntry.
    public func parseLine(_ line: String) -> LogEntry? {
        guard !line.isEmpty else { return nil }
        guard let data = line.data(using: .utf8) else { return nil }
        return try? decoder.decode(LogEntry.self, from: data)
    }

    /// Parse multiple ndjson lines into LogEntry array.
    public func parseNDJSON(_ text: String) -> [LogEntry] {
        text.split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { parseLine(String($0)) }
    }

    /// Parse a JSON array of log entries.
    public func parseJSONArray(_ text: String) -> [LogEntry] {
        guard let data = text.data(using: .utf8) else { return [] }
        return (try? decoder.decode([LogEntry].self, from: data)) ?? []
    }

    /// Stream-parse ndjson lines, yielding entries as they're parsed.
    public func parseStream(_ lines: AsyncThrowingStream<String, Error>) -> AsyncThrowingStream<LogEntry, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in lines {
                        if let entry = parseLine(line) {
                            continuation.yield(entry)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
