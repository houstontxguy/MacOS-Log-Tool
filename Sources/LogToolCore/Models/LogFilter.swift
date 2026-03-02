import Foundation

/// Configuration for filtering log entries.
public struct LogFilter: Sendable {
    public var process: String?
    public var subsystem: String?
    public var category: String?
    public var level: LogLevel?
    public var messageContains: String?
    public var startTime: Date?
    public var endTime: Date?
    public var lastInterval: TimeInterval?
    public var predicate: String?
    public var senderName: String?

    public init(
        process: String? = nil,
        subsystem: String? = nil,
        category: String? = nil,
        level: LogLevel? = nil,
        messageContains: String? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        lastInterval: TimeInterval? = nil,
        predicate: String? = nil,
        senderName: String? = nil
    ) {
        self.process = process
        self.subsystem = subsystem
        self.category = category
        self.level = level
        self.messageContains = messageContains
        self.startTime = startTime
        self.endTime = endTime
        self.lastInterval = lastInterval
        self.predicate = predicate
        self.senderName = senderName
    }

    /// Whether this filter has any constraints set.
    public var isEmpty: Bool {
        process == nil && subsystem == nil && category == nil &&
        level == nil && messageContains == nil && startTime == nil &&
        endTime == nil && lastInterval == nil && predicate == nil &&
        senderName == nil
    }
}

/// Time range specification for log queries.
public enum TimeRange: Sendable {
    case last(TimeInterval)
    case between(start: Date, end: Date)
    case since(Date)

    /// Convert to start/end dates from the current moment.
    public func resolve() -> (start: Date, end: Date) {
        let now = Date()
        switch self {
        case .last(let interval):
            return (start: now.addingTimeInterval(-interval), end: now)
        case .between(let start, let end):
            return (start: start, end: end)
        case .since(let start):
            return (start: start, end: now)
        }
    }
}

/// Parses time duration strings like "5m", "1h", "30s", "2d" into TimeInterval.
public func parseTimeInterval(_ string: String) -> TimeInterval? {
    let str = string.trimmingCharacters(in: .whitespaces).lowercased()
    guard str.count >= 2 else { return nil }

    let suffix = str.last!
    guard let value = Double(str.dropLast()) else { return nil }

    switch suffix {
    case "s": return value
    case "m": return value * 60
    case "h": return value * 3600
    case "d": return value * 86400
    case "w": return value * 604800
    default: return nil
    }
}
