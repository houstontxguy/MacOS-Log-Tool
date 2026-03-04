import AppKit
import Foundation
import LogToolCore
import Observation
import UniformTypeIdentifiers

@Observable
final class CaptureAnalyzeViewModel {
    // Capture config
    var minutes: Int = 5
    var process = ""
    var subsystem = ""
    var selectedLevel: LogLevel?

    // Results
    var entries: [LogEntry] = []
    var captureCompleted = false
    var isCapturing = false
    var errorMessage: String?

    // Summary
    var levelCounts: [(level: LogLevel, count: Int)] = []
    var topSubsystems: [(name: String, count: Int)] = []
    var topProcesses: [(name: String, count: Int)] = []

    // Anomalies
    var anomalies: [Anomaly] = []

    // AI Analysis
    var aiContext = ""
    var aiResponse = ""
    var aiUsage: AIResponse.Usage?
    var isAnalyzingAI = false

    // Drill-down
    var selectedEntryID: UUID?
    var drillDownEntries: [LogEntry] = []
    var drillDownTitle = ""
    var showDrillDown = false
    var selectedAnomaly: Anomaly?

    var totalEntries: Int { entries.count }
    var errorFaultCount: Int {
        entries.filter { $0.level >= .error }.count
    }
    var uniqueSubsystemCount: Int {
        Set(entries.map(\.subsystem)).count
    }
    var uniqueProcessCount: Int {
        Set(entries.map(\.processName)).count
    }

    var selectedEntry: LogEntry? {
        guard let id = selectedEntryID else { return nil }
        return drillDownEntries.first { $0.id == id }
    }

    var isAIConfigured: Bool {
        let config = Configuration.shared.load()
        return config.aiProvider != nil
    }

    func drillIntoErrors() {
        drillDownEntries = entries.filter { $0.level >= .error }
        drillDownTitle = "Errors & Faults"
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

    func drillIntoLevel(_ level: LogLevel) {
        drillDownEntries = entries.filter { $0.level == level }
        drillDownTitle = "\(level.rawValue.capitalized) Entries"
        selectedEntryID = nil
        showDrillDown = true
    }

    func drillIntoAll() {
        drillDownEntries = entries
        drillDownTitle = "All Entries"
        selectedEntryID = nil
        showDrillDown = true
    }

    private let collector = LogCollector()
    private let detector = AnomalyDetector()

    func capture() {
        guard !isCapturing else { return }
        isCapturing = true
        errorMessage = nil
        captureCompleted = false
        entries = []
        levelCounts = []
        topSubsystems = []
        topProcesses = []
        anomalies = []
        aiResponse = ""
        aiUsage = nil

        Task { @MainActor in
            do {
                let interval = TimeInterval(minutes * 60)
                let filter = LogFilter(
                    process: process.isEmpty ? nil : process,
                    subsystem: subsystem.isEmpty ? nil : subsystem,
                    level: selectedLevel,
                    lastInterval: interval
                )
                entries = try await collector.collect(filter: filter, maxEntries: 10000)

                guard !entries.isEmpty else {
                    errorMessage = "No log entries found for the given filters."
                    isCapturing = false
                    return
                }

                computeSummary()
                anomalies = detector.detect(entries: entries)
                captureCompleted = true
                isCapturing = false
            } catch {
                errorMessage = error.localizedDescription
                isCapturing = false
            }
        }
    }

    func saveToFile(format: ExportFormat) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "logs-\(ISO8601DateFormatter().string(from: Date()))"
        panel.allowedContentTypes = [format.contentType]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let formatter = JSONOutputFormatter()
        let content: String
        switch format {
        case .json:
            content = formatter.formatEntries(entries)
        case .csv:
            content = formatter.formatEntriesCSV(entries)
        case .ndjson:
            content = formatter.formatEntriesNDJSON(entries)
        }

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
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

    func reset() {
        entries = []
        captureCompleted = false
        isCapturing = false
        errorMessage = nil
        levelCounts = []
        topSubsystems = []
        topProcesses = []
        anomalies = []
        aiResponse = ""
        aiUsage = nil
    }

    private func computeSummary() {
        var counts: [LogLevel: Int] = [:]
        for entry in entries {
            counts[entry.level, default: 0] += 1
        }
        levelCounts = LogLevel.allCases.map { level in
            (level: level, count: counts[level] ?? 0)
        }

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

enum ExportFormat: String, CaseIterable {
    case json = "JSON"
    case csv = "CSV"
    case ndjson = "NDJSON"

    var contentType: UTType {
        switch self {
        case .json: return .json
        case .csv: return .commaSeparatedText
        case .ndjson: return .json
        }
    }

    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        case .ndjson: return "ndjson"
        }
    }
}
