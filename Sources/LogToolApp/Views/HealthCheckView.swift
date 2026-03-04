import SwiftUI
import LogToolCore

struct HealthCheckView: View {
    @State private var viewModel = HealthCheckViewModel()
    @State private var expandedIssue: UUID?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                if let error = viewModel.errorMessage { errorBanner(error) }
                if viewModel.isScanning { progressSection }
                if viewModel.scanComplete {
                    overallStatusSection
                    issuesSection
                    aiSection
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Health Check")
    }

    // MARK: - Header

    private var headerSection: some View {
        GroupBox {
            HStack(spacing: 16) {
                Image(systemName: "heart.text.square")
                    .font(.title)
                    .foregroundStyle(.pink)

                VStack(alignment: .leading, spacing: 2) {
                    Text("System Health Check")
                        .font(.headline)
                    Text("Scans all \(DiagnosticPreset.allPresets.count) diagnostic areas for issues")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("Last")
                    TextField("15", value: $viewModel.minutes, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                    Stepper("", value: $viewModel.minutes, in: 1...1440)
                        .labelsHidden()
                    Text("min")
                        .foregroundStyle(.secondary)
                }

                Button(action: viewModel.scan) {
                    if viewModel.isScanning {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label(viewModel.scanComplete ? "Re-scan" : "Scan", systemImage: "stethoscope")
                    }
                }
                .disabled(viewModel.isScanning)
                .controlSize(.large)
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Progress

    private var progressSection: some View {
        GroupBox {
            VStack(spacing: 8) {
                ProgressView(value: viewModel.scanProgress) {
                    Text("Scanning... \(Int(viewModel.scanProgress * 100))%")
                        .font(.caption)
                }
                let scannedCount = Int(viewModel.scanProgress * Double(DiagnosticPreset.allPresets.count))
                Text("\(scannedCount) / \(DiagnosticPreset.allPresets.count) areas checked")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Overall Status

    private var overallStatusSection: some View {
        GroupBox {
            HStack(spacing: 16) {
                Image(systemName: viewModel.overallSeverity.icon)
                    .font(.largeTitle)
                    .foregroundStyle(severityColor(viewModel.overallSeverity))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall: \(viewModel.overallSeverity.label)")
                        .font(.title3.bold())
                    let critical = viewModel.issues.filter { $0.severity == .critical }.count
                    let warnings = viewModel.issues.filter { $0.severity == .warning }.count
                    let info = viewModel.issues.filter { $0.severity == .info }.count
                    let ok = viewModel.issues.filter { $0.severity == .ok }.count
                    Text("\(critical) critical, \(warnings) warnings, \(info) info, \(ok) ok")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Issues List

    private var issuesSection: some View {
        GroupBox("Results by Area") {
            VStack(spacing: 0) {
                ForEach(viewModel.sortedIssues) { issue in
                    VStack(spacing: 0) {
                        issueRow(issue)
                        if issue.id != viewModel.sortedIssues.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
    }

    private func issueRow(_ issue: HealthIssue) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: issue.severity.icon)
                    .foregroundStyle(severityColor(issue.severity))
                    .font(.title3)

                Image(systemName: issue.icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(issue.area)
                        .font(.body.bold())
                    Text(issue.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if issue.errorCount > 0 {
                    Text("\(issue.errorCount) errors")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange, in: Capsule())
                }

                Text(issue.severity.label)
                    .font(.caption.bold())
                    .foregroundStyle(severityColor(issue.severity))
            }

            Text(issue.description)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.leading, 30)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    // MARK: - AI

    private var aiSection: some View {
        GroupBox("AI Summary") {
            VStack(alignment: .leading, spacing: 12) {
                if !viewModel.isAIConfigured {
                    HStack {
                        Image(systemName: "brain").foregroundStyle(.secondary)
                        Text("Configure an AI provider in Settings (Cmd+,) for an AI-powered summary.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                } else {
                    Button(action: viewModel.runAISummary) {
                        if viewModel.isAnalyzingAI {
                            ProgressView().controlSize(.small)
                        } else {
                            Label("Get AI Summary", systemImage: "wand.and.stars")
                        }
                    }
                    .disabled(viewModel.isAnalyzingAI)

                    if !viewModel.aiSummary.isEmpty {
                        Divider()
                        Text(viewModel.aiSummary)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if let usage = viewModel.aiUsage {
                            Divider()
                            Text("Tokens: \(usage.inputTokens) in / \(usage.outputTokens) out")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            Text(message).font(.caption)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(.orange.opacity(0.1))
    }

    private func severityColor(_ severity: HealthSeverity) -> Color {
        switch severity {
        case .ok: return .green
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}
