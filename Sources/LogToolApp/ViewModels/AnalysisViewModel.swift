import Foundation
import LogToolCore
import Observation

@Observable
final class AnalysisViewModel {
    // NL Query tab
    var nlQuery = ""
    var generatedPredicate = ""
    var queryResults: [LogEntry] = []
    var isQuerying = false
    var selectedQueryEntryID: UUID?

    // Log Analysis tab
    var analysisProcess = ""
    var analysisTimeRange = "5m"
    var analysisContext = ""
    var analysisResponse = ""
    var analysisUsage: AIResponse.Usage?
    var isAnalyzing = false

    var errorMessage: String?

    var selectedQueryEntry: LogEntry? {
        guard let id = selectedQueryEntryID else { return nil }
        return queryResults.first { $0.id == id }
    }

    var isAIConfigured: Bool {
        let config = Configuration.shared.load()
        return config.aiProvider != nil
    }

    private let collector = LogCollector()

    func runNLQuery() {
        guard !nlQuery.isEmpty, !isQuerying else { return }
        isQuerying = true
        errorMessage = nil
        generatedPredicate = ""
        queryResults = []

        Task { @MainActor in
            do {
                let provider = try AIProviderFactory.create()
                let templates = PromptTemplates()
                let prompt = templates.buildNLQueryPrompt(query: nlQuery)
                let messages = [
                    AIMessage(role: .system, content: PromptTemplates.nlToPredicateSystem),
                    AIMessage(role: .user, content: prompt),
                ]
                let response = try await provider.complete(messages: messages)
                generatedPredicate = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

                // Try to use the generated predicate to fetch logs
                let filter = LogFilter(lastInterval: 300, predicate: generatedPredicate)
                queryResults = try await collector.collect(filter: filter, maxEntries: 500)
                isQuerying = false
            } catch {
                errorMessage = error.localizedDescription
                isQuerying = false
            }
        }
    }

    func runAnalysis() {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        errorMessage = nil
        analysisResponse = ""
        analysisUsage = nil

        Task { @MainActor in
            do {
                let interval = parseTimeInterval(analysisTimeRange) ?? 300
                let filter = LogFilter(
                    process: analysisProcess.isEmpty ? nil : analysisProcess,
                    lastInterval: interval
                )
                let entries = try await collector.collect(filter: filter, maxEntries: 2000)

                guard !entries.isEmpty else {
                    errorMessage = "No log entries found for the given filters."
                    isAnalyzing = false
                    return
                }

                let provider = try AIProviderFactory.create()
                let templates = PromptTemplates()
                let prompt = templates.buildAnalysisPrompt(
                    entries: entries,
                    context: analysisContext.isEmpty ? nil : analysisContext
                )
                let messages = [
                    AIMessage(role: .system, content: PromptTemplates.logAnalysisSystem),
                    AIMessage(role: .user, content: prompt),
                ]
                let response = try await provider.complete(messages: messages)
                analysisResponse = response.content
                analysisUsage = response.usage
                isAnalyzing = false
            } catch {
                errorMessage = error.localizedDescription
                isAnalyzing = false
            }
        }
    }
}
