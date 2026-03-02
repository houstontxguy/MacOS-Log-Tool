import ArgumentParser
import Foundation
import LogToolCore

struct DiscoverCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "discover",
        abstract: "Browse all active subsystems and categories with event counts."
    )

    @Option(name: .long, help: "Time range (e.g., 5m, 1h, 30s, 2d).")
    var last: String = "5m"

    @Option(name: .long, help: "Filter subsystems containing this text.")
    var filter: String?

    @Flag(name: .long, help: "Show detailed category breakdown.")
    var detailed: Bool = false

    @Option(name: .long, help: "Output format: table, json.")
    var format: String = "table"

    func run() async throws {
        guard let interval = parseTimeInterval(last) else {
            print("Invalid time range: \(last). Use formats like 5m, 1h, 30s, 2d.")
            throw ExitCode.failure
        }

        let discovery = SubsystemDiscovery()
        var subsystems = try await discovery.discover(lastInterval: interval)

        // Apply text filter
        if let filter {
            subsystems = subsystems.filter {
                $0.subsystem.localizedCaseInsensitiveContains(filter)
            }
        }

        switch format.lowercased() {
        case "json":
            let formatter = JSONOutputFormatter()
            print(formatter.formatSubsystems(subsystems))
        default:
            let formatter = TableFormatter()
            print(formatter.formatSubsystems(subsystems, detailed: detailed))
        }
    }
}
