import Foundation

/// Builds NSPredicate-style filter strings for the macOS `log` command.
public struct PredicateBuilder: Sendable {
    public init() {}

    /// Build a predicate string from a LogFilter.
    public func build(from filter: LogFilter) -> String? {
        var clauses: [String] = []

        if let process = filter.process {
            clauses.append("process == \"\(escapePredicateString(process))\"")
        }

        if let subsystem = filter.subsystem {
            clauses.append("subsystem == \"\(escapePredicateString(subsystem))\"")
        }

        if let category = filter.category {
            clauses.append("category == \"\(escapePredicateString(category))\"")
        }

        if let senderName = filter.senderName {
            clauses.append("senderImagePath ENDSWITH \"\(escapePredicateString(senderName))\"")
        }

        if let messageContains = filter.messageContains {
            clauses.append("eventMessage CONTAINS[c] \"\(escapePredicateString(messageContains))\"")
        }

        if let level = filter.level {
            let levelClause = levelPredicate(for: level)
            if !levelClause.isEmpty {
                clauses.append(levelClause)
            }
        }

        if let predicate = filter.predicate {
            clauses.append(predicate)
        }

        guard !clauses.isEmpty else { return nil }
        return clauses.joined(separator: " AND ")
    }

    /// Build command-line arguments for the `log` command from a filter.
    public func buildArguments(from filter: LogFilter) -> [String] {
        var args: [String] = []

        if let predicate = build(from: filter) {
            args += ["--predicate", predicate]
        }

        return args
    }

    /// Generate a predicate clause for minimum log level.
    private func levelPredicate(for level: LogLevel) -> String {
        switch level {
        case .debug:
            return "" // debug shows everything
        case .info:
            return "messageType IN {1, 2, 16, 17}"
        case .default:
            return "messageType IN {2, 16, 17}"
        case .error:
            return "messageType IN {16, 17}"
        case .fault:
            return "messageType == 17"
        }
    }

    /// Escape special characters in predicate string values.
    private func escapePredicateString(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
