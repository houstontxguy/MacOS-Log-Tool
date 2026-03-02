import SwiftUI
import LogToolCore

struct DiscoverView: View {
    @State private var viewModel = DiscoverViewModel()

    var body: some View {
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
                    DisclosureGroup {
                        // Categories
                        if !info.categories.isEmpty {
                            Section("Categories") {
                                ForEach(info.categories, id: \.name) { cat in
                                    HStack {
                                        Text(cat.name)
                                            .font(.caption)
                                        Spacer()
                                        Text("\(cat.count)")
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
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

                        // Processes
                        if !info.processes.isEmpty {
                            Section("Processes") {
                                ForEach(info.processes, id: \.self) { proc in
                                    Text(proc)
                                        .font(.caption)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(info.subsystem.isEmpty ? "(none)" : info.subsystem)
                                .font(.body)
                            Spacer()
                            if info.errorCount > 0 {
                                Text("\(info.errorCount) errors")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            Text("\(info.totalCount)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .navigationTitle("Subsystem Discovery")
        .task {
            viewModel.fetch()
        }
    }
}
