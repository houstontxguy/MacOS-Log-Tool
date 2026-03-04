import Foundation
import LogToolCore
import Observation

enum ProcessClassification: String {
    case appleSystem = "Apple System"
    case appleFramework = "Apple Framework"
    case thirdParty = "Third Party"
    case userApp = "User App"

    var icon: String {
        switch self {
        case .appleSystem: return "apple.logo"
        case .appleFramework: return "building.columns"
        case .thirdParty: return "shippingbox"
        case .userApp: return "person"
        }
    }
}

@Observable
final class EntryInspectorViewModel {
    let entry: LogEntry
    let siblings: [LogEntry]

    // Heuristic context
    var processClassification: ProcessClassification = .userApp
    var subsystemErrorRate: Double = 0
    var subsystemErrorCount: Int = 0
    var subsystemTotalCount: Int = 0
    var messageFrequency: Int = 0
    var sameProcessEntries: [LogEntry] = []
    var sameSubsystemEntries: [LogEntry] = []
    var sameThreadEntries: [LogEntry] = []
    var temporalNeighbors: [LogEntry] = []

    // AI
    var aiAnalysis = ""
    var isAnalyzingAI = false
    var aiUsage: AIResponse.Usage?
    var aiError: String?

    var isAIConfigured: Bool {
        Configuration.shared.load().aiProvider != nil
    }

    init(entry: LogEntry, siblings: [LogEntry]) {
        self.entry = entry
        self.siblings = siblings
        computeContext()
    }

    private func computeContext() {
        // Process classification
        processClassification = classifyProcess(entry.processImagePath)

        // Subsystem error rate
        let subsystemEntries = siblings.filter { $0.subsystem == entry.subsystem }
        subsystemTotalCount = subsystemEntries.count
        subsystemErrorCount = subsystemEntries.filter { $0.level >= .error }.count
        subsystemErrorRate = subsystemTotalCount > 0 ? Double(subsystemErrorCount) / Double(subsystemTotalCount) : 0

        // Message frequency
        let normalizedMessage = normalizeMessage(entry.eventMessage)
        messageFrequency = siblings.filter { normalizeMessage($0.eventMessage) == normalizedMessage }.count

        // Same-process entries
        sameProcessEntries = siblings.filter { $0.processName == entry.processName && $0.id != entry.id }

        // Same-subsystem entries
        sameSubsystemEntries = siblings.filter { $0.subsystem == entry.subsystem && $0.id != entry.id }

        // Same-thread entries
        sameThreadEntries = siblings.filter { $0.threadID == entry.threadID && $0.id != entry.id }

        // Temporal neighbors (±5 seconds)
        if let entryDate = entry.date {
            temporalNeighbors = siblings.filter { sibling in
                guard sibling.id != entry.id, let siblingDate = sibling.date else { return false }
                return abs(siblingDate.timeIntervalSince(entryDate)) <= 5.0
            }.sorted { a, b in
                (a.date ?? .distantPast) < (b.date ?? .distantPast)
            }
        }
    }

    func runAIAnalysis() {
        guard !isAnalyzingAI else { return }
        isAnalyzingAI = true
        aiAnalysis = ""
        aiUsage = nil
        aiError = nil

        Task { @MainActor in
            do {
                let provider = try AIProviderFactory.create()

                var prompt = "Analyze this macOS unified log entry and explain what it means, whether it indicates a problem, and what action (if any) the user should take.\n\n"
                prompt += "## Entry\n"
                prompt += "- Timestamp: \(entry.timestamp)\n"
                prompt += "- Level: \(entry.level.rawValue)\n"
                prompt += "- Process: \(entry.processName) (PID: \(entry.processID))\n"
                prompt += "- Subsystem: \(entry.subsystem)\n"
                prompt += "- Category: \(entry.category)\n"
                prompt += "- Sender: \(entry.senderName)\n"
                prompt += "- Message: \(entry.eventMessage)\n\n"

                prompt += "## Context\n"
                prompt += "- Process type: \(processClassification.rawValue)\n"
                prompt += "- Subsystem error rate: \(String(format: "%.1f", subsystemErrorRate * 100))% (\(subsystemErrorCount)/\(subsystemTotalCount))\n"
                prompt += "- This message pattern appears \(messageFrequency) times\n"
                prompt += "- \(temporalNeighbors.count) entries within ±5s\n\n"

                if !temporalNeighbors.isEmpty {
                    prompt += "## Nearby entries (±5s):\n"
                    for neighbor in temporalNeighbors.prefix(20) {
                        prompt += "[\(neighbor.level.rawValue)] \(neighbor.processName)/\(neighbor.subsystem): \(neighbor.eventMessage.prefix(200))\n"
                    }
                }

                let messages = [
                    AIMessage(role: .system, content: PromptTemplates.logAnalysisSystem),
                    AIMessage(role: .user, content: prompt),
                ]
                let response = try await provider.complete(messages: messages)
                aiAnalysis = response.content
                aiUsage = response.usage
                isAnalyzingAI = false
            } catch {
                aiError = error.localizedDescription
                isAnalyzingAI = false
            }
        }
    }

    // MARK: - Helpers

    private func classifyProcess(_ path: String) -> ProcessClassification {
        let systemPrefixes = [
            "/usr/libexec/", "/usr/sbin/", "/usr/bin/",
            "/System/Library/CoreServices/", "/sbin/",
            "/System/Library/PrivateFrameworks/",
        ]
        let frameworkPrefixes = [
            "/System/Library/Frameworks/",
            "/System/Library/Extensions/",
            "/Library/Apple/",
        ]
        let appPrefixes = [
            "/System/Applications/",
            "/Applications/",
        ]

        for prefix in systemPrefixes {
            if path.hasPrefix(prefix) { return .appleSystem }
        }
        for prefix in frameworkPrefixes {
            if path.hasPrefix(prefix) { return .appleFramework }
        }
        for prefix in appPrefixes {
            if path.hasPrefix(prefix) {
                return path.contains("/Apple/") || path.contains("com.apple") ? .appleSystem : .thirdParty
            }
        }
        if path.hasPrefix("/System/") { return .appleSystem }
        return .userApp
    }

    private func normalizeMessage(_ message: String) -> String {
        var result = message
        result = result.replacingOccurrences(
            of: "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}",
            with: "<UUID>", options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "0x[0-9a-fA-F]+", with: "<HEX>", options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "\\b\\d{4,}\\b", with: "<NUM>", options: .regularExpression
        )
        return result
    }
}
