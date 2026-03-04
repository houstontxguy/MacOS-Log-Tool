import SwiftUI
import Charts
import LogToolCore

struct DiagnosticResultView: View {
    let preset: DiagnosticPreset
    @State private var viewModel: DiagnosticViewModel

    init(preset: DiagnosticPreset) {
        self.preset = preset
        self._viewModel = State(initialValue: DiagnosticViewModel(preset: preset))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                if let error = viewModel.errorMessage { errorBanner(error) }
                if viewModel.completed {
                    summarySection
                    if !viewModel.anomalies.isEmpty { anomaliesSection }
                    entriesSection
                    aiSection
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(preset.name)
        .task {
            viewModel.run()
        }
        .sheet(isPresented: $viewModel.showDrillDown) {
            diagnosticDrillDownSheet
        }
        .sheet(item: $viewModel.selectedAnomaly) { anomaly in
            AnomalyDetailView(anomaly: anomaly, entries: viewModel.entries)
        }
    }

    private var diagnosticDrillDownSheet: some View {
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

                    TableColumn("Message") { entry in
                        Text(entry.eventMessage)
                            .font(.caption).lineLimit(1)
                    }
                    .width(min: 200)
                }

                Group {
                    if let selected = viewModel.drillDownSelectedEntry {
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

    // MARK: - Header

    private var headerSection: some View {
        GroupBox {
            HStack(spacing: 16) {
                Image(systemName: preset.icon)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(.headline)
                    Text(presetDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("Last")
                    TextField("15", value: $viewModel.minutes, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                    Stepper("", value: $viewModel.minutes, in: 1...1440)
                        .labelsHidden()
                    Text("min")
                        .foregroundStyle(.secondary)
                }

                Button(action: viewModel.run) {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Re-run", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isLoading)
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ClickableStatCard(title: "Total", value: "\(viewModel.totalEntries)", icon: "doc.text", color: .blue, action: viewModel.drillIntoAll)
                ClickableStatCard(title: "Errors", value: "\(viewModel.errorFaultCount)", icon: "exclamationmark.triangle", color: .red, action: viewModel.drillIntoErrors)
                ClickableStatCard(title: "Anomalies", value: "\(viewModel.anomalies.count)", icon: "waveform.path.ecg", color: .purple, action: viewModel.drillIntoAll)
                ClickableStatCard(title: "Processes", value: "\(viewModel.uniqueProcessCount)", icon: "gearshape.2", color: .green, action: viewModel.drillIntoAll)
            }
            .padding(.horizontal)

            if !viewModel.levelCounts.isEmpty {
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
                    .frame(height: 160)
                    .padding(.vertical, 4)
                }
                .padding(.horizontal)
            }

            HStack(alignment: .top, spacing: 20) {
                GroupBox("Top Subsystems") {
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

                GroupBox("Top Processes") {
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

    // MARK: - Anomalies

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

    // MARK: - Entries

    private var entriesSection: some View {
        GroupBox("Log Entries (\(viewModel.filteredEntries.count))") {
            VStack(spacing: 0) {
                HStack {
                    TextField("Search entries...", text: $viewModel.searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 300)
                    Spacer()
                }
                .padding(.bottom, 8)

                if viewModel.filteredEntries.isEmpty {
                    Text("No entries match the search.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .padding()
                } else {
                    Table(viewModel.filteredEntries, selection: $viewModel.selectedEntryID) {
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

                        TableColumn("Message") { entry in
                            Text(entry.eventMessage)
                                .font(.caption).lineLimit(1)
                        }
                        .width(min: 200)
                    }
                    .frame(height: 300)
                }

                if let entry = viewModel.selectedEntry {
                    Divider()
                    EntryInspectorView(entry: entry, siblings: viewModel.filteredEntries)
                        .frame(height: 300)
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
    }

    // MARK: - AI

    private var aiSection: some View {
        GroupBox("AI Analysis") {
            VStack(alignment: .leading, spacing: 12) {
                if !viewModel.isAIConfigured {
                    HStack {
                        Image(systemName: "brain").foregroundStyle(.secondary)
                        Text("Configure an AI provider in Settings (Cmd+,) to enable AI analysis.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                } else {
                    HStack(spacing: 12) {
                        TextField("Context (optional)", text: $viewModel.aiContext)
                            .textFieldStyle(.roundedBorder)
                        Button(action: viewModel.runAIAnalysis) {
                            if viewModel.isAnalyzingAI {
                                ProgressView().controlSize(.small)
                            } else {
                                Label("Run AI Analysis", systemImage: "wand.and.stars")
                            }
                        }
                        .disabled(viewModel.isAnalyzingAI)
                    }

                    if !viewModel.aiResponse.isEmpty {
                        Divider()
                        Text(viewModel.aiResponse)
                            .font(.body).textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if let usage = viewModel.aiUsage {
                            Divider()
                            Text("Tokens: \(usage.inputTokens) in / \(usage.outputTokens) out")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private var presetDescription: String {
        var parts: [String] = []
        if !preset.subsystems.isEmpty {
            parts.append("Subsystems: \(preset.subsystems.joined(separator: ", "))")
        }
        if !preset.processes.isEmpty {
            parts.append("Processes: \(preset.processes.joined(separator: ", "))")
        }
        if !preset.keywords.isEmpty {
            parts.append("Keywords: \(preset.keywords.joined(separator: ", "))")
        }
        return parts.joined(separator: " | ")
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            Text(message).font(.caption)
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

    private func formatTime(_ entry: LogEntry) -> String {
        guard let date = entry.date else { return entry.timestamp }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}
