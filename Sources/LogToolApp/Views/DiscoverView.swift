import SwiftUI
import LogToolCore

struct DiscoverView: View {
    @State private var viewModel = DiscoverViewModel()

    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            VStack(spacing: 0) {
                // Controls
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("Time range:")
                        TextField("e.g. 5m, 1h", text: $viewModel.timeRange)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }

                    Button(action: viewModel.fetch) {
                        Label("Discover", systemImage: "magnifyingglass")
                    }

                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Spacer()

                    TextField("Filter subsystems...", text: $viewModel.filterText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)

                    Text("\(viewModel.filteredSubsystems.count) subsystems")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .padding()
                }

                if viewModel.subsystems.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Subsystems",
                        systemImage: "list.bullet.indent",
                        description: Text("Click Discover to find active subsystems.")
                    )
                } else {
                    List(viewModel.filteredSubsystems, id: \.subsystem) { info in
                        subsystemRow(info)
                    }
                    .listStyle(.sidebar)
                }
            }
            .navigationTitle("Subsystem Discovery")
            .navigationDestination(for: DrillDownLevel.self) { level in
                drillDownView(for: level)
            }
        }
        .task {
            viewModel.fetch()
        }
    }

    // MARK: - Subsystem Row

    @ViewBuilder
    private func subsystemRow(_ info: SubsystemInfo) -> some View {
        DisclosureGroup {
            // Categories (clickable)
            if !info.categories.isEmpty {
                Section("Categories") {
                    ForEach(info.categories, id: \.name) { cat in
                        Button {
                            viewModel.drillIntoCategory(subsystem: info.subsystem, category: cat.name)
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                Text(cat.name)
                                    .font(.caption)
                                Spacer()
                                Text("\(cat.count)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Level breakdown
            Section("Levels") {
                ForEach(LogLevel.allCases, id: \.self) { level in
                    if let count = info.levelBreakdown[level], count > 0 {
                        HStack {
                            LevelBadge(level: level)
                            Spacer()
                            Text("\(count)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Processes (clickable)
            if !info.processes.isEmpty {
                Section("Processes") {
                    ForEach(info.processes, id: \.self) { proc in
                        Button {
                            viewModel.drillIntoProcess(subsystem: info.subsystem, process: proc)
                        } label: {
                            HStack {
                                Image(systemName: "gearshape")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                Text(proc)
                                    .font(.caption)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // View all entries button
            Button {
                viewModel.fetchEntriesForSubsystem(info.subsystem)
            } label: {
                Label("View All Entries", systemImage: "doc.text.magnifyingglass")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .padding(.top, 4)
        } label: {
            HStack {
                Text(info.subsystem.isEmpty ? "(none)" : info.subsystem)
                    .font(.body)
                Spacer()
                if info.errorCount > 0 {
                    Button {
                        viewModel.drillIntoErrors(subsystem: info.subsystem)
                    } label: {
                        Text("\(info.errorCount) errors")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Text("\(info.totalCount)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Drill-Down View

    @ViewBuilder
    private func drillDownView(for level: DrillDownLevel) -> some View {
        VSplitView {
            VStack(spacing: 0) {
                drillDownHeader(for: level)
                Divider()
                drillDownTable
            }

            Group {
                if let entry = viewModel.selectedEntry {
                    LogDetailView(entry: entry)
                } else {
                    Text("Select an entry to view details")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minHeight: 150, idealHeight: 250)
        }
        .navigationTitle(drillDownTitle(for: level))
    }

    private func drillDownHeader(for level: DrillDownLevel) -> some View {
        HStack(spacing: 12) {
            switch level {
            case .subsystem(let s):
                Label(s.isEmpty ? "(none)" : s, systemImage: "shippingbox")
                    .font(.headline)
            case .category(let s, let c):
                Label(s, systemImage: "shippingbox")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Label(c, systemImage: "folder")
                    .font(.headline)
            case .process(let s, let p):
                Label(s, systemImage: "shippingbox")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Label(p, systemImage: "gearshape")
                    .font(.headline)
            case .errors(let s):
                Label(s.isEmpty ? "(none)" : s, systemImage: "shippingbox")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Label("Errors", systemImage: "exclamationmark.triangle")
                    .font(.headline)
                    .foregroundStyle(.orange)
            }

            Spacer()

            if viewModel.isLoadingEntries {
                ProgressView()
                    .controlSize(.small)
            }

            Text("\(viewModel.drillDownEntries.count) entries")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var drillDownTable: some View {
        if viewModel.isLoadingEntries {
            ProgressView("Loading entries...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.drillDownEntries.isEmpty {
            ContentUnavailableView(
                "No Entries",
                systemImage: "doc.text",
                description: Text("No log entries found for this filter.")
            )
        } else {
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
        }
    }

    private func drillDownTitle(for level: DrillDownLevel) -> String {
        switch level {
        case .subsystem(let s): return s.isEmpty ? "(none)" : s
        case .category(_, let c): return c
        case .process(_, let p): return p
        case .errors(let s): return "\(s) - Errors"
        }
    }

    private func formatTime(_ entry: LogEntry) -> String {
        guard let date = entry.date else { return entry.timestamp }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}
