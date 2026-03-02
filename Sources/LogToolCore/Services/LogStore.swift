import Foundation
import GRDB

/// SQLite-backed log storage with full-text search via FTS5.
public final class LogStore: Sendable {
    private let dbPool: DatabasePool

    public init(path: String? = nil) throws {
        let dbPath = path ?? Configuration.shared.databasePath.path
        let dir = (dbPath as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        dbPool = try DatabasePool(path: dbPath)
        try migrate()
    }

    /// Run database migrations.
    private func migrate() throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "log_entries") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("traceID", .integer)
                t.column("eventMessage", .text).notNull()
                t.column("eventType", .text)
                t.column("subsystem", .text).notNull().defaults(to: "")
                t.column("category", .text).notNull().defaults(to: "")
                t.column("processName", .text).notNull()
                t.column("processID", .integer)
                t.column("threadID", .integer)
                t.column("messageType", .text)
                t.column("timestamp", .text).notNull()
                t.column("senderName", .text)
                t.column("processImagePath", .text)
                t.column("senderImagePath", .text)
                t.column("source", .text)
            }

            try db.create(
                virtualTable: "log_entries_fts",
                using: FTS5()
            ) { t in
                t.tokenizer = .porter(wrapping: .unicode61())
                t.synchronize(withTable: "log_entries")
                t.column("eventMessage")
                t.column("subsystem")
                t.column("category")
                t.column("processName")
            }

            try db.create(index: "idx_log_entries_timestamp", on: "log_entries", columns: ["timestamp"])
            try db.create(index: "idx_log_entries_subsystem", on: "log_entries", columns: ["subsystem"])
            try db.create(index: "idx_log_entries_processName", on: "log_entries", columns: ["processName"])
            try db.create(index: "idx_log_entries_messageType", on: "log_entries", columns: ["messageType"])
        }

        try migrator.migrate(dbPool)
    }

    /// Import log entries into the store.
    public func importEntries(_ entries: [LogEntry]) throws -> Int {
        try dbPool.write { db in
            var count = 0
            for entry in entries {
                try db.execute(
                    sql: """
                        INSERT INTO log_entries
                        (traceID, eventMessage, eventType, subsystem, category,
                         processName, processID, threadID, messageType, timestamp,
                         senderName, processImagePath, senderImagePath, source)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """,
                    arguments: [
                        entry.traceID, entry.eventMessage, entry.eventType,
                        entry.subsystem, entry.category,
                        entry.processName, entry.processID, entry.threadID,
                        entry.messageType, entry.timestamp,
                        entry.senderName, entry.processImagePath,
                        entry.senderImagePath, entry.source
                    ]
                )
                count += 1
            }
            return count
        }
    }

    /// Full-text search across imported logs.
    public func search(query: String, limit: Int = 100) throws -> [StoredLogEntry] {
        try dbPool.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT log_entries.*
                FROM log_entries
                JOIN log_entries_fts ON log_entries.id = log_entries_fts.rowid
                WHERE log_entries_fts MATCH ?
                ORDER BY rank
                LIMIT ?
                """,
                arguments: [query, limit]
            )
            return rows.map { StoredLogEntry(row: $0) }
        }
    }

    /// Count total stored entries.
    public func count() throws -> Int {
        try dbPool.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM log_entries") ?? 0
        }
    }
}

/// A log entry as stored in the database.
public struct StoredLogEntry: Sendable {
    public let id: Int64
    public let eventMessage: String
    public let eventType: String?
    public let subsystem: String
    public let category: String
    public let processName: String
    public let processID: Int?
    public let messageType: String?
    public let timestamp: String
    public let senderName: String?

    init(row: Row) {
        id = row["id"]
        eventMessage = row["eventMessage"]
        eventType = row["eventType"]
        subsystem = row["subsystem"]
        category = row["category"]
        processName = row["processName"]
        processID = row["processID"]
        messageType = row["messageType"]
        timestamp = row["timestamp"]
        senderName = row["senderName"]
    }

    public var level: LogLevel {
        LogLevel(rawValue: (messageType ?? "default").lowercased()) ?? .default
    }
}
