import SwiftUI
import LogToolCore

struct StreamView: View {
    @State private var viewModel = StreamViewModel()
    @Environment(ActiveSubsystemPoller.self) private var poller: ActiveSubsystemPoller?

    var body: some View {
        VStack(spacing: 0) {
            // Controls
            HStack(spacing: 12) {
                Button(action: viewModel.toggleStream) {
                    Label(
                        viewModel.isStreaming ? "Stop" : "Start",
                        systemImage: viewModel.isStreaming ? "stop.fill" : "play.fill"
                    )
                }
                .controlSize(.large)
                .tint(viewModel.isStreaming ? .red : .green)

                HStack(spacing: 4) {
                    Image(systemName: "gearshape.2")
                        .foregroundStyle(.secondary)
                    SuggestionTextField(
                        placeholder: "Process",
                        text: $viewModel.process,
                        suggestions: poller?.processSuggestions ?? DiagnosticPreset.commonProcesses,
                        isDisabled: viewModel.isStreaming
                    )
                    .frame(width: 140, height: 24)
                }

                HStack(spacing: 4) {
                    Image(systemName: "shippingbox")
                        .foregroundStyle(.secondary)
                    SuggestionTextField(
                        placeholder: "Subsystem",
                        text: $viewModel.subsystem,
                        suggestions: poller?.subsystemSuggestions ?? DiagnosticPreset.commonSubsystems,
                        isDisabled: viewModel.isStreaming
                    )
                    .frame(width: 200, height: 24)
                }

                Picker("Level", selection: $viewModel.selectedLevel) {
                    Text("All").tag(LogLevel?.none)
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Text(level.rawValue.capitalized).tag(LogLevel?.some(level))
                    }
                }
                .frame(width: 120)
                .disabled(viewModel.isStreaming)

                Spacer()

                Toggle("Auto-scroll", isOn: $viewModel.autoScroll)

                Button(action: viewModel.clear) {
                    Label("Clear", systemImage: "trash")
                }

                Text("\(viewModel.entryCount) entries")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .monospacedDigit()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(.orange.opacity(0.1))
            }

            // Log entries with detail pane
            VSplitView {
                ScrollViewReader { proxy in
                    List(viewModel.entries, selection: $viewModel.selectedEntryID) { entry in
                        LogEntryRow(entry: entry)
                            .id(entry.id)
                            .tag(entry.id)
                    }
                    .listStyle(.plain)
                    .font(.system(.caption, design: .monospaced))
                    .onChange(of: viewModel.entries.count) {
                        if viewModel.autoScroll, let last = viewModel.entries.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }

                Group {
                    if let selected = viewModel.selectedEntry {
                        EntryInspectorView(entry: selected, siblings: viewModel.entries)
                    } else {
                        Text("Select an entry to inspect")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(minHeight: 120, idealHeight: 220)
            }
        }
        .navigationTitle("Live Stream")
        .onDisappear {
            viewModel.stop()
        }
    }
}
