import Foundation

/// Result from an AI-powered log analysis.
public struct AnalysisResult: Sendable {
    public let summary: String
    public let findings: [Finding]
    public let recommendations: [String]
    public let severity: Severity
    public let rawResponse: String?

    public init(
        summary: String,
        findings: [Finding],
        recommendations: [String],
        severity: Severity,
        rawResponse: String? = nil
    ) {
        self.summary = summary
        self.findings = findings
        self.recommendations = recommendations
        self.severity = severity
        self.rawResponse = rawResponse
    }

    /// A specific finding from log analysis.
    public struct Finding: Sendable {
        public let title: String
        public let description: String
        public let relatedEntries: [String]
        public let category: FindingCategory

        public init(title: String, description: String, relatedEntries: [String] = [], category: FindingCategory = .observation) {
            self.title = title
            self.description = description
            self.relatedEntries = relatedEntries
            self.category = category
        }
    }

    public enum FindingCategory: String, Sendable {
        case rootCause = "Root Cause"
        case symptom = "Symptom"
        case pattern = "Pattern"
        case anomaly = "Anomaly"
        case observation = "Observation"
    }

    public enum Severity: String, Sendable {
        case critical = "Critical"
        case warning = "Warning"
        case info = "Info"
        case ok = "OK"
    }
}

/// Messages exchanged with AI providers.
public struct AIMessage: Sendable {
    public let role: Role
    public let content: String

    public enum Role: String, Sendable {
        case system
        case user
        case assistant
    }

    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}

/// Response from an AI provider.
public struct AIResponse: Sendable {
    public let content: String
    public let toolCalls: [ToolCall]?
    public let finishReason: String?
    public let usage: Usage?

    public init(content: String, toolCalls: [ToolCall]? = nil, finishReason: String? = nil, usage: Usage? = nil) {
        self.content = content
        self.toolCalls = toolCalls
        self.finishReason = finishReason
        self.usage = usage
    }

    public struct ToolCall: Sendable {
        public let id: String
        public let name: String
        public let arguments: String

        public init(id: String, name: String, arguments: String) {
            self.id = id
            self.name = name
            self.arguments = arguments
        }
    }

    public struct Usage: Sendable {
        public let inputTokens: Int
        public let outputTokens: Int

        public init(inputTokens: Int, outputTokens: Int) {
            self.inputTokens = inputTokens
            self.outputTokens = outputTokens
        }
    }
}

/// Tool definition for AI providers.
public struct AITool: Sendable {
    public let name: String
    public let description: String
    public let parameters: String // JSON Schema as string

    public init(name: String, description: String, parameters: String) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}
