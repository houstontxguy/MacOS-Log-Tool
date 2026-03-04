import SwiftUI
import LogToolCore

struct CrashView: View {
    @State private var viewModel = CrashViewModel()

    var body: some View {
        HSplitView {
            // Crash list
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView("Loading crash reports...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.crashes.isEmpty {
                    ContentUnavailableView(
                        "No Crash Reports",
                        systemImage: "exclamationmark.triangle",
                        description: Text("No crash reports found in the standard directories.")
                    )
                } else {
                    List(viewModel.crashes, id: \.filePath, selection: Binding(
                        get: { viewModel.selectedCrash?.filePath },
                        set: { path in
                            if let path, let crash = viewModel.crashes.first(where: { $0.filePath == path }) {
                                viewModel.selectCrash(crash)
                            }
                        }
                    )) { crash in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(crash.processName)
                                .font(.headline)
                            Text(crash.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            if let time = crash.header.timestamp ?? crash.body.captureTime {
                                Text(time)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 2)
                        .tag(crash.filePath)
                    }
                    .listStyle(.sidebar)
                }
            }
            .frame(minWidth: 250, idealWidth: 300)

            // Detail
            VStack(spacing: 0) {
                if let crash = viewModel.selectedCrash {
                    // Action bar
                    HStack {
                        Button(action: viewModel.correlateLogs) {
                            if viewModel.isCorrelating {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("Correlate Logs", systemImage: "clock.arrow.2.circlepath")
                            }
                        }
                        .disabled(viewModel.isCorrelating || crash.date == nil)

                        Button(action: viewModel.analyzeWithAI) {
                            if viewModel.isAnalyzing {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("Analyze with AI", systemImage: "brain")
                            }
                        }
                        .disabled(viewModel.isAnalyzing)

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)

                    Divider()

                    // Crash detail + optional analysis
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            CrashDetailView(crash: crash)

                            if !viewModel.correlatedLogs.isEmpty {
                                GroupBox("Correlated Logs (\(viewModel.correlatedLogs.count))") {
                                    VStack(alignment: .leading, spacing: 0) {
                                        List(viewModel.correlatedLogs.prefix(100).map { $0 }, id: \.id, selection: $viewModel.selectedLogEntryID) { entry in
                                            LogEntryRow(entry: entry)
                                                .tag(entry.id)
                                        }
                                        .listStyle(.plain)
                                        .frame(height: min(CGFloat(viewModel.correlatedLogs.count) * 28, 300))

                                        if viewModel.correlatedLogs.count > 100 {
                                            Text("... \(viewModel.correlatedLogs.count - 100) more entries")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .padding(.top, 4)
                                        }
                                    }
                                }
                                .padding(.horizontal)

                                if let logEntry = viewModel.selectedLogEntry {
                                    GroupBox("Entry Inspector") {
                                        EntryInspectorView(entry: logEntry, siblings: viewModel.correlatedLogs)
                                            .frame(maxHeight: 400)
                                    }
                                    .padding(.horizontal)
                                }
                            }

                            if let analysis = viewModel.analysisResult {
                                GroupBox("AI Analysis") {
                                    Text(analysis)
                                        .font(.body)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Select a Crash Report",
                        systemImage: "doc.text",
                        description: Text("Choose a crash report from the list to view details.")
                    )
                }
            }
        }
        .navigationTitle("Crash Reports")
        .task {
            viewModel.loadCrashes()
        }
    }
}
