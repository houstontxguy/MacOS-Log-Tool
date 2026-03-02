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
                        // Top subsystems
                        GroupBox("Top Subsystems") {
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
                                    Text("No data")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        // Top processes
                        GroupBox("Top Processes") {
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
                                    Text("No data")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal)

                    // Anomalies
                    if !viewModel.anomalies.isEmpty {
                        GroupBox("Anomalies Detected") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(viewModel.anomalies.enumerated()), id: \.offset) { _, anomaly in
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
                                    }
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
