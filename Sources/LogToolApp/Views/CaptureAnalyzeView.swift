import SwiftUI
import Charts
import LogToolCore

struct CaptureAnalyzeView: View {
    @State private var viewModel = CaptureAnalyzeViewModel()
    @State private var showFilters = false
    @Environment(ActiveSubsystemPoller.self) private var poller: ActiveSubsystemPoller?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                captureSection

                if let error = viewModel.errorMessage {
                    errorBanner(error)
                }

                if viewModel.captureCompleted {
                    summarySection
                    exportSection
                    if !viewModel.anomalies.isEmpty {
                        anomaliesSection
                    }
                    aiAnalysisSection
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Capture & Analyze")
    }

    // MARK: - Capture Section

    private var captureSection: some View {
        GroupBox("Capture") {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("Last")
                        TextField("5", value: $viewModel.minutes, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        Stepper("", value: $viewModel.minutes, in: 1...1440)
                            .labelsHidden()
                        Text("minutes")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(action: viewModel.capture) {
                        if viewModel.isCapturing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Label("Capture Logs", systemImage: "arrow.down.doc")
                        }
                    }
                    .disabled(viewModel.isCapturing)
                    .keyboardShortcut(.return, modifiers: .command)

                    if viewModel.captureCompleted {
                        Button(action: viewModel.reset) {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                        }
                    }
                }

                DisclosureGroup("Filters", isExpanded: $showFilters) {
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text("Process:")
                                .foregroundStyle(.secondary)
                            SuggestionTextField(
                                placeholder: "e.g. Finder",
                                text: $viewModel.process,
                                suggestions: poller?.processSuggestions ?? DiagnosticPreset.commonProcesses
                            )
                            .frame(width: 160, height: 24)
                        }

                        HStack(spacing: 4) {
                            Text("Subsystem:")
                                .foregroundStyle(.secondary)
                            SuggestionTextField(
                                placeholder: "e.g. com.apple.bluetooth",
                                text: $viewModel.subsystem,
                                suggestions: poller?.subsystemSuggestions ?? DiagnosticPreset.commonSubsystems
                            )
                            .frame(width: 220, height: 24)
                        }

                        HStack(spacing: 4) {
                            Text("Level:")
                                .foregroundStyle(.secondary)
                            Picker("", selection: $viewModel.selectedLevel) {
                                Text("All").tag(LogLevel?.none)
                                ForEach(LogLevel.allCases, id: \.self) { level in
                                    Text(level.rawValue.capitalized).tag(LogLevel?.some(level))
                                }
                            }
                            .frame(width: 100)
                        }

                        Spacer()
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(spacing: 16) {
            // Stat cards
            HStack(spacing: 12) {
                statCard("Total Entries", value: "\(viewModel.totalEntries)", icon: "doc.text", color: .blue)
                statCard("Errors / Faults", value: "\(viewModel.errorFaultCount)", icon: "exclamationmark.triangle", color: .red)
                statCard("Subsystems", value: "\(viewModel.uniqueSubsystemCount)", icon: "square.grid.2x2", color: .purple)
                statCard("Processes", value: "\(viewModel.uniqueProcessCount)", icon: "gearshape.2", color: .green)
            }
            .padding(.horizontal)

            // Level chart
            GroupBox("Log Levels") {
                Chart(viewModel.levelCounts, id: \.level) { item in
                    BarMark(
                        x: .value("Level", item.level.rawValue.capitalized),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(item.level.color)
                }
                .frame(height: 200)
                .padding(.vertical, 8)
            }
            .padding(.horizontal)

            HStack(alignment: .top, spacing: 20) {
                GroupBox("Top 5 Subsystems") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(viewModel.topSubsystems.enumerated()), id: \.offset) { _, item in
                            HStack {
                                Text(item.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(item.count)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if viewModel.topSubsystems.isEmpty {
                            Text("No data").foregroundStyle(.secondary).font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }

                GroupBox("Top 5 Processes") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(viewModel.topProcesses.enumerated()), id: \.offset) { _, item in
                            HStack {
                                Text(item.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(item.count)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if viewModel.topProcesses.isEmpty {
                            Text("No data").foregroundStyle(.secondary).font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Export Section

    private var exportSection: some View {
        GroupBox("Export") {
            HStack(spacing: 12) {
                Text("\(viewModel.totalEntries) entries ready to export")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                Spacer()
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Button(action: { viewModel.saveToFile(format: format) }) {
                        Label("Save \(format.rawValue)", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Anomalies Section

    private var anomaliesSection: some View {
        GroupBox("Anomalies Detected") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(viewModel.anomalies.enumerated()), id: \.offset) { _, anomaly in
                    HStack(alignment: .top) {
                        Image(systemName: severityIcon(anomaly.severity))
                            .foregroundStyle(severityColor(anomaly.severity))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(anomaly.type.rawValue)
                                .font(.caption.bold())
                            Text(anomaly.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !anomaly.relatedSubsystems.isEmpty {
                                Text("Subsystems: \(anomaly.relatedSubsystems.joined(separator: ", "))")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
    }

    // MARK: - AI Analysis Section

    private var aiAnalysisSection: some View {
        GroupBox("AI Analysis") {
            VStack(alignment: .leading, spacing: 12) {
                if !viewModel.isAIConfigured {
                    HStack {
                        Image(systemName: "brain")
                            .foregroundStyle(.secondary)
                        Text("Configure an AI provider in Settings (Cmd+,) to enable AI analysis.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack(spacing: 12) {
                        TextField("Context (optional, e.g. investigating app crashes)", text: $viewModel.aiContext)
                            .textFieldStyle(.roundedBorder)

                        Button(action: viewModel.runAIAnalysis) {
                            if viewModel.isAnalyzingAI {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("Run AI Analysis", systemImage: "wand.and.stars")
                            }
                        }
                        .disabled(viewModel.isAnalyzingAI)
                    }

                    if !viewModel.aiResponse.isEmpty {
                        Divider()

                        Text(viewModel.aiResponse)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let usage = viewModel.aiUsage {
                            Divider()
                            HStack {
                                Text("Tokens: \(usage.inputTokens) in / \(usage.outputTokens) out")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func statCard(_ title: String, value: String, icon: String, color: Color) -> some View {
        GroupBox {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(value)
                    .font(.title.monospacedDigit().bold())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
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

    private func severityIcon(_ severity: Double) -> String {
        if severity >= 0.8 { return "exclamationmark.triangle.fill" }
        if severity >= 0.5 { return "exclamationmark.circle.fill" }
        return "info.circle.fill"
    }

    private func severityColor(_ severity: Double) -> Color {
        if severity >= 0.8 { return .red }
        if severity >= 0.5 { return .orange }
        return .yellow
    }
}
