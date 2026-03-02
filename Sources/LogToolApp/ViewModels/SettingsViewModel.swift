import Foundation
import LogToolCore
import Observation

@Observable
final class SettingsViewModel {
    // General
    var defaultTimeRange: String = "5m"
    var maxEntries: String = "5000"

    // AI
    var selectedProvider: String = ""
    var claudeModel: String = "claude-sonnet-4-20250514"
    var openaiModel: String = "gpt-4o"
    var ollamaModel: String = "llama3.1"
    var ollamaURL: String = "http://localhost:11434"

    // Keys
    var claudeAPIKey: String = ""
    var openAIAPIKey: String = ""
    var claudeKeyStored = false
    var openAIKeyStored = false

    var statusMessage: String?

    private let config = Configuration.shared
    private let keychain = KeychainHelper()

    init() {
        loadSettings()
    }

    func loadSettings() {
        let values = config.load()
        selectedProvider = values.aiProvider ?? ""
        defaultTimeRange = values.defaultTimeRange ?? "5m"
        claudeModel = values.claudeModel ?? "claude-sonnet-4-20250514"
        openaiModel = values.openaiModel ?? "gpt-4o"
        ollamaModel = values.ollamaModel ?? "llama3.1"
        ollamaURL = values.ollamaURL ?? "http://localhost:11434"

        claudeKeyStored = keychain.exists(key: KeychainHelper.claudeAPIKey)
        openAIKeyStored = keychain.exists(key: KeychainHelper.openAIAPIKey)

        if let max = values.custom["max-entries"] {
            maxEntries = max
        }
    }

    func saveSettings() {
        do {
            var values = config.load()
            values.aiProvider = selectedProvider.isEmpty ? nil : selectedProvider
            values.defaultTimeRange = defaultTimeRange
            values.claudeModel = claudeModel
            values.openaiModel = openaiModel
            values.ollamaModel = ollamaModel
            values.ollamaURL = ollamaURL
            values.custom["max-entries"] = maxEntries
            try config.save(values)
            statusMessage = "Settings saved."
        } catch {
            statusMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    func saveCaudeKey() {
        guard !claudeAPIKey.isEmpty else { return }
        do {
            try keychain.store(key: KeychainHelper.claudeAPIKey, value: claudeAPIKey)
            claudeAPIKey = ""
            claudeKeyStored = true
            statusMessage = "Claude API key stored in Keychain."
        } catch {
            statusMessage = "Failed to store key: \(error.localizedDescription)"
        }
    }

    func saveOpenAIKey() {
        guard !openAIAPIKey.isEmpty else { return }
        do {
            try keychain.store(key: KeychainHelper.openAIAPIKey, value: openAIAPIKey)
            openAIAPIKey = ""
            openAIKeyStored = true
            statusMessage = "OpenAI API key stored in Keychain."
        } catch {
            statusMessage = "Failed to store key: \(error.localizedDescription)"
        }
    }

    func deleteCaudeKey() {
        do {
            try keychain.delete(key: KeychainHelper.claudeAPIKey)
            claudeKeyStored = false
            statusMessage = "Claude API key removed."
        } catch {
            statusMessage = "Failed to delete key: \(error.localizedDescription)"
        }
    }

    func deleteOpenAIKey() {
        do {
            try keychain.delete(key: KeychainHelper.openAIAPIKey)
            openAIKeyStored = false
            statusMessage = "OpenAI API key removed."
        } catch {
            statusMessage = "Failed to delete key: \(error.localizedDescription)"
        }
    }
}
