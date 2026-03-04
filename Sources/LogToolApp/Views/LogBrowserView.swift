import SwiftUI
import LogToolCore

struct LogBrowserView: View {
    @State private var viewModel = LogBrowserViewModel()

    var body: some View {
        VSplitView {
            VStack(spacing: 0) {
                FilterBar(
                    process: $viewModel.process,
                    subsystem: $viewModel.subsystem,
                    selectedLevel: $viewModel.selectedLevel,
                    timeRange: $viewModel.timeRange,
                    onFetch: viewModel.fetch
                )

                Divider()

                if viewModel.isLoading {
                    ProgressView("Fetching logs...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry", action: viewModel.fetch)
                    }
                } else if viewModel.entries.isEmpty {
                    ContentUnavailableView(
                        "No Logs",
                        systemImage: "doc.text",
                        description: Text("Set filters and click Fetch to load log entries.")
                    )
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
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .width(min: 80, ideal: 110)

                        TableColumn("Subsystem") { entry in
                            Text(entry.subsystem)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .width(min: 120, ideal: 200)

                        TableColumn("Message") { entry in
                            Text(entry.eventMessage)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .width(min: 200)
                    }
                    .searchable(text: $viewModel.searchText, prompt: "Filter messages...")
                }
            }

            // Detail pane
            Group {
                if let selected = viewModel.selectedEntry {
                    EntryInspectorView(entry: selected, siblings: viewModel.filteredEntries)
                } else {
                    Text("Select a log entry to view details")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minHeight: 150, idealHeight: 250)
        }
        .navigationTitle("Log Browser")
        .toolbar {
            ToolbarItem {
                Text("\(viewModel.filteredEntries.count) entries")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }

    private func formatTime(_ entry: LogEntry) -> String {
        guard let date = entry.date else { return entry.timestamp }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}
