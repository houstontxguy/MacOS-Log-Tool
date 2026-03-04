import Foundation
import LogToolCore
import Observation

@Observable
final class ActiveSubsystemPoller {
    var activeSubsystems: [String] = []
    var activeProcesses: [String] = []

    private let discovery = SubsystemDiscovery()
    private var pollTask: Task<Void, Never>?

    func start() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.poll()
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
    }

    @MainActor
    private func poll() async {
        do {
            let infos = try await discovery.discover(lastInterval: 300)
            activeSubsystems = infos.map(\.subsystem).filter { !$0.isEmpty }.sorted()
            var procs = Set<String>()
            for info in infos {
                for p in info.processes { procs.insert(p) }
            }
            activeProcesses = procs.sorted()
        } catch {
            // Silently continue; stale data is fine
        }
    }

    /// Merged suggestions: curated + discovered, deduplicated
    var subsystemSuggestions: [String] {
        let merged = Set(DiagnosticPreset.commonSubsystems).union(activeSubsystems)
        return merged.sorted()
    }

    var processSuggestions: [String] {
        let merged = Set(DiagnosticPreset.commonProcesses).union(activeProcesses)
        return merged.sorted()
    }
}
