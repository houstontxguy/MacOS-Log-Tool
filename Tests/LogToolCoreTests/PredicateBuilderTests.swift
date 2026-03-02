import XCTest
@testable import LogToolCore

final class PredicateBuilderTests: XCTestCase {
    let builder = PredicateBuilder()

    func testEmptyFilter() {
        let filter = LogFilter()
        XCTAssertNil(builder.build(from: filter))
    }

    func testProcessFilter() {
        let filter = LogFilter(process: "Finder")
        let predicate = builder.build(from: filter)
        XCTAssertEqual(predicate, "process == \"Finder\"")
    }

    func testSubsystemFilter() {
        let filter = LogFilter(subsystem: "com.apple.bluetooth")
        let predicate = builder.build(from: filter)
        XCTAssertEqual(predicate, "subsystem == \"com.apple.bluetooth\"")
    }

    func testCategoryFilter() {
        let filter = LogFilter(category: "networking")
        let predicate = builder.build(from: filter)
        XCTAssertEqual(predicate, "category == \"networking\"")
    }

    func testMessageContainsFilter() {
        let filter = LogFilter(messageContains: "error")
        let predicate = builder.build(from: filter)
        XCTAssertEqual(predicate, "eventMessage CONTAINS[c] \"error\"")
    }

    func testLevelFilter() {
        let filter = LogFilter(level: .error)
        let predicate = builder.build(from: filter)
        XCTAssertEqual(predicate, "messageType IN {16, 17}")
    }

    func testFaultLevelFilter() {
        let filter = LogFilter(level: .fault)
        let predicate = builder.build(from: filter)
        XCTAssertEqual(predicate, "messageType == 17")
    }

    func testDebugLevelProducesNoPredicate() {
        let filter = LogFilter(level: .debug)
        // Debug shows everything, so no level predicate needed
        XCTAssertNil(builder.build(from: filter))
    }

    func testCombinedFilters() {
        let filter = LogFilter(
            process: "Safari",
            subsystem: "com.apple.WebKit",
            level: .error
        )
        let predicate = builder.build(from: filter)
        XCTAssertNotNil(predicate)
        XCTAssertTrue(predicate!.contains("process == \"Safari\""))
        XCTAssertTrue(predicate!.contains("subsystem == \"com.apple.WebKit\""))
        XCTAssertTrue(predicate!.contains("messageType IN {16, 17}"))
        XCTAssertTrue(predicate!.contains(" AND "))
    }

    func testCustomPredicate() {
        let filter = LogFilter(predicate: "eventMessage BEGINSWITH \"CUSTOM\"")
        let predicate = builder.build(from: filter)
        XCTAssertEqual(predicate, "eventMessage BEGINSWITH \"CUSTOM\"")
    }

    func testSpecialCharacterEscaping() {
        let filter = LogFilter(process: "My \"App\"")
        let predicate = builder.build(from: filter)
        XCTAssertEqual(predicate, "process == \"My \\\"App\\\"\"")
    }

    func testBuildArguments() {
        let filter = LogFilter(process: "Finder")
        let args = builder.buildArguments(from: filter)
        XCTAssertEqual(args, ["--predicate", "process == \"Finder\""])
    }

    func testBuildArgumentsEmpty() {
        let filter = LogFilter()
        let args = builder.buildArguments(from: filter)
        XCTAssertTrue(args.isEmpty)
    }

    func testSenderNameFilter() {
        let filter = LogFilter(senderName: "CoreBluetooth")
        let predicate = builder.build(from: filter)
        XCTAssertEqual(predicate, "senderImagePath ENDSWITH \"CoreBluetooth\"")
    }
}
