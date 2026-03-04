import Foundation
import LogToolCore
import Observation

enum HealthSeverity: Int, Comparable {
    case ok = 0
    case info = 1
    case warning = 2
    case critical = 3

    static func < (lhs: HealthSeverity, rhs: HealthSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .ok: return "OK"
        case .info: return "Info"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }

    var icon: String {
        switch self {
        case .ok: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}

struct HealthIssue: Identifiable {
    let id = UUID()
    let area: String
    let icon: String
    let severity: HealthSeverity
    let title: String
    let description: String
    let errorCount: Int
    let presetID: String
}

@Observable
final class HealthCheckViewModel {
    var issues: [HealthIssue] = []
    var isScanning = false
    var scanProgress: Double = 0
    var scanComplete = false
    var errorMessage: String?
    var minutes: Int = 15

    // AI
    var aiSummary = ""
    var isAnalyzingAI = false
    var aiUsage: AIResponse.Usage?

    private let collector = LogCollector()
    private let detector = AnomalyDetector()

    var overallSeverity: HealthSeverity {
        issues.map(\.severity).max() ?? .ok
    }

    var isAIConfigured: Bool {
        Configuration.shared.load().aiProvider != nil
    }

    var sortedIssues: [HealthIssue] {
        issues.sorted { $0.severity > $1.severity }
    }

    func scan() {
        guard !isScanning else { return }
        isScanning = true
        scanComplete = false
        issues = []
        scanProgress = 0
        errorMessage = nil
        aiSummary = ""
        aiUsage = nil

        Task { @MainActor in
            let presets = DiagnosticPreset.allPresets
            for (index, preset) in presets.enumerated() {
                do {
                    let filter = preset.buildFilter(lastMinutes: minutes)
                    let entries = try await collector.collect(filter: filter, maxEntries: 5000)
                    let anomalies = detector.detect(entries: entries)

                    let errorCount = entries.filter { $0.level >= .error }.count
                    let faultCount = entries.filter { $0.level >= .fault }.count
                    let anomalyCount = anomalies.count

                    let severity: HealthSeverity
                    let title: String
                    let description: String

                    if faultCount > 5 || (anomalies.contains { $0.severity >= 0.8 }) {
                        severity = .critical
                        title = "Critical issues detected"
                        description = "\(faultCount) faults, \(errorCount) errors, \(anomalyCount) anomalies in \(entries.count) entries"
                    } else if errorCount > 10 || anomalyCount > 2 {
                        severity = .warning
                        title = "Issues detected"
                        description = "\(errorCount) errors, \(anomalyCount) anomalies in \(entries.count) entries"
                    } else if errorCount > 0 || anomalyCount > 0 {
                        severity = .info
                        title = "Minor activity"
                        description = "\(errorCount) errors, \(anomalyCount) anomalies in \(entries.count) entries"
                    } else {
                        severity = .ok
                        title = entries.isEmpty ? "No recent activity" : "Normal"
                        description = "\(entries.count) entries, no issues"
                    }

                    issues.append(HealthIssue(
                        area: preset.name,
                        icon: preset.icon,
                        severity: severity,
                        title: title,
                        description: description,
                        errorCount: errorCount,
                        presetID: preset.id
                    ))
                } catch {
                    issues.append(HealthIssue(
                        area: preset.name,
                        icon: preset.icon,
                        severity: .info,
                        title: "Scan failed",
                        description: error.localizedDescription,
                        errorCount: 0,
                        presetID: preset.id
                    ))
                }

                scanProgress = Double(index + 1) / Double(presets.count)
            }

            isScanning = false
            scanComplete = true
        }
    }

    func runAISummary() {
        guard !isAnalyzingAI, !issues.isEmpty else { return }
        isAnalyzingAI = true
        errorMessage = nil
        aiSummary = ""
        aiUsage = nil

        Task { @MainActor in
            do {
                let provider = try AIProviderFactory.create()

                var summary = "System Health Check Results (last \(minutes) minutes):\n\n"
                for issue in sortedIssues {
                    summary += "[\(issue.severity.label.uppercased())] \(issue.area): \(issue.title) - \(issue.description)\n"
                }

                let messages = [
                    AIMessage(role: .system, content: PromptTemplates.logAnalysisSystem),
                    AIMessage(
                        role: .user,
                        content: """
                        Analyze this macOS system health check and provide a brief, \
                        actionable summary. Focus on the most important issues and \
                        what the user should investigate first.

                        \(summary)
                        """
                    ),
                ]
                let response = try await provider.complete(messages: messages)
                aiSummary = response.content
                aiUsage = response.usage
                isAnalyzingAI = false
            } catch {
                errorMessage = error.localizedDescription
                isAnalyzingAI = false
            }
        }
    }
}
