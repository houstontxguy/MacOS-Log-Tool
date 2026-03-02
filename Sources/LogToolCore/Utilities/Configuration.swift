import Foundation

/// Manages ~/.logtool/ configuration.
public final class Configuration: Sendable {
    public static let shared = Configuration()

    private let configDir: URL
    private let configFile: URL

    public init(baseDir: URL? = nil) {
        let base = baseDir ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".logtool")
        self.configDir = base
        self.configFile = base.appendingPathComponent("config.json")
    }

    /// Ensure the config directory exists.
    public func ensureDirectoryExists() throws {
        try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: configDir.appendingPathComponent("sessions"),
            withIntermediateDirectories: true
        )
    }

    /// The path to the config directory.
    public var directory: URL { configDir }

    /// The path to the SQLite database.
    public var databasePath: URL { configDir.appendingPathComponent("store.db") }

    /// The path to saved predicates.
    public var predicatesPath: URL { configDir.appendingPathComponent("predicates.json") }

    /// Load configuration values.
    public func load() -> ConfigValues {
        guard let data = try? Data(contentsOf: configFile),
              let values = try? JSONDecoder().decode(ConfigValues.self, from: data) else {
            return ConfigValues()
        }
        return values
    }

    /// Save configuration values.
    public func save(_ values: ConfigValues) throws {
        try ensureDirectoryExists()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(values)
        try data.write(to: configFile)
    }

    /// Get a single config value.
    public func get(_ key: String) -> String? {
        let values = load()
        switch key {
        case "ai-provider": return values.aiProvider
        case "default-format": return values.defaultFormat
        case "default-time-range": return values.defaultTimeRange
        case "ollama-url": return values.ollamaURL
        case "ollama-model": return values.ollamaModel
        case "claude-model": return values.claudeModel
        case "openai-model": return values.openaiModel
        default: return values.custom[key]
        }
    }

    /// Set a single config value.
    public func set(_ key: String, value: String) throws {
        var values = load()
        switch key {
        case "ai-provider": values.aiProvider = value
        case "default-format": values.defaultFormat = value
        case "default-time-range": values.defaultTimeRange = value
        case "ollama-url": values.ollamaURL = value
        case "ollama-model": values.ollamaModel = value
        case "claude-model": values.claudeModel = value
        case "openai-model": values.openaiModel = value
        default: values.custom[key] = value
        }
        try save(values)
    }

    /// Remove a config value.
    public func remove(_ key: String) throws {
        var values = load()
        switch key {
        case "ai-provider": values.aiProvider = nil
        case "default-format": values.defaultFormat = nil
        case "default-time-range": values.defaultTimeRange = nil
        case "ollama-url": values.ollamaURL = nil
        case "ollama-model": values.ollamaModel = nil
        case "claude-model": values.claudeModel = nil
        case "openai-model": values.openaiModel = nil
        default: values.custom.removeValue(forKey: key)
        }
        try save(values)
    }

    /// List all config values.
    public func listAll() -> [(key: String, value: String)] {
        let values = load()
        var result: [(String, String)] = []
        if let v = values.aiProvider { result.append(("ai-provider", v)) }
        if let v = values.defaultFormat { result.append(("default-format", v)) }
        if let v = values.defaultTimeRange { result.append(("default-time-range", v)) }
        if let v = values.ollamaURL { result.append(("ollama-url", v)) }
        if let v = values.ollamaModel { result.append(("ollama-model", v)) }
        if let v = values.claudeModel { result.append(("claude-model", v)) }
        if let v = values.openaiModel { result.append(("openai-model", v)) }
        for (k, v) in values.custom.sorted(by: { $0.key < $1.key }) {
            result.append((k, v))
        }
        return result
    }
}

/// Stored configuration values.
public struct ConfigValues: Codable, Sendable {
    public var aiProvider: String?
    public var defaultFormat: String?
    public var defaultTimeRange: String?
    public var ollamaURL: String?
    public var ollamaModel: String?
    public var claudeModel: String?
    public var openaiModel: String?
    public var custom: [String: String]

    public init() {
        self.custom = [:]
    }

    enum CodingKeys: String, CodingKey {
        case aiProvider = "ai_provider"
        case defaultFormat = "default_format"
        case defaultTimeRange = "default_time_range"
        case ollamaURL = "ollama_url"
        case ollamaModel = "ollama_model"
        case claudeModel = "claude_model"
        case openaiModel = "openai_model"
        case custom
    }
}
