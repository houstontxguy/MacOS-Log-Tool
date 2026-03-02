import Foundation

/// ANSI color-coded output formatting for log entries.
/// Respects the NO_COLOR environment variable.
public struct ColorFormatter: Sendable {
    private let colorEnabled: Bool

    public init(forceColor: Bool? = nil) {
        if let force = forceColor {
            self.colorEnabled = force
        } else {
            self.colorEnabled = ProcessInfo.processInfo.environment["NO_COLOR"] == nil
                && isatty(STDOUT_FILENO) != 0
        }
    }

    /// ANSI escape codes.
    public enum Color: String, Sendable {
        case reset = "\u{001B}[0m"
        case red = "\u{001B}[31m"
        case yellow = "\u{001B}[33m"
        case blue = "\u{001B}[34m"
        case gray = "\u{001B}[90m"
        case white = "\u{001B}[37m"
        case bold = "\u{001B}[1m"
        case dim = "\u{001B}[2m"
        case cyan = "\u{001B}[36m"
        case green = "\u{001B}[32m"
        case magenta = "\u{001B}[35m"
        case boldRed = "\u{001B}[1;31m"
        case boldYellow = "\u{001B}[1;33m"
    }

    /// Apply color to text if color is enabled.
    public func colorize(_ text: String, _ color: Color) -> String {
        guard colorEnabled else { return text }
        return "\(color.rawValue)\(text)\(Color.reset.rawValue)"
    }

    /// Get the color for a log level.
    public func color(for level: LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .default: return .white
        case .error: return .yellow
        case .fault: return .boldRed
        }
    }

    /// Format a log entry with colors.
    public func formatEntry(_ entry: LogEntry, showSubsystem: Bool = true) -> String {
        let levelColor = color(for: entry.level)
        let levelStr = colorize(entry.level.rawValue.padding(toLength: 7, withPad: " ", startingAt: 0).uppercased(), levelColor)
        let timestamp = colorize(formatTimestamp(entry.timestamp), .dim)
        let process = colorize(entry.processName, .cyan)
        let pid = colorize("[\(entry.processID)]", .dim)

        var line = "\(timestamp) \(levelStr) \(process)\(pid)"

        if showSubsystem && !entry.subsystem.isEmpty {
            let sub = colorize("\(entry.subsystem):\(entry.category)", .magenta)
            line += " \(sub)"
        }

        let message = colorize(entry.eventMessage, levelColor)
        line += " \(message)"

        return line
    }

    /// Format a timestamp string for display (truncate to readable length).
    private func formatTimestamp(_ timestamp: String) -> String {
        // Input: "2024-01-15 10:30:45.123456-0800"
        // Output: "10:30:45.123456"
        let parts = timestamp.split(separator: " ")
        if parts.count >= 2 {
            let timePart = String(parts[1])
            // Remove timezone
            if let plusIdx = timePart.firstIndex(of: "+") {
                return String(timePart[..<plusIdx])
            }
            if let minusIdx = timePart.lastIndex(of: "-"), minusIdx > timePart.startIndex {
                let beforeMinus = timePart[..<minusIdx]
                if beforeMinus.contains(":") {
                    return String(beforeMinus)
                }
            }
            return timePart
        }
        return timestamp
    }

    /// Format a severity indicator.
    public func severityIndicator(for severity: AnalysisResult.Severity) -> String {
        switch severity {
        case .critical: return colorize("●", .boldRed)
        case .warning: return colorize("●", .boldYellow)
        case .info: return colorize("●", .blue)
        case .ok: return colorize("●", .green)
        }
    }

    /// Format an anomaly severity bar.
    public func severityBar(_ severity: Double, width: Int = 10) -> String {
        let filled = Int(severity * Double(width))
        let empty = width - filled
        let color: Color = severity > 0.7 ? .boldRed : (severity > 0.4 ? .yellow : .green)
        return colorize(String(repeating: "█", count: filled), color) +
            colorize(String(repeating: "░", count: empty), .dim)
    }
}
