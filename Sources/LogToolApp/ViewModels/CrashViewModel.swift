import Foundation
import LogToolCore
import Observation

@Observable
final class CrashViewModel {
    var crashes: [CrashReport] = []
    var selectedCrash: CrashReport?
    var correlatedLogs: [LogEntry] = []
    var analysisResult: String?
    var selectedLogEntryID: UUID?
    var isLoading = false
    var isCorrelating = false
    var isAnalyzing = false
    var errorMessage: String?

    var selectedLogEntry: LogEntry? {
        guard let id = selectedLogEntryID else { return nil }
        return correlatedLogs.first { $0.id == id }
    }

    private let parser = CrashReportParser()
    private let collector = LogCollector()

    func loadCrashes() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let urls = parser.listCrashReports()
                var reports: [CrashReport] = []
                for url in urls.prefix(50) {
                    if let report = try? parser.parse(at: url.path) {
                        reports.append(report)
                    }
                }
                crashes = reports
                isLoading = false
            }
        }
    }

    func selectCrash(_ crash: CrashReport) {
        selectedCrash = crash
        correlatedLogs = []
        analysisResult = nil
    }

    func correlateLogs() {
        guard let crash = selectedCrash, let crashDate = crash.date else { return }
        guard !isCorrelating else { return }
        isCorrelating = true

        Task { @MainActor in
            do {
                let windowSeconds: TimeInterval = 300 // 5 minutes
                let filter = LogFilter(
                    process: crash.processName,
                    startTime: crashDate.addingTimeInterval(-windowSeconds),
                    endTime: crashDate.addingTimeInterval(windowSeconds)
                )
                correlatedLogs = try await collector.collect(filter: filter, maxEntries: 500)
                isCorrelating = false
            } catch {
                errorMessage = error.localizedDescription
                isCorrelating = false
            }
        }
    }

    func analyzeWithAI() {
        guard let crash = selectedCrash else { return }
        guard !isAnalyzing else { return }
        isAnalyzing = true
        analysisResult = nil

        Task { @MainActor in
            do {
                let provider = try AIProviderFactory.create()
                let templates = PromptTemplates()
                let prompt = templates.buildCrashAnalysisPrompt(crash: crash, logs: correlatedLogs)
                let messages = [
                    AIMessage(role: .system, content: PromptTemplates.crashAnalysisSystem),
                    AIMessage(role: .user, content: prompt),
                ]
                let response = try await provider.complete(messages: messages)
                analysisResult = response.content
                isAnalyzing = false
            } catch {
                errorMessage = error.localizedDescription
                isAnalyzing = false
            }
        }
    }
}
