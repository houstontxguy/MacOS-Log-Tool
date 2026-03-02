import Foundation

/// Parses macOS crash reports from .ips files.
public struct CrashReportParser: Sendable {
    private let decoder: JSONDecoder

    public init() {
        self.decoder = JSONDecoder()
    }

    /// Parse a .ips crash report file.
    /// Modern .ips format: first line is JSON header, rest is JSON body.
    public func parse(at path: String) throws -> CrashReport {
        let url = URL(fileURLWithPath: path)
        let content = try String(contentsOf: url, encoding: .utf8)
        return try parse(content: content, filePath: path)
    }

    /// Parse crash report content.
    public func parse(content: String, filePath: String = "") throws -> CrashReport {
        // Split into header (first line) and body (rest)
        let lines = content.components(separatedBy: "\n")
        guard let headerLine = lines.first, !headerLine.isEmpty else {
            throw CrashReportError.invalidFormat("Empty file")
        }

        // Parse header
        guard let headerData = headerLine.data(using: .utf8) else {
            throw CrashReportError.invalidFormat("Cannot read header")
        }
        let header: CrashReport.Header
        do {
            header = try decoder.decode(CrashReport.Header.self, from: headerData)
        } catch {
            throw CrashReportError.headerParseFailed(error.localizedDescription)
        }

        // Parse body (everything after the first line)
        let bodyText = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !bodyText.isEmpty, let bodyData = bodyText.data(using: .utf8) else {
            throw CrashReportError.invalidFormat("No body content")
        }

        let body: CrashReport.Body
        do {
            body = try decoder.decode(CrashReport.Body.self, from: bodyData)
        } catch {
            throw CrashReportError.bodyParseFailed(error.localizedDescription)
        }

        return CrashReport(header: header, body: body, filePath: filePath)
    }

    /// List all .ips crash report files in the DiagnosticReports directories.
    public func listCrashReports(since: Date? = nil) -> [URL] {
        let fm = FileManager.default
        let homeDir = fm.homeDirectoryForCurrentUser

        let directories = [
            homeDir.appendingPathComponent("Library/Logs/DiagnosticReports"),
            URL(fileURLWithPath: "/Library/Logs/DiagnosticReports"),
        ]

        var files: [URL] = []

        for dir in directories {
            guard let enumerator = fm.enumerator(
                at: dir,
                includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            while let url = enumerator.nextObject() as? URL {
                guard url.pathExtension == "ips" else { continue }

                if let since {
                    if let attrs = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
                       let modDate = attrs.contentModificationDate,
                       modDate < since {
                        continue
                    }
                }

                files.append(url)
            }
        }

        // Sort by modification date, newest first
        files.sort { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            return date1 > date2
        }

        return files
    }
}

/// Errors from crash report parsing.
public enum CrashReportError: Error, LocalizedError {
    case invalidFormat(String)
    case headerParseFailed(String)
    case bodyParseFailed(String)
    case fileNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .invalidFormat(let msg): return "Invalid crash report format: \(msg)"
        case .headerParseFailed(let msg): return "Failed to parse crash header: \(msg)"
        case .bodyParseFailed(let msg): return "Failed to parse crash body: \(msg)"
        case .fileNotFound(let path): return "Crash report not found: \(path)"
        }
    }
}
