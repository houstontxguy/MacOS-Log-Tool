import SwiftUI
import LogToolCore

struct HealthIssueDrillDownView: View {
    let issue: HealthIssue
    let scanResult: ScanResult

    @State private var selectedEntryID: UUID?
    @State private var selectedAnomaly: Anomaly?
    @State private var searchText = ""

    private var selectedEntry: LogEntry? {
        guard let id = selectedEntryID else { return nil }
        return scanResult.entries.first { $0.id == id }
    }

    private var filteredEntries: [LogEntry] {
        guard !searchText.isEmpty else { return scanResult.entries }
        return scanResult.entries.filter {
            $0.eventMessage.localizedCaseInsensitiveContains(searchText) ||
            $0.processName.localizedCaseInsensitiveContains(searchText) ||
            $0.subsystem.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()

            if !scanResult.anomalies.isEmpty {
                anomaliesSection
                Divider()
            }

            VSplitView {
                VStack(spacing: 0) {
                    HStack {
                        TextField("Search entries...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 300)
                        Spacer()
                        Text("\(filteredEntries.count) entries")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)

                    Table(filteredEntries, selection: $selectedEntryID) {
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
                }

                Group {
                    if let selected = selectedEntry {
                        EntryInspectorView(entry: selected, siblings: scanResult.entries)
                    } else {
                        Text("Select a log entry to inspect")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(minHeight: 150, idealHeight: 250)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .sheet(item: $selectedAnomaly) { anomaly in
            AnomalyDetailView(anomaly: anomaly, entries: scanResult.entries)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: issue.severity.icon)
                .font(.title2)
                .foregroundStyle(severityColor)

            Image(systemName: issue.icon)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(issue.area)
                    .font(.headline)
                Text(issue.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(scanResult.entries.count)")
                        .font(.title3.monospacedDigit().bold())
                    Text("Total")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 2) {
                    Text("\(scanResult.errorCount)")
                        .font(.title3.monospacedDigit().bold())
                        .foregroundStyle(.orange)
                    Text("Errors")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 2) {
                    Text("\(scanResult.faultCount)")
                        .font(.title3.monospacedDigit().bold())
                        .foregroundStyle(.red)
                    Text("Faults")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 2) {
                    Text("\(scanResult.anomalies.count)")
                        .font(.title3.monospacedDigit().bold())
                        .foregroundStyle(.purple)
                    Text("Anomalies")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(issue.severity.label)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(severityColor, in: Capsule())
        }
        .padding()
    }

    // MARK: - Anomalies

    private var anomaliesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(scanResult.anomalies.enumerated()), id: \.offset) { _, anomaly in
                    Button {
                        selectedAnomaly = anomaly
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: anomalySeverityIcon(anomaly.severity))
                                .foregroundStyle(anomalySeverityColor(anomaly.severity))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(anomaly.type.rawValue)
                                    .font(.caption2.bold())
                                Text("\(anomaly.entryCount) entries")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(.background)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Helpers

    private var severityColor: Color {
        switch issue.severity {
        case .ok: return .green
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }

    private func anomalySeverityIcon(_ severity: Double) -> String {
        if severity >= 0.8 { return "exclamationmark.triangle.fill" }
        if severity >= 0.5 { return "exclamationmark.circle.fill" }
        return "info.circle.fill"
    }

    private func anomalySeverityColor(_ severity: Double) -> Color {
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

// MARK: - Make Anomaly Identifiable for sheet

extension Anomaly: Identifiable {
    public var id: String {
        "\(type.rawValue)-\(description.hashValue)-\(severity)"
    }
}
