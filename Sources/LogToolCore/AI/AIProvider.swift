import Foundation

/// Protocol for pluggable AI backends.
public protocol AIProvider: Sendable {
    /// Display name of this provider.
    var name: String { get }

    /// Whether this provider supports tool-use / function calling.
    var supportsToolUse: Bool { get }

    /// Maximum context window in tokens.
    var maxContextTokens: Int { get }

    /// Send a completion request.
    func complete(messages: [AIMessage], tools: [AITool]?) async throws -> AIResponse

    /// Stream a response token-by-token.
    func stream(messages: [AIMessage]) -> AsyncThrowingStream<String, Error>
}

extension AIProvider {
    /// Convenience: complete without tools.
    public func complete(messages: [AIMessage]) async throws -> AIResponse {
        try await complete(messages: messages, tools: nil)
    }
}

/// Factory for creating AI providers from configuration.
public struct AIProviderFactory {
    public static func create(from config: Configuration = .shared) throws -> AIProvider {
        let values = config.load()
        let keychain = KeychainHelper()

        switch values.aiProvider?.lowercased() {
        case "claude":
            guard let apiKey = keychain.retrieve(key: KeychainHelper.claudeAPIKey) else {
                throw AIProviderError.missingAPIKey("Claude API key not found. Run: logtool config set-key claude <key>")
            }
            let model = values.claudeModel ?? "claude-sonnet-4-20250514"
            return ClaudeProvider(apiKey: apiKey, model: model)

        case "openai":
            guard let apiKey = keychain.retrieve(key: KeychainHelper.openAIAPIKey) else {
                throw AIProviderError.missingAPIKey("OpenAI API key not found. Run: logtool config set-key openai <key>")
            }
            let model = values.openaiModel ?? "gpt-4o"
            return OpenAIProvider(apiKey: apiKey, model: model)

        case "ollama":
            let url = values.ollamaURL ?? "http://localhost:11434"
            let model = values.ollamaModel ?? "llama3.1"
            return OllamaProvider(baseURL: url, model: model)

        case nil:
            throw AIProviderError.noProviderConfigured

        default:
            throw AIProviderError.unknownProvider(values.aiProvider ?? "")
        }
    }
}

/// Errors from AI provider operations.
public enum AIProviderError: Error, LocalizedError {
    case missingAPIKey(String)
    case noProviderConfigured
    case unknownProvider(String)
    case requestFailed(String)
    case invalidResponse(String)
    case rateLimited
    case contextTooLarge(Int, max: Int)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey(let msg): return msg
        case .noProviderConfigured: return "No AI provider configured. Run: logtool config set ai-provider <claude|openai|ollama>"
        case .unknownProvider(let name): return "Unknown AI provider: \(name). Use: claude, openai, or ollama"
        case .requestFailed(let msg): return "AI request failed: \(msg)"
        case .invalidResponse(let msg): return "Invalid AI response: \(msg)"
        case .rateLimited: return "Rate limited by AI provider. Please wait and try again."
        case .contextTooLarge(let size, let max): return "Context too large (\(size) tokens, max \(max)). Try narrowing your query."
        }
    }
}
