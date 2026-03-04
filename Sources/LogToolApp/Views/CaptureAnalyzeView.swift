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
        .sheet(isPresented: $viewModel.showDrillDown) {
            captureDrillDownSheet
        }
        .sheet(item: $viewModel.selectedAnomaly) { anomaly in
            AnomalyDetailView(anomaly: anomaly, entries: viewModel.entries)
        }
    }

    // MARK: - Drill-Down Sheet

    private var captureDrillDownSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text(viewModel.drillDownTitle)
                    .font(.headline)
                Spacer()
                Text("\(viewModel.drillDownEntries.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Done") {
                    viewModel.showDrillDown = false
                }
            }
            .padding()

            Divider()

            VSplitView {
                Table(viewModel.drillDownEntries, selection: $viewModel.selectedEntryID) {
                    TableColumn("Time") { entry in
                        Text(formatTime(entry))
                            .font(.caption.monospaced())
                    }
                    .width(min: 85, ideal: 95)

                    TableColumn("Level") { entry in
                        LevelBadge(level: entry.level)
                    }
                    .width(min: 60, ideal: 70)

                    TableColumn("Process") { entry in
                        Text(entry.processName)
                            .font(.caption).lineLimit(1)
                    }
                    .width(min: 80, ideal: 110)

                    TableColumn("Subsystem") { entry in
                        Text(entry.subsystem)
                            .font(.caption).lineLimit(1)
                    }
                    .width(min: 120, ideal: 200)

                    TableColumn("Message") { entry in
                        Text(entry.eventMessage)
                            .font(.caption).lineLimit(1)
                    }
                    .width(min: 200)
                }

                Group {
                    if let selected = viewModel.selectedEntry {
                        EntryInspectorView(entry: selected, siblings: viewModel.drillDownEntries)
                    } else {
                        Text("Select an entry to inspect")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(minHeight: 150, idealHeight: 250)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }

    private func formatTime(_ entry: LogEntry) -> String {
        guard let date = entry.date else { return entry.timestamp }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
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
            // Stat cards — clickable
            HStack(spacing: 12) {
                ClickableStatCard(title: "Total Entries", value: "\(viewModel.totalEntries)", icon: "doc.text", color: .blue, action: viewModel.drillIntoAll)
                ClickableStatCard(title: "Errors / Faults", value: "\(viewModel.errorFaultCount)", icon: "exclamationmark.triangle", color: .red, action: viewModel.drillIntoErrors)
                ClickableStatCard(title: "Subsystems", value: "\(viewModel.uniqueSubsystemCount)", icon: "square.grid.2x2", color: .purple, action: viewModel.drillIntoAll)
                ClickableStatCard(title: "Processes", value: "\(viewModel.uniqueProcessCount)", icon: "gearshape.2", color: .green, action: viewModel.drillIntoAll)
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
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .onTapGesture { location in
                                guard let level: String = proxy.value(atX: location.x) else { return }
                                if let matched = LogLevel.allCases.first(where: {
                                    $0.rawValue.capitalized == level
                                }) {
                                    viewModel.drillIntoLevel(matched)
                                }
                            }
                    }
                }
                .frame(height: 200)
                .padding(.vertical, 8)
            }
            .padding(.horizontal)

            HStack(alignment: .top, spacing: 20) {
                GroupBox("Top 5 Subsystems") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(viewModel.topSubsystems.enumerated()), id: \.offset) { _, item in
                            ClickableListRow(name: item.name, count: item.count) {
                                viewModel.drillIntoSubsystem(item.name)
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
                            ClickableListRow(name: item.name, count: item.count) {
                                viewModel.drillIntoProcess(item.name)
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
                    Button {
                        viewModel.selectedAnomaly = anomaly
                    } label: {
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
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
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
