import SwiftUI
import LogToolCore

struct LogDetailView: View {
    let entry: LogEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    LevelBadge(level: entry.level)
                    Text(entry.processName)
                        .font(.headline)
                    Spacer()
                    Text(entry.timestamp)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }

                GroupBox("Message") {
                    Text(entry.eventMessage)
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], alignment: .leading, spacing: 8) {
                    DetailField(label: "Process", value: entry.processName)
                    DetailField(label: "PID", value: "\(entry.processID)")
                    DetailField(label: "Subsystem", value: entry.subsystem)
                    DetailField(label: "Category", value: entry.category)
                    DetailField(label: "Sender", value: entry.senderName)
                    DetailField(label: "Thread", value: "\(entry.threadID)")
                    DetailField(label: "Trace ID", value: "\(entry.traceID)")
                    DetailField(label: "Type", value: entry.messageType)
                }

                if let format = entry.formatString, !format.isEmpty {
                    DetailField(label: "Format String", value: format)
                }

                if let source = entry.source, !source.isEmpty {
                    DetailField(label: "Source", value: source)
                }
            }
            .padding()
        }
    }
}

private struct DetailField: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "—" : value)
                .font(.caption.monospaced())
                .textSelection(.enabled)
        }
    }
}
