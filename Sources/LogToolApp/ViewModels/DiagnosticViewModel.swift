import Foundation
import LogToolCore
import Observation

@Observable
final class DiagnosticViewModel {
    let preset: DiagnosticPreset

    // Config
    var minutes: Int = 15

    // Results
    var entries: [LogEntry] = []
    var isLoading = false
    var errorMessage: String?
    var completed = false

    // Summary
    var levelCounts: [(level: LogLevel, count: Int)] = []
    var topSubsystems: [(name: String, count: Int)] = []
    var topProcesses: [(name: String, count: Int)] = []

    // Anomalies
    var anomalies: [Anomaly] = []

    // AI
    var aiContext = ""
    var aiResponse = ""
    var aiUsage: AIResponse.Usage?
    var isAnalyzingAI = false

    // Search
    var searchText = ""
    var selectedEntryID: UUID?

    // Drill-down
    var drillDownEntries: [LogEntry] = []
    var drillDownTitle = ""
    var showDrillDown = false
    var selectedAnomaly: Anomaly?

    private let collector = LogCollector()
    private let detector = AnomalyDetector()

    init(preset: DiagnosticPreset) {
        self.preset = preset
        self.aiContext = "Investigating \(preset.name) issues"
    }

    var totalEntries: Int { entries.count }
    var errorFaultCount: Int { entries.filter { $0.level >= .error }.count }
    var uniqueSubsystemCount: Int { Set(entries.map(\.subsystem)).count }
    var uniqueProcessCount: Int { Set(entries.map(\.processName)).count }

    var filteredEntries: [LogEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter {
            $0.eventMessage.localizedCaseInsensitiveContains(searchText) ||
            $0.processName.localizedCaseInsensitiveContains(searchText) ||
            $0.subsystem.localizedCaseInsensitiveContains(searchText)
        }
    }

    var selectedEntry: LogEntry? {
        guard let id = selectedEntryID else { return nil }
        return entries.first { $0.id == id }
    }

    var isAIConfigured: Bool {
        Configuration.shared.load().aiProvider != nil
    }

    var drillDownSelectedEntry: LogEntry? {
        guard let id = selectedEntryID, showDrillDown else { return nil }
        return drillDownEntries.first { $0.id == id }
    }

    func drillIntoLevel(_ level: LogLevel) {
        drillDownEntries = entries.filter { $0.level == level }
        drillDownTitle = "\(level.rawValue.capitalized) Entries"
        selectedEntryID = nil
        showDrillDown = true
    }

    func drillIntoSubsystem(_ name: String) {
        let actualName = name == "(none)" ? "" : name
        drillDownEntries = entries.filter { $0.subsystem == actualName }
        drillDownTitle = name
        selectedEntryID = nil
        showDrillDown = true
    }

    func drillIntoProcess(_ name: String) {
        drillDownEntries = entries.filter { $0.processName == name }
        drillDownTitle = name
        selectedEntryID = nil
        showDrillDown = true
    }

    func drillIntoAll() {
        drillDownEntries = entries
        drillDownTitle = "All Entries"
        selectedEntryID = nil
        showDrillDown = true
    }

    func drillIntoErrors() {
        drillDownEntries = entries.filter { $0.level >= .error }
        drillDownTitle = "Errors & Faults"
        selectedEntryID = nil
        showDrillDown = true
    }

    func run() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        completed = false
        entries = []
        anomalies = []
        aiResponse = ""
        aiUsage = nil

        Task { @MainActor in
            do {
                let filter = preset.buildFilter(lastMinutes: minutes)
                entries = try await collector.collect(filter: filter, maxEntries: 10000)
                computeSummary()
                anomalies = detector.detect(entries: entries)
                completed = true
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    func runAIAnalysis() {
        guard !isAnalyzingAI else { return }
        isAnalyzingAI = true
        errorMessage = nil
        aiResponse = ""
        aiUsage = nil

        Task { @MainActor in
            do {
                let provider = try AIProviderFactory.create()
                let templates = PromptTemplates()
                let prompt = templates.buildAnalysisPrompt(
                    entries: entries,
                    context: aiContext.isEmpty ? nil : aiContext
                )
                let messages = [
                    AIMessage(role: .system, content: PromptTemplates.logAnalysisSystem),
                    AIMessage(role: .user, content: prompt),
                ]
                let response = try await provider.complete(messages: messages)
                aiResponse = response.content
                aiUsage = response.usage
                isAnalyzingAI = false
            } catch {
                errorMessage = error.localizedDescription
                isAnalyzingAI = false
            }
        }
    }

    private func computeSummary() {
        var counts: [LogLevel: Int] = [:]
        for entry in entries { counts[entry.level, default: 0] += 1 }
        levelCounts = LogLevel.allCases.map { (level: $0, count: counts[$0] ?? 0) }

        let subsystemGroups = Dictionary(grouping: entries, by: \.subsystem)
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
        topSubsystems = subsystemGroups.prefix(5).map {
            (name: $0.key.isEmpty ? "(none)" : $0.key, count: $0.value)
        }

        let processGroups = Dictionary(grouping: entries, by: \.processName)
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
        topProcesses = processGroups.prefix(5).map { (name: $0.key, count: $0.value) }
    }
}
