import SwiftUI
import LogToolCore

struct StreamView: View {
    @State private var viewModel = StreamViewModel()

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
                    TextField("Process", text: $viewModel.process)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                        .disabled(viewModel.isStreaming)
                }

                HStack(spacing: 4) {
                    Image(systemName: "shippingbox")
                        .foregroundStyle(.secondary)
                    TextField("Subsystem", text: $viewModel.subsystem)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 180)
                        .disabled(viewModel.isStreaming)
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

            // Log entries
            ScrollViewReader { proxy in
                List(viewModel.entries) { entry in
                    LogEntryRow(entry: entry)
                        .id(entry.id)
                }
                .listStyle(.plain)
                .font(.system(.caption, design: .monospaced))
                .onChange(of: viewModel.entries.count) {
                    if viewModel.autoScroll, let last = viewModel.entries.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .navigationTitle("Live Stream")
        .onDisappear {
            viewModel.stop()
        }
    }
}
