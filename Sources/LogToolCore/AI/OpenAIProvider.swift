import Foundation

/// OpenAI GPT API provider.
public struct OpenAIProvider: AIProvider {
    public let name = "OpenAI"
    public let supportsToolUse = true
    public let maxContextTokens = 128_000

    private let apiKey: String
    private let model: String
    private let baseURL: String

    public init(apiKey: String, model: String = "gpt-4o", baseURL: String = "https://api.openai.com") {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
    }

    public func complete(messages: [AIMessage], tools: [AITool]? = nil) async throws -> AIResponse {
        let url = URL(string: "\(baseURL)/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "authorization")

        var body: [String: Any] = [
            "model": model,
            "messages": messages.map { msg -> [String: Any] in
                ["role": msg.role.rawValue, "content": msg.content]
            },
        ]

        if let tools, !tools.isEmpty {
            body["tools"] = tools.map { tool -> [String: Any] in
                var fn: [String: Any] = [
                    "name": tool.name,
                    "description": tool.description,
                ]
                if let schema = try? JSONSerialization.jsonObject(with: Data(tool.parameters.utf8)) {
                    fn["parameters"] = schema
                }
                return ["type": "function", "function": fn]
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
        guard let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any] else {
            return AIResponse(content: "", finishReason: nil)
        }

        let content = message["content"] as? String ?? ""
        let finishReason = first["finish_reason"] as? String

        var toolCalls: [AIResponse.ToolCall] = []
        if let tcs = message["tool_calls"] as? [[String: Any]] {
            for tc in tcs {
                guard let id = tc["id"] as? String,
                      let fn = tc["function"] as? [String: Any],
                      let name = fn["name"] as? String,
                      let args = fn["arguments"] as? String else { continue }
                toolCalls.append(AIResponse.ToolCall(id: id, name: name, arguments: args))
            }
        }

        var usage: AIResponse.Usage?
        if let usageDict = json["usage"] as? [String: Any] {
            let prompt = usageDict["prompt_tokens"] as? Int ?? 0
            let completion = usageDict["completion_tokens"] as? Int ?? 0
            usage = AIResponse.Usage(inputTokens: prompt, outputTokens: completion)
        }

        return AIResponse(
            content: content,
            toolCalls: toolCalls.isEmpty ? nil : toolCalls,
            finishReason: finishReason,
            usage: usage
        )
    }
}
