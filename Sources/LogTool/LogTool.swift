import ArgumentParser

@main
struct LogTool: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "logtool",
        abstract: "macOS unified log analysis tool with optional AI-powered insights.",
        version: "0.1.0",
        subcommands: [
            ExportCommand.self,
            StreamCommand.self,
            StatsCommand.self,
            DiscoverCommand.self,
            CrashCommand.self,
            QueryCommand.self,
            AnalyzeCommand.self,
            ConfigCommand.self,
        ]
    )
}
