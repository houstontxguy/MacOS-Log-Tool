import SwiftUI
import LogToolCore

struct AnalysisView: View {
    @State private var viewModel = AnalysisViewModel()
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.isAIConfigured {
                ContentUnavailableView {
                    Label("AI Not Configured", systemImage: "brain")
                } description: {
                    Text("Configure an AI provider in Settings (Cmd+,) to use AI-powered analysis.")
                }
            } else {
                TabView(selection: $selectedTab) {
                    nlQueryTab
                        .tabItem { Label("NL Query", systemImage: "text.magnifyingglass") }
                        .tag(0)

                    logAnalysisTab
                        .tabItem { Label("Log Analysis", systemImage: "wand.and.stars") }
                        .tag(1)
                }
            }
        }
        .navigationTitle("AI Analysis")
    }

    // MARK: - NL Query Tab

    private var nlQueryTab: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                TextField("Describe what you're looking for...", text: $viewModel.nlQuery)
                    .textFieldStyle(.roundedBorder)

                Button(action: viewModel.runNLQuery) {
                    if viewModel.isQuerying {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Query", systemImage: "paperplane")
                    }
                }
                .disabled(viewModel.nlQuery.isEmpty || viewModel.isQuerying)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()

            if let error = viewModel.errorMessage, selectedTab == 0 {
                errorBanner(error)
            }

            if !viewModel.generatedPredicate.isEmpty {
                HStack {
                    Text("Generated predicate:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.generatedPredicate)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            if !viewModel.queryResults.isEmpty {
                List(viewModel.queryResults) { entry in
                    LogEntryRow(entry: entry)
                }
                .listStyle(.plain)
            } else if !viewModel.isQuerying && !viewModel.generatedPredicate.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("The generated predicate returned no log entries.")
                )
            } else {
                Spacer()
            }
        }
    }

    // MARK: - Log Analysis Tab

    private var logAnalysisTab: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "gearshape.2")
                        .foregroundStyle(.secondary)
                    TextField("Process", text: $viewModel.analysisProcess)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                }

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    TextField("e.g. 5m", text: $viewModel.analysisTimeRange)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }

                TextField("Context (optional)", text: $viewModel.analysisContext)
                    .textFieldStyle(.roundedBorder)

                Button(action: viewModel.runAnalysis) {
                    if viewModel.isAnalyzing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Analyze", systemImage: "wand.and.stars")
                    }
                }
                .disabled(viewModel.isAnalyzing)
            }
            .padding()

            if let error = viewModel.errorMessage, selectedTab == 1 {
                errorBanner(error)
            }

            if !viewModel.analysisResponse.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(viewModel.analysisResponse)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let usage = viewModel.analysisUsage {
                            Divider()
                            HStack {
                                Text("Tokens: \(usage.inputTokens) in / \(usage.outputTokens) out")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
            } else {
                Spacer()
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(.orange.opacity(0.1))
    }
}
