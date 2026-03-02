import Foundation

/// Represents a single unified log entry from macOS `log show --style ndjson` output.
/// Fields match the ndjson schema produced by the `log` command.
public struct LogEntry: Codable, Sendable, Identifiable, Hashable {
    public let id = UUID()

    public let traceID: UInt64
    public let eventMessage: String
    public let eventType: String
    public let source: String?
    public let formatString: String?
    public let activityIdentifier: UInt64
    public let subsystem: String
    public let category: String
    public let threadID: UInt64
    public let senderImageUUID: String
    public let backtrace: BacktraceInfo?
    public let bootUUID: String
    public let processImagePath: String
    public let timestamp: String
    public let senderImagePath: String
    public let machTimestamp: UInt64
    public let messageType: String
    public let processImageUUID: String
    public let processID: Int
    public let senderProgramCounter: UInt64
    public let parentActivityIdentifier: UInt64
    public let timezoneName: String

    public struct BacktraceInfo: Codable, Sendable {
        public let frames: [BacktraceFrame]

        public struct BacktraceFrame: Codable, Sendable {
            public let imageOffset: Int
            public let imageUUID: String
        }
    }

    enum CodingKeys: String, CodingKey {
        case traceID
        case eventMessage
        case eventType
        case source
        case formatString
        case activityIdentifier
        case subsystem
        case category
        case threadID
        case senderImageUUID
        case backtrace
        case bootUUID
        case processImagePath
        case timestamp
        case senderImagePath
        case machTimestamp
        case messageType
        case processImageUUID
        case processID
        case senderProgramCounter
        case parentActivityIdentifier
        case timezoneName
    }

    /// The log level derived from `messageType`.
    public var level: LogLevel {
        LogLevel(rawValue: messageType.lowercased()) ?? .default
    }

    /// The process name extracted from the process image path.
    public var processName: String {
        (processImagePath as NSString).lastPathComponent
    }

    /// The sender (library/framework) name extracted from sender image path.
    public var senderName: String {
        (senderImagePath as NSString).lastPathComponent
    }

    /// Parsed timestamp as Date.
    public var date: Date? {
        LogEntry.dateFormatter.date(from: timestamp)
            ?? LogEntry.fallbackDateFormatter.date(from: timestamp)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSZ"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let fallbackDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSZZZZZ"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    public static func == (lhs: LogEntry, rhs: LogEntry) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Log severity levels matching macOS unified logging.
public enum LogLevel: String, Codable, Sendable, CaseIterable, Comparable {
    case `default` = "default"
    case info = "info"
    case debug = "debug"
    case error = "error"
    case fault = "fault"

    /// Numeric severity for comparison (higher = more severe).
    public var severity: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .default: return 2
        case .error: return 3
        case .fault: return 4
        }
    }

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.severity < rhs.severity
    }
}
