import SwiftUI
import Charts
import LogToolCore

struct StatsView: View {
    @State private var viewModel = StatsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Controls
                HStack {
                    HStack(spacing: 4) {
                        Text("Time range:")
                        TextField("e.g. 5m, 1h", text: $viewModel.timeRange)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }

                    Button(action: viewModel.fetch) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .keyboardShortcut(.return, modifiers: .command)

                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Spacer()

                    Text("\(viewModel.totalEntries) total entries")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .padding()
                }

                if !viewModel.levelCounts.isEmpty {
                    // Stat cards
                    HStack(spacing: 12) {
                        ClickableStatCard(
                            title: "Total",
                            value: "\(viewModel.totalEntries)",
                            icon: "doc.text",
                            color: .blue,
                            action: viewModel.drillIntoAll
                        )
                        ClickableStatCard(
                            title: "Errors",
                            value: "\(viewModel.errorCount)",
                            icon: "exclamationmark.triangle",
                            color: .red,
                            action: viewModel.drillIntoErrors
                        )
                        ClickableStatCard(
                            title: "Subsystems",
                            value: "\(viewModel.topSubsystems.count)",
                            icon: "square.grid.2x2",
                            color: .purple,
                            action: viewModel.drillIntoAll
                        )
                        ClickableStatCard(
                            title: "Processes",
                            value: "\(viewModel.topProcesses.count)",
                            icon: "gearshape.2",
                            color: .green,
                            action: viewModel.drillIntoAll
                        )
                    }
                    .padding(.horizontal)

                    // Level chart with tap
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
                        // Top subsystems — clickable
                        GroupBox("Top Subsystems") {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(Array(viewModel.topSubsystems.enumerated()), id: \.offset) { _, item in
                                    ClickableListRow(name: item.name, count: item.count) {
                                        viewModel.drillIntoSubsystem(item.name)
                                    }
                                }
                                if viewModel.topSubsystems.isEmpty {
                                    Text("No data")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        // Top processes — clickable
                        GroupBox("Top Processes") {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(Array(viewModel.topProcesses.enumerated()), id: \.offset) { _, item in
                                    ClickableListRow(name: item.name, count: item.count) {
                                        viewModel.drillIntoProcess(item.name)
                                    }
                                }
                                if viewModel.topProcesses.isEmpty {
                                    Text("No data")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal)

                    // Recent errors
                    if !viewModel.recentErrors.isEmpty {
                        GroupBox("Recent Errors (\(viewModel.recentErrors.count))") {
                            VStack(spacing: 2) {
                                ForEach(viewModel.recentErrors) { entry in
                                    Button {
                                        viewModel.drillDownEntries = [entry]
                                        viewModel.drillDownTitle = "Error Entry"
                                        viewModel.selectedEntryID = entry.id
                                        viewModel.showDrillDown = true
                                    } label: {
                                        LogEntryRow(entry: entry)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .padding(.horizontal)
                    }

                    // Anomalies — clickable
                    if !viewModel.anomalies.isEmpty {
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
                                                Text(anomaly.type.rawValue.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression).capitalized)
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
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Dashboard")
        .task {
            viewModel.fetch()
        }
        .sheet(isPresented: $viewModel.showDrillDown) {
            drillDownSheet
        }
        .sheet(item: $viewModel.selectedAnomaly) { anomaly in
            AnomalyDetailView(anomaly: anomaly, entries: viewModel.entries)
        }
    }

    // MARK: - Drill-Down Sheet

    private var drillDownSheet: some View {
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

    // MARK: - Helpers

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
