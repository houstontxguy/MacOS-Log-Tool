import SwiftUI
import LogToolCore

struct CrashDetailView: View {
    let crash: CrashReport

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                GroupBox("Crash Info") {
                    VStack(alignment: .leading, spacing: 6) {
                        DetailRow(label: "Process", value: crash.body.procName ?? "Unknown")
                        DetailRow(label: "PID", value: crash.body.pid.map { "\($0)" } ?? "—")
                        DetailRow(label: "Path", value: crash.body.procPath ?? "—")
                        if let bundle = crash.body.bundleInfo {
                            DetailRow(label: "Bundle ID", value: bundle.CFBundleIdentifier ?? "—")
                            DetailRow(label: "Version", value: bundle.CFBundleShortVersionString ?? "—")
                        }
                        DetailRow(label: "Date", value: crash.body.captureTime ?? crash.header.timestamp ?? "—")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Exception
                if let exception = crash.body.exception {
                    GroupBox("Exception") {
                        VStack(alignment: .leading, spacing: 6) {
                            DetailRow(label: "Type", value: exception.type ?? "—")
                            DetailRow(label: "Signal", value: exception.signal ?? "—")
                            DetailRow(label: "Codes", value: exception.codes ?? "—")
                            if let subtype = exception.subtype {
                                DetailRow(label: "Subtype", value: subtype)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Termination
                if let term = crash.body.termination {
                    GroupBox("Termination") {
                        VStack(alignment: .leading, spacing: 6) {
                            DetailRow(label: "Signal", value: term.signal ?? "—")
                            DetailRow(label: "Code", value: term.code.map { "\($0)" } ?? "—")
                            DetailRow(label: "Namespace", value: term.namespace ?? "—")
                            DetailRow(label: "By Process", value: term.byProc ?? "—")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Faulting thread
                if let threadIdx = crash.body.faultingThread,
                   let threads = crash.body.threads,
                   threadIdx < threads.count {
                    let thread = threads[threadIdx]
                    GroupBox("Faulting Thread (\(threadIdx))") {
                        VStack(alignment: .leading, spacing: 4) {
                            if let queue = thread.queue {
                                Text("Queue: \(queue)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            if let frames = thread.frames {
                                ForEach(Array(frames.prefix(20).enumerated()), id: \.offset) { idx, frame in
                                    HStack(spacing: 8) {
                                        Text("\(idx)")
                                            .font(.caption2.monospaced())
                                            .frame(width: 25, alignment: .trailing)
                                            .foregroundStyle(.secondary)
                                        Text(frame.symbol ?? "0x\(String(frame.imageOffset ?? 0, radix: 16))")
                                            .font(.caption.monospaced())
                                            .lineLimit(1)
                                    }
                                }
                                if frames.count > 20 {
                                    Text("... \(frames.count - 20) more frames")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.caption.bold())
                .frame(width: 80, alignment: .trailing)
            Text(value)
                .font(.caption.monospaced())
                .textSelection(.enabled)
        }
    }
}
