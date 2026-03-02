import Foundation

/// Anthropic Claude API provider.
public struct ClaudeProvider: AIProvider {
    public let name = "Claude"
    public let supportsToolUse = true
    public let maxContextTokens = 200_000

    private let apiKey: String
    private let model: String
    private let baseURL: String

    public init(apiKey: String, model: String = "claude-sonnet-4-20250514", baseURL: String = "https://api.anthropic.com") {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
    }

    public func complete(messages: [AIMessage], tools: [AITool]? = nil) async throws -> AIResponse {
        let url = URL(string: "\(baseURL)/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        var body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
        ]

        // Handle system message separately (Claude API format)
        var apiMessages: [[String: Any]] = []
        var systemPrompt: String?

        for msg in messages {
            if msg.role == .system {
                systemPrompt = msg.content
            } else {
                apiMessages.append([
                    "role": msg.role.rawValue,
                    "content": msg.content,
                ])
            }
        }

        body["messages"] = apiMessages
        if let system = systemPrompt {
            body["system"] = system
        }

        // Add tools if provided
        if let tools, !tools.isEmpty {
            body["tools"] = tools.map { tool -> [String: Any] in
                var toolDict: [String: Any] = [
                    "name": tool.name,
                    "description": tool.description,
                ]
                if let schema = try? JSONSerialization.jsonObject(with: Data(tool.parameters.utf8)) {
                    toolDict["input_schema"] = schema
                }
                return toolDict
            }
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.requestFailed("Invalid response type")
        }

        if httpResponse.statusCode == 429 {
            throw AIProviderError.rateLimited
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIProviderError.requestFailed("HTTP \(httpResponse.statusCode): \(errorBody)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIProviderError.invalidResponse("Cannot parse response JSON")
        }

        return parseResponse(json)
    }

    public func stream(messages: [AIMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let response = try await complete(messages: messages)
                    continuation.yield(response.content)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func parseResponse(_ json: [String: Any]) -> AIResponse {
        var content = ""
        var toolCalls: [AIResponse.ToolCall] = []

        if let contentBlocks = json["content"] as? [[String: Any]] {
            for block in contentBlocks {
                if let type = block["type"] as? String {
                    if type == "text", let text = block["text"] as? String {
                        content += text
                    } else if type == "tool_use",
                              let id = block["id"] as? String,
                              let name = block["name"] as? String,
                              let input = block["input"] {
                        if let inputData = try? JSONSerialization.data(withJSONObject: input),
                           let inputStr = String(data: inputData, encoding: .utf8) {
                            toolCalls.append(AIResponse.ToolCall(id: id, name: name, arguments: inputStr))
                        }
                    }
                }
            }
        }

        let stopReason = json["stop_reason"] as? String
        var usage: AIResponse.Usage?
        if let usageDict = json["usage"] as? [String: Any] {
            let input = usageDict["input_tokens"] as? Int ?? 0
            let output = usageDict["output_tokens"] as? Int ?? 0
            usage = AIResponse.Usage(inputTokens: input, outputTokens: output)
        }

        return AIResponse(
            content: content,
            toolCalls: toolCalls.isEmpty ? nil : toolCalls,
            finishReason: stopReason,
            usage: usage
        )
    }
}
