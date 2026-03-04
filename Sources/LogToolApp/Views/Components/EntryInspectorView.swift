import SwiftUI
import LogToolCore

struct EntryInspectorView: View {
    let entry: LogEntry
    let siblings: [LogEntry]
    @State private var viewModel: EntryInspectorViewModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Existing detail view
                LogDetailView(entry: entry)

                if let vm = viewModel {
                    contextSection(vm)
                    relatedEntriesSection(vm)
                    aiSection(vm)
                }
            }
        }
        .onChange(of: entry.id, initial: true) {
            viewModel = EntryInspectorViewModel(entry: entry, siblings: siblings)
        }
    }

    // MARK: - Context Section

    @ViewBuilder
    private func contextSection(_ vm: EntryInspectorViewModel) -> some View {
        GroupBox("Context") {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: vm.processClassification.icon)
                        .foregroundStyle(.secondary)
                    Text(vm.processClassification.rawValue)
                        .font(.caption.bold())
                    Spacer()
                }

                if vm.subsystemTotalCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Text("\(String(format: "%.0f", vm.subsystemErrorRate * 100))% error rate in this subsystem (\(vm.subsystemErrorCount)/\(vm.subsystemTotalCount))")
                            .font(.caption)
                            .foregroundStyle(vm.subsystemErrorRate > 0.2 ? .red : .secondary)
                    }
                }

                if vm.messageFrequency > 1 {
                    HStack(spacing: 6) {
                        Image(systemName: "repeat")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Text("This message pattern appears \(vm.messageFrequency) times")
                            .font(.caption)
                            .foregroundStyle(vm.messageFrequency > 10 ? .orange : .secondary)
                    }
                }

                if !vm.sameThreadEntries.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.branch")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Text("\(vm.sameThreadEntries.count) entries on same thread")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Timeline: nearby entries from same process
                if !vm.temporalNeighbors.isEmpty {
                    Divider()
                    Text("Timeline (±5s)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    VStack(spacing: 2) {
                        ForEach(vm.temporalNeighbors.prefix(10)) { neighbor in
                            CompactEntryRow(entry: neighbor, highlightID: entry.id)
                        }
                        if vm.temporalNeighbors.count > 10 {
                            Text("... \(vm.temporalNeighbors.count - 10) more")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Related Entries Section

    @ViewBuilder
    private func relatedEntriesSection(_ vm: EntryInspectorViewModel) -> some View {
        GroupBox("Related Entries") {
            VStack(alignment: .leading, spacing: 4) {
                relatedDisclosure(
                    title: "Same Process",
                    count: vm.sameProcessEntries.count,
                    entries: vm.sameProcessEntries
                )
                relatedDisclosure(
                    title: "Same Subsystem",
                    count: vm.sameSubsystemEntries.count,
                    entries: vm.sameSubsystemEntries
                )
                relatedDisclosure(
                    title: "Same Thread",
                    count: vm.sameThreadEntries.count,
                    entries: vm.sameThreadEntries
                )
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func relatedDisclosure(title: String, count: Int, entries: [LogEntry]) -> some View {
        DisclosureGroup("\(title) (\(count))") {
            if entries.isEmpty {
                Text("None")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                VStack(spacing: 2) {
                    ForEach(entries.prefix(20)) { relatedEntry in
                        CompactEntryRow(entry: relatedEntry, highlightID: entry.id)
                    }
                    if entries.count > 20 {
                        Text("... \(entries.count - 20) more")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .font(.caption)
    }

    // MARK: - AI Section

    @ViewBuilder
    private func aiSection(_ vm: EntryInspectorViewModel) -> some View {
        if vm.isAIConfigured {
            GroupBox("AI Analysis") {
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: vm.runAIAnalysis) {
                        if vm.isAnalyzingAI {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Label(
                                vm.aiAnalysis.isEmpty ? "Analyze Entry" : "Re-analyze",
                                systemImage: "wand.and.stars"
                            )
                        }
                    }
                    .disabled(vm.isAnalyzingAI)

                    if let error = vm.aiError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if !vm.aiAnalysis.isEmpty {
                        Divider()
                        Text(vm.aiAnalysis)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if let usage = vm.aiUsage {
                            Divider()
                            Text("Tokens: \(usage.inputTokens) in / \(usage.outputTokens) out")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Compact Entry Row

private struct CompactEntryRow: View {
    let entry: LogEntry
    var highlightID: UUID?

    var body: some View {
        HStack(spacing: 6) {
            Text(formattedTime)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 75, alignment: .leading)

            LevelBadge(level: entry.level)
                .scaleEffect(0.8)
                .frame(width: 50)

            Text(entry.processName)
                .font(.caption2)
                .frame(width: 80, alignment: .leading)
                .lineLimit(1)

            Text(entry.eventMessage)
                .font(.caption2)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 1)
        .opacity(entry.id == highlightID ? 0.5 : 1.0)
    }

    private var formattedTime: String {
        guard let date = entry.date else { return entry.timestamp }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}
