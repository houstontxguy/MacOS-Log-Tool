import ArgumentParser
import Foundation
import LogToolCore

struct CrashCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "crash",
        abstract: "List recent crash reports and correlate with unified logs.",
        subcommands: [
            ListSubcommand.self,
            ShowSubcommand.self,
            CorrelateSubcommand.self,
            AnalyzeSubcommand.self,
        ],
        defaultSubcommand: ListSubcommand.self
    )
}

extension CrashCommand {
    struct ListSubcommand: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "list",
            abstract: "List recent crash reports."
        )

        @Option(name: .long, help: "Only show crashes from the last N days.")
        var days: Int = 7

        @Option(name: .long, help: "Filter by process name.")
        var process: String?

        func run() async throws {
            let parser = CrashReportParser()
            let since = Calendar.current.date(byAdding: .day, value: -days, to: Date())
            let files = parser.listCrashReports(since: since)

            var reports: [(url: URL, summary: String)] = []
            for url in files {
                if let crash = try? parser.parse(at: url.path) {
                    if let process, !crash.processName.localizedCaseInsensitiveContains(process) {
                        continue
                    }
                    reports.append((url: url, summary: crash.summary))
                }
            }

            let formatter = TableFormatter()
            print(formatter.formatCrashList(reports))
        }
    }

    struct ShowSubcommand: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "show",
            abstract: "Show details of a crash report."
        )

        @Argument(help: "Path to the .ips crash report file.")
        var path: String

        func run() async throws {
            let parser = CrashReportParser()
            let crash = try parser.parse(at: path)
            let colorFormatter = ColorFormatter()

            print(colorFormatter.colorize("Crash Report", .bold))
            print(String(repeating: "─", count: 60))
            print("Process:    \(crash.processName)")
            print("PID:        \(crash.body.pid ?? 0)")
            print("Timestamp:  \(crash.header.timestamp ?? crash.body.captureTime ?? "Unknown")")
            print("OS Version: \(crash.header.os_version ?? "Unknown")")

            if let bundle = crash.body.bundleInfo {
                print("Bundle:     \(bundle.CFBundleIdentifier ?? "?") \(bundle.CFBundleShortVersionString ?? "")")
            }

            if let exc = crash.body.exception {
                print("")
                print(colorFormatter.colorize("Exception", .bold))
                print("Type:       \(exc.type ?? "Unknown")")
                print("Signal:     \(exc.signal ?? "Unknown")")
                if let codes = exc.codes {
                    print("Codes:      \(codes)")
                }
                if let subtype = exc.subtype {
                    print("Subtype:    \(subtype)")
                }
            }

            if let term = crash.body.termination {
                print("")
                print(colorFormatter.colorize("Termination", .bold))
                print("Namespace:  \(term.namespace ?? "?")")
                print("Code:       \(term.code ?? 0)")
                if let indicator = term.indicator {
                    print("Indicator:  \(indicator)")
                }
                if let byProc = term.byProc {
                    print("By Process: \(byProc) (PID \(term.byPid ?? 0))")
                }
            }

            // Show faulting thread
            if let faultingThread = crash.body.faultingThread,
               let threads = crash.body.threads,
               faultingThread < threads.count {
                let thread = threads[faultingThread]
                print("")
                print(colorFormatter.colorize("Faulting Thread \(faultingThread)", .boldRed))
                if let queue = thread.queue {
                    print("Queue: \(queue)")
                }
                if let frames = thread.frames {
                    for (idx, frame) in frames.prefix(30).enumerated() {
                        let symbol = frame.symbol ?? "???"
                        let offset = frame.symbolLocation.map { " + \($0)" } ?? ""
                        let imageIdx = frame.imageIndex.map { " [image \($0)]" } ?? ""
                        print("  \(String(idx).padding(toLength: 3, withPad: " ", startingAt: 0)) \(symbol)\(offset)\(imageIdx)")
                    }
                }
            }
        }
    }

    struct CorrelateSubcommand: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "correlate",
            abstract: "Pull unified logs from around a crash time."
        )

        @Argument(help: "Path to the .ips crash report file.")
        var path: String

        @Option(name: .long, help: "Window in seconds before/after crash (default: 300).")
        var window: Int = 300

        @Option(name: .long, help: "Output format: table, json.")
        var format: String = "table"

        func run() async throws {
            let crashParser = CrashReportParser()
            let crash = try crashParser.parse(at: path)

            guard let crashDate = crash.date else {
                print("Cannot determine crash timestamp.")
                throw ExitCode.failure
            }

            let startTime = crashDate.addingTimeInterval(-Double(window))
            let endTime = crashDate.addingTimeInterval(30) // Include a bit after crash

            let filter = LogFilter(
                process: crash.processName,
                startTime: startTime,
                endTime: endTime
            )

            let collector = LogCollector()
            let entries = try await collector.collect(filter: filter)

            let colorFormatter = ColorFormatter()
            print(colorFormatter.colorize("Logs around crash: \(crash.processName) at \(crash.header.timestamp ?? "?")", .bold))
            print("Window: \(window)s before to 30s after crash")
            print("")

            switch format.lowercased() {
            case "json":
                let jsonFormatter = JSONOutputFormatter()
                print(jsonFormatter.formatEntries(entries))
            default:
                let tableFormatter = TableFormatter()
                print(tableFormatter.formatEntries(entries))
            }
        }
    }

    struct AnalyzeSubcommand: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "analyze",
            abstract: "AI-powered crash report analysis with log correlation."
        )

        @Argument(help: "Path to the .ips crash report file.")
        var path: String

        @Option(name: .long, help: "Window in seconds before crash for log correlation (default: 300).")
        var window: Int = 300

        func run() async throws {
            let crashParser = CrashReportParser()
            let crash = try crashParser.parse(at: path)
            let colorFormatter = ColorFormatter()

            // Get correlated logs
            var logs: [LogEntry] = []
            if let crashDate = crash.date {
                let filter = LogFilter(
                    process: crash.processName,
                    startTime: crashDate.addingTimeInterval(-Double(window)),
                    endTime: crashDate.addingTimeInterval(30)
                )
                let collector = LogCollector()
                logs = (try? await collector.collect(filter: filter)) ?? []
            }

            print(colorFormatter.colorize("Analyzing crash report with AI...", .dim))

            let provider = try AIProviderFactory.create()
            let prompts = PromptTemplates()

            let messages = [
                AIMessage(role: .system, content: PromptTemplates.crashAnalysisSystem),
                AIMessage(role: .user, content: prompts.buildCrashAnalysisPrompt(crash: crash, logs: logs)),
            ]

            let response = try await provider.complete(messages: messages)
            print("")
            print(response.content)

            if let usage = response.usage {
                print("")
                print(colorFormatter.colorize("Tokens: \(usage.inputTokens) in, \(usage.outputTokens) out", .dim))
            }
        }
    }
}
