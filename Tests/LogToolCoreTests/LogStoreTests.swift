import XCTest
@testable import LogToolCore

final class LogStoreTests: XCTestCase {
    var store: LogStore!
    var tempDir: URL!

    override func setUp() async throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("logtool-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        store = try LogStore(path: tempDir.appendingPathComponent("test.db").path)
    }

    override func tearDown() async throws {
        store = nil
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testImportAndCount() throws {
        let entries = makeSampleEntries(count: 10)
        let imported = try store.importEntries(entries)
        XCTAssertEqual(imported, 10)

        let count = try store.count()
        XCTAssertEqual(count, 10)
    }

    func testFullTextSearch() throws {
        let entries = makeSampleEntries(count: 5) + [
            makeEntry(message: "Bluetooth device disconnected unexpectedly", subsystem: "com.apple.bluetooth"),
            makeEntry(message: "WiFi connection lost", subsystem: "com.apple.wifi"),
        ]

        _ = try store.importEntries(entries)

        let results = try store.search(query: "bluetooth")
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0].eventMessage.lowercased().contains("bluetooth"))
    }

    func testSearchNoResults() throws {
        let entries = makeSampleEntries(count: 5)
        _ = try store.importEntries(entries)

        let results = try store.search(query: "nonexistentterm12345")
        XCTAssertTrue(results.isEmpty)
    }

    func testEmptyStoreCount() throws {
        let count = try store.count()
        XCTAssertEqual(count, 0)
    }

    // MARK: - Helpers

    private func makeSampleEntries(count: Int) -> [LogEntry] {
        (0..<count).map { i in
            makeEntry(message: "Test message \(i)", subsystem: "com.test.subsystem\(i % 3)")
        }
    }

    private func makeEntry(
        message: String,
        subsystem: String = "com.test",
        category: String = "general",
        messageType: String = "Default",
        processName: String = "TestProcess"
    ) -> LogEntry {
        LogEntry(
            traceID: UInt64(Int64.random(in: 0...Int64.max)),
            eventMessage: message,
            eventType: "logEvent",
            source: nil,
            formatString: message,
            activityIdentifier: 0,
            subsystem: subsystem,
            category: category,
            threadID: 1,
            senderImageUUID: "test-uuid",
            backtrace: nil,
            bootUUID: "boot-uuid",
            processImagePath: "/usr/bin/\(processName)",
            timestamp: "2024-01-15 10:30:00.000000-0800",
            senderImagePath: "/usr/lib/libSystem.B.dylib",
            machTimestamp: 100000,
            messageType: messageType,
            processImageUUID: "proc-uuid",
            processID: 1234,
            senderProgramCounter: 5678,
            parentActivityIdentifier: 0,
            timezoneName: "PST"
        )
    }
}
