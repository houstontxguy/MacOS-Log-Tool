import SwiftUI
import LogToolCore

struct FilterBar: View {
    @Binding var process: String
    @Binding var subsystem: String
    @Binding var selectedLevel: LogLevel?
    @Binding var timeRange: String
    var onFetch: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "gearshape.2")
                    .foregroundStyle(.secondary)
                TextField("Process", text: $process)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 140)
            }

            HStack(spacing: 4) {
                Image(systemName: "shippingbox")
                    .foregroundStyle(.secondary)
                TextField("Subsystem", text: $subsystem)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }

            Picker("Level", selection: $selectedLevel) {
                Text("All Levels").tag(LogLevel?.none)
                Divider()
                ForEach(LogLevel.allCases, id: \.self) { level in
                    Text(level.rawValue.capitalized).tag(LogLevel?.some(level))
                }
            }
            .frame(width: 130)

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                TextField("e.g. 5m, 1h", text: $timeRange)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
            }

            Button(action: onFetch) {
                Label("Fetch", systemImage: "arrow.clockwise")
            }
            .keyboardShortcut(.return, modifiers: .command)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
