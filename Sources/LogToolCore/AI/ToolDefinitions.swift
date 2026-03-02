import Foundation

/// Tool-use definitions for AI-driven iterative log exploration.
public struct ToolDefinitions: Sendable {
    public init() {}

    /// All available tools for AI exploration.
    public static let allTools: [AITool] = [
        getLogsToolDef,
        getLogContextToolDef,
        searchLogsToolDef,
        getCrashReportsToolDef,
    ]

    /// Tool: get_logs — Retrieve log entries with filters.
    public static let getLogsToolDef = AITool(
        name: "get_logs",
        description: "Retrieve macOS unified log entries filtered by process, subsystem, time range, and log level. Returns log entries as formatted text.",
        parameters: """
        {
            "type": "object",
            "properties": {
                "process": {
                    "type": "string",
                    "description": "Filter by process name (e.g., 'Finder', 'WindowServer')"
                },
                "subsystem": {
                    "type": "string",
                    "description": "Filter by subsystem (e.g., 'com.apple.bluetooth')"
                },
                "last": {
                    "type": "string",
                    "description": "Time range like '5m', '1h', '30s', '2d'"
                },
                "level": {
                    "type": "string",
                    "enum": ["debug", "info", "default", "error", "fault"],
                    "description": "Minimum log level to include"
                },
                "message_contains": {
                    "type": "string",
                    "description": "Filter messages containing this text (case-insensitive)"
                },
                "max_entries": {
                    "type": "integer",
                    "description": "Maximum number of entries to return (default: 100)"
                }
            }
        }
        """
    )

    /// Tool: get_log_context — Get log entries around a specific timestamp.
    public static let getLogContextToolDef = AITool(
        name: "get_log_context",
        description: "Get log entries within a time window around a specific timestamp. Useful for understanding what happened before and after an event.",
        parameters: """
        {
            "type": "object",
            "properties": {
                "timestamp": {
                    "type": "string",
                    "description": "Center timestamp (format: 'yyyy-MM-dd HH:mm:ss')"
                },
                "window_seconds": {
                    "type": "integer",
                    "description": "Number of seconds before and after the timestamp (default: 30)"
                },
                "process": {
                    "type": "string",
                    "description": "Optional: filter by process name"
                }
            },
            "required": ["timestamp"]
        }
        """
    )

    /// Tool: search_logs — Full-text search across imported logs.
    public static let searchLogsToolDef = AITool(
        name: "search_logs",
        description: "Full-text search across previously imported log entries in the local database.",
        parameters: """
        {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "Search query (supports FTS5 syntax: AND, OR, NOT, phrases)"
                },
                "limit": {
                    "type": "integer",
                    "description": "Maximum results to return (default: 50)"
                }
            },
            "required": ["query"]
        }
        """
    )

    /// Tool: get_crash_reports — List recent crash reports.
    public static let getCrashReportsToolDef = AITool(
        name: "get_crash_reports",
        description: "List recent macOS crash reports (.ips files) from DiagnosticReports.",
        parameters: """
        {
            "type": "object",
            "properties": {
                "process": {
                    "type": "string",
                    "description": "Optional: filter by process name"
                },
                "since_days": {
                    "type": "integer",
                    "description": "Only show crashes from the last N days (default: 7)"
                }
            }
        }
        """
    )
}
