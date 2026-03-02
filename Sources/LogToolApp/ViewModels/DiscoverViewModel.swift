import Foundation
import LogToolCore
import Observation

@Observable
final class DiscoverViewModel {
    var subsystems: [SubsystemInfo] = []
    var filterText = ""
    var timeRange = "5m"
    var isLoading = false
    var errorMessage: String?

    private let discovery = SubsystemDiscovery()

    var filteredSubsystems: [SubsystemInfo] {
        guard !filterText.isEmpty else { return subsystems }
        return subsystems.filter {
            $0.subsystem.localizedCaseInsensitiveContains(filterText)
        }
    }

    func fetch() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let interval = parseTimeInterval(timeRange) ?? 300
                subsystems = try await discovery.discover(lastInterval: interval)
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
