import XCTest
@testable import LogToolCore

final class CrashReportParserTests: XCTestCase {
    let parser = CrashReportParser()

    func testParseSampleCrash() throws {
        let content = loadFixture("sample_crash.ips")
        let crash = try parser.parse(content: content, filePath: "/test/sample_crash.ips")

        // Header
        XCTAssertEqual(crash.header.bugType, "309")
        XCTAssertEqual(crash.header.name, "TestApp")
        XCTAssertTrue(crash.header.os_version?.contains("14.2.1") ?? false)
        XCTAssertEqual(crash.header.incident_id, "AAAABBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF")

        // Body basics
        XCTAssertEqual(crash.body.pid, 1234)
        XCTAssertEqual(crash.body.procName, "TestApp")
        XCTAssertEqual(crash.body.parentProc, "launchd")
        XCTAssertEqual(crash.body.parentPid, 1)
        XCTAssertEqual(crash.body.cpuType, "ARM-64")
        XCTAssertEqual(crash.body.faultingThread, 0)

        // Bundle info
        XCTAssertEqual(crash.body.bundleInfo?.CFBundleIdentifier, "com.test.TestApp")
        XCTAssertEqual(crash.body.bundleInfo?.CFBundleShortVersionString, "1.0.0")

        // Exception
        XCTAssertEqual(crash.body.exception?.type, "EXC_BAD_ACCESS")
        XCTAssertEqual(crash.body.exception?.signal, "SIGSEGV")
        XCTAssertTrue(crash.body.exception?.codes?.contains("KERN_INVALID_ADDRESS") ?? false)

        // Termination
        XCTAssertEqual(crash.body.termination?.code, 11)
        XCTAssertEqual(crash.body.termination?.namespace, "SIGNAL")

        // Threads
        XCTAssertEqual(crash.body.threads?.count, 2)

        let mainThread = crash.body.threads?[0]
        XCTAssertEqual(mainThread?.name, "main")
        XCTAssertEqual(mainThread?.triggered, true)
        XCTAssertEqual(mainThread?.queue, "com.apple.main-thread")
        XCTAssertEqual(mainThread?.frames?.count, 4)
        XCTAssertEqual(mainThread?.frames?[0].symbol, "TestApp.DataManager.loadData()")

        // Used images
        XCTAssertEqual(crash.body.usedImages?.count, 3)
        XCTAssertEqual(crash.body.usedImages?[0].name, "TestApp")
    }

    func testCrashSummary() throws {
        let content = loadFixture("sample_crash.ips")
        let crash = try parser.parse(content: content, filePath: "/test/sample_crash.ips")

        let summary = crash.summary
        XCTAssertTrue(summary.contains("TestApp"))
        XCTAssertTrue(summary.contains("EXC_BAD_ACCESS"))
        XCTAssertTrue(summary.contains("SIGSEGV"))
    }

    func testProcessName() throws {
        let content = loadFixture("sample_crash.ips")
        let crash = try parser.parse(content: content, filePath: "/test/sample_crash.ips")
        XCTAssertEqual(crash.processName, "TestApp")
    }

    func testInvalidFormat() {
        XCTAssertThrowsError(try parser.parse(content: "", filePath: "")) { error in
            XCTAssertTrue(error is CrashReportError)
        }
    }

    func testInvalidHeader() {
        XCTAssertThrowsError(try parser.parse(content: "not json\n{}", filePath: "")) { error in
            XCTAssertTrue(error is CrashReportError)
        }
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
