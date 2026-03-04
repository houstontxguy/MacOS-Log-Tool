import SwiftUI
import LogToolCore

struct AnomalyDetailView: View {
    let anomaly: Anomaly
    let entries: [LogEntry]
    @State private var selectedEntryID: UUID?

    private var relatedEntries: [LogEntry] {
        let subsystems = Set(anomaly.relatedSubsystems)
        var filtered: [LogEntry]

        if subsystems.isEmpty {
            filtered = entries
        } else {
            filtered = entries.filter { subsystems.contains($0.subsystem) }
        }

        // If anomaly has a timestamp, narrow to ±60s window
        if let anomalyDate = anomaly.timestamp {
            filtered = filtered.filter { entry in
                guard let date = entry.date else { return true }
                return abs(date.timeIntervalSince(anomalyDate)) <= 60
            }
        }

        return filtered
    }

    private var selectedEntry: LogEntry? {
        guard let id = selectedEntryID else { return nil }
        return relatedEntries.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            GroupBox {
                HStack(spacing: 12) {
                    Image(systemName: severityIcon)
                        .font(.title2)
                        .foregroundStyle(severityColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(anomaly.type.rawValue)
                            .font(.headline)
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

                    severityBadge
                }
                .padding(.vertical, 4)
            }
            .padding()

            Divider()

            // Entries table + inspector
            VSplitView {
                Table(relatedEntries, selection: $selectedEntryID) {
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
                    if let selected = selectedEntry {
                        EntryInspectorView(entry: selected, siblings: relatedEntries)
                    } else {
                        Text("Select an entry to inspect")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(minHeight: 150, idealHeight: 250)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    // MARK: - Helpers

    private var severityIcon: String {
        if anomaly.severity >= 0.8 { return "exclamationmark.triangle.fill" }
        if anomaly.severity >= 0.5 { return "exclamationmark.circle.fill" }
        return "info.circle.fill"
    }

    private var severityColor: Color {
        if anomaly.severity >= 0.8 { return .red }
        if anomaly.severity >= 0.5 { return .orange }
        return .yellow
    }

    private var severityBadge: some View {
        Text(anomaly.severity >= 0.8 ? "Critical" : anomaly.severity >= 0.5 ? "Warning" : "Info")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(severityColor, in: Capsule())
    }

    private func formatTime(_ entry: LogEntry) -> String {
        guard let date = entry.date else { return entry.timestamp }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}
