import XCTest
@testable import LogToolCore

final class LogParserTests: XCTestCase {
    let parser = LogParser()

    func testParseSingleLine() throws {
        let line = """
        {"traceID":1234567890,"eventMessage":"Test message","eventType":"logEvent","source":null,"formatString":"Test message","activityIdentifier":0,"subsystem":"com.test","category":"general","threadID":100,"senderImageUUID":"AABB-1122","backtrace":null,"bootUUID":"1111-2222","processImagePath":"/usr/bin/test","timestamp":"2024-01-15 10:30:00.000000-0800","senderImagePath":"/usr/lib/libSystem.B.dylib","machTimestamp":100000,"messageType":"Default","processImageUUID":"FFEE-DDCC","processID":1234,"senderProgramCounter":5678,"parentActivityIdentifier":0,"timezoneName":"PST"}
        """

        let entry = parser.parseLine(line)
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.eventMessage, "Test message")
        XCTAssertEqual(entry?.subsystem, "com.test")
        XCTAssertEqual(entry?.category, "general")
        XCTAssertEqual(entry?.processID, 1234)
        XCTAssertEqual(entry?.processName, "test")
        XCTAssertEqual(entry?.level, .default)
    }

    func testParseNDJSON() throws {
        let ndjson = loadFixture("sample_log.ndjson")
        let entries = parser.parseNDJSON(ndjson)

        XCTAssertEqual(entries.count, 6)

        // Check first entry
        XCTAssertEqual(entries[0].eventMessage, "Application started successfully")
        XCTAssertEqual(entries[0].subsystem, "com.apple.test.app")
        XCTAssertEqual(entries[0].category, "lifecycle")
        XCTAssertEqual(entries[0].processName, "TestApp")
        XCTAssertEqual(entries[0].level, .default)

        // Check error entry
        XCTAssertEqual(entries[3].level, .error)
        XCTAssertTrue(entries[3].eventMessage.contains("database"))

        // Check fault entry
        XCTAssertEqual(entries[4].level, .fault)

        // Check different subsystem
        XCTAssertEqual(entries[5].subsystem, "com.apple.bluetooth")
        XCTAssertEqual(entries[5].processName, "bluetoothd")
    }

    func testParseEmptyLine() {
        XCTAssertNil(parser.parseLine(""))
    }

    func testParseInvalidJSON() {
        XCTAssertNil(parser.parseLine("not valid json"))
        XCTAssertNil(parser.parseLine("{invalid}"))
    }

    func testLogLevelSeverity() {
        XCTAssertTrue(LogLevel.debug < LogLevel.info)
        XCTAssertTrue(LogLevel.info < LogLevel.default)
        XCTAssertTrue(LogLevel.default < LogLevel.error)
        XCTAssertTrue(LogLevel.error < LogLevel.fault)
    }

    func testLogLevelFromMessageType() {
        let ndjson = loadFixture("sample_log.ndjson")
        let entries = parser.parseNDJSON(ndjson)

        let levels = entries.map(\.level)
        XCTAssertEqual(levels, [.default, .info, .debug, .error, .fault, .default])
    }

    func testProcessNameExtraction() {
        let line = """
        {"traceID":1,"eventMessage":"msg","eventType":"logEvent","source":null,"formatString":"msg","activityIdentifier":0,"subsystem":"","category":"","threadID":1,"senderImageUUID":"","backtrace":null,"bootUUID":"","processImagePath":"/Applications/Safari.app/Contents/MacOS/Safari","timestamp":"2024-01-15 10:00:00.000000-0800","senderImagePath":"/System/Library/Frameworks/WebKit.framework/WebKit","machTimestamp":1,"messageType":"Default","processImageUUID":"","processID":999,"senderProgramCounter":0,"parentActivityIdentifier":0,"timezoneName":"PST"}
        """

        let entry = parser.parseLine(line)
        XCTAssertEqual(entry?.processName, "Safari")
        XCTAssertEqual(entry?.senderName, "WebKit")
    }

    // MARK: - Helpers

    private func loadFixture(_ name: String) -> String {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: name, withExtension: nil, subdirectory: "Fixtures") else {
            XCTFail("Missing fixture: \(name)")
            return ""
        }
        return (try? String(contentsOf: url)) ?? ""
    }
}
