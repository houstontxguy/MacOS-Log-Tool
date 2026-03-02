import SwiftUI
import LogToolCore

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gear") }

            aiTab
                .tabItem { Label("AI", systemImage: "brain") }

            keysTab
                .tabItem { Label("API Keys", systemImage: "key") }

            aboutTab
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 480, height: 360)
    }

    // MARK: - General

    private var generalTab: some View {
        Form {
            TextField("Default time range:", text: $viewModel.defaultTimeRange)
                .help("Duration like 5m, 1h, 30s, 2d")

            TextField("Max entries:", text: $viewModel.maxEntries)
                .help("Maximum log entries to fetch per query")

            HStack {
                Spacer()
                Button("Save") {
                    viewModel.saveSettings()
                }
            }

            if let status = viewModel.statusMessage {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // MARK: - AI

    private var aiTab: some View {
        Form {
            Picker("AI Provider:", selection: $viewModel.selectedProvider) {
                Text("None").tag("")
                Divider()
                Text("Claude").tag("claude")
                Text("OpenAI").tag("openai")
                Text("Ollama").tag("ollama")
            }

            switch viewModel.selectedProvider {
            case "claude":
                TextField("Claude model:", text: $viewModel.claudeModel)
            case "openai":
                TextField("OpenAI model:", text: $viewModel.openaiModel)
            case "ollama":
                TextField("Ollama model:", text: $viewModel.ollamaModel)
                TextField("Ollama URL:", text: $viewModel.ollamaURL)
            default:
                EmptyView()
            }

            HStack {
                Spacer()
                Button("Save") {
                    viewModel.saveSettings()
                }
            }

            if let status = viewModel.statusMessage {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // MARK: - API Keys

    private var keysTab: some View {
        Form {
            Section("Claude API Key") {
                if viewModel.claudeKeyStored {
                    HStack {
                        Label("Key stored in Keychain", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Spacer()
                        Button("Remove", role: .destructive) {
                            viewModel.deleteCaudeKey()
                        }
                    }
                } else {
                    HStack {
                        SecureField("sk-ant-...", text: $viewModel.claudeAPIKey)
                        Button("Save") {
                            viewModel.saveCaudeKey()
                        }
                        .disabled(viewModel.claudeAPIKey.isEmpty)
                    }
                }
            }

            Section("OpenAI API Key") {
                if viewModel.openAIKeyStored {
                    HStack {
                        Label("Key stored in Keychain", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Spacer()
                        Button("Remove", role: .destructive) {
                            viewModel.deleteOpenAIKey()
                        }
                    }
                } else {
                    HStack {
                        SecureField("sk-...", text: $viewModel.openAIAPIKey)
                        Button("Save") {
                            viewModel.saveOpenAIKey()
                        }
                        .disabled(viewModel.openAIAPIKey.isEmpty)
                    }
                }
            }

            if let status = viewModel.statusMessage {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // MARK: - About

    private var aboutTab: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Log Tool")
                .font(.title)

            Text("macOS Unified Log Analyzer")
                .foregroundStyle(.secondary)

            Text("Built with SwiftUI and LogToolCore")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
