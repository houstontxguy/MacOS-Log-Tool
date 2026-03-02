import ArgumentParser
import Foundation
import LogToolCore

struct ConfigCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "Manage logtool configuration and API keys.",
        subcommands: [
            GetSubcommand.self,
            SetSubcommand.self,
            ListSubcommand.self,
            SetKeySubcommand.self,
            RemoveKeySubcommand.self,
            PathSubcommand.self,
        ]
    )
}

extension ConfigCommand {
    struct GetSubcommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "get",
            abstract: "Get a configuration value."
        )

        @Argument(help: "Configuration key.")
        var key: String

        func run() throws {
            let config = Configuration.shared
            if let value = config.get(key) {
                print(value)
            } else {
                print("Not set")
            }
        }
    }

    struct SetSubcommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "set",
            abstract: "Set a configuration value."
        )

        @Argument(help: "Configuration key.")
        var key: String

        @Argument(help: "Value to set.")
        var value: String

        func run() throws {
            let config = Configuration.shared
            try config.set(key, value: value)
            print("Set \(key) = \(value)")
        }
    }

    struct ListSubcommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "list",
            abstract: "List all configuration values."
        )

        func run() throws {
            let config = Configuration.shared
            let values = config.listAll()

            if values.isEmpty {
                print("No configuration values set.")
                print("")
                print("Available keys:")
                print("  ai-provider       AI backend: claude, openai, ollama")
                print("  default-format    Output format: table, json, csv")
                print("  default-time-range  Default time range (e.g., 5m)")
                print("  claude-model      Claude model name")
                print("  openai-model      OpenAI model name")
                print("  ollama-url        Ollama server URL")
                print("  ollama-model      Ollama model name")
            } else {
                for (key, value) in values {
                    print("\(key.padding(toLength: 22, withPad: " ", startingAt: 0)) \(value)")
                }
            }

            // Show API key status
            let keychain = KeychainHelper()
            print("")
            print("API Keys:")
            let claudeStatus = keychain.exists(key: KeychainHelper.claudeAPIKey) ? "configured" : "not set"
            let openaiStatus = keychain.exists(key: KeychainHelper.openAIAPIKey) ? "configured" : "not set"
            print("  Claude:  \(claudeStatus)")
            print("  OpenAI:  \(openaiStatus)")
        }
    }

    struct SetKeySubcommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "set-key",
            abstract: "Store an API key in the macOS Keychain."
        )

        @Argument(help: "Provider: claude, openai.")
        var provider: String

        @Argument(help: "API key value.")
        var apiKey: String

        func run() throws {
            let keychain = KeychainHelper()
            let keychainKey: String
            switch provider.lowercased() {
            case "claude":
                keychainKey = KeychainHelper.claudeAPIKey
            case "openai":
                keychainKey = KeychainHelper.openAIAPIKey
            default:
                print("Unknown provider: \(provider). Use: claude, openai")
                throw ExitCode.failure
            }

            try keychain.store(key: keychainKey, value: apiKey)
            print("API key for \(provider) stored in Keychain.")
        }
    }

    struct RemoveKeySubcommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "remove-key",
            abstract: "Remove an API key from the macOS Keychain."
        )

        @Argument(help: "Provider: claude, openai.")
        var provider: String

        func run() throws {
            let keychain = KeychainHelper()
            let keychainKey: String
            switch provider.lowercased() {
            case "claude":
                keychainKey = KeychainHelper.claudeAPIKey
            case "openai":
                keychainKey = KeychainHelper.openAIAPIKey
            default:
                print("Unknown provider: \(provider). Use: claude, openai")
                throw ExitCode.failure
            }

            try keychain.delete(key: keychainKey)
            print("API key for \(provider) removed from Keychain.")
        }
    }

    struct PathSubcommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "path",
            abstract: "Show the configuration directory path."
        )

        func run() throws {
            let config = Configuration.shared
            print(config.directory.path)
        }
    }
}
