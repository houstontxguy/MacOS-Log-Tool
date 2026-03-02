import SwiftUI
import LogToolCore

struct LogEntryRow: View {
    let entry: LogEntry

    var body: some View {
        HStack(spacing: 8) {
            Text(formattedTime)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)

            LevelBadge(level: entry.level)
                .frame(width: 65)

            Text(entry.processName)
                .font(.caption)
                .frame(width: 100, alignment: .leading)
                .lineLimit(1)

            Text(entry.subsystem)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 180, alignment: .leading)
                .lineLimit(1)

            Text(entry.eventMessage)
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }

    private var formattedTime: String {
        guard let date = entry.date else { return entry.timestamp }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}
