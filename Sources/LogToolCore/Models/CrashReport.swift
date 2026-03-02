import Foundation

/// Represents a parsed macOS crash report from a .ips file.
/// Modern .ips files use a two-part format: a JSON header line followed by a JSON body.
public struct CrashReport: Sendable {
    public let header: Header
    public let body: Body
    public let filePath: String

    /// The header (first line) of a .ips crash report.
    public struct Header: Codable, Sendable {
        public let bugType: String?
        public let timestamp: String?
        public let os_version: String?
        public let incident_id: String?
        public let name: String?

        enum CodingKeys: String, CodingKey {
            case bugType = "bug_type"
            case timestamp
            case os_version
            case incident_id
            case name
        }
    }

    /// The body (remaining JSON) of a .ips crash report.
    public struct Body: Codable, Sendable {
        public let pid: Int?
        public let procName: String?
        public let procPath: String?
        public let bundleInfo: BundleInfo?
        public let storeInfo: StoreInfo?
        public let parentProc: String?
        public let parentPid: Int?
        public let coalitionName: String?
        public let crashReporterKey: String?
        public let responsiblePid: Int?
        public let responsibleProc: String?
        public let cpuType: String?
        public let exception: ExceptionInfo?
        public let termination: TerminationInfo?
        public let faultingThread: Int?
        public let threads: [ThreadInfo]?
        public let usedImages: [ImageInfo]?
        public let captureTime: String?
        public let modelCode: String?
        public let isCorpse: Int?

        public struct BundleInfo: Codable, Sendable {
            public let CFBundleIdentifier: String?
            public let CFBundleVersion: String?
            public let CFBundleShortVersionString: String?
        }

        public struct StoreInfo: Codable, Sendable {
            public let deviceIdentifierForVendor: String?
            public let thirdParty: Bool?
        }

        public struct ExceptionInfo: Codable, Sendable {
            public let type: String?
            public let signal: String?
            public let codes: String?
            public let subtype: String?
        }

        public struct TerminationInfo: Codable, Sendable {
            public let signal: String?
            public let code: Int?
            public let namespace: String?
            public let indicator: String?
            public let byProc: String?
            public let byPid: Int?
        }

        public struct ThreadInfo: Codable, Sendable {
            public let id: Int?
            public let name: String?
            public let triggered: Bool?
            public let threadState: ThreadState?
            public let queue: String?
            public let frames: [FrameInfo]?

            public struct ThreadState: Codable, Sendable {
                public let flavor: String?
            }
        }

        public struct FrameInfo: Codable, Sendable {
            public let imageOffset: Int?
            public let imageIndex: Int?
            public let symbol: String?
            public let symbolLocation: Int?
        }

        public struct ImageInfo: Codable, Sendable {
            public let source: String?
            public let arch: String?
            public let base: UInt64?
            public let size: UInt64?
            public let uuid: String?
            public let path: String?
            public let name: String?
        }
    }

    /// Summary of the crash for display.
    public var summary: String {
        let proc = body.procName ?? header.name ?? "Unknown"
        let exception = body.exception?.type ?? "Unknown"
        let signal = body.exception?.signal ?? body.termination?.signal ?? "?"
        let time = header.timestamp ?? body.captureTime ?? "?"
        return "\(proc) — \(exception) (\(signal)) at \(time)"
    }

    /// The process name.
    public var processName: String {
        body.procName ?? header.name ?? "Unknown"
    }

    /// The crash timestamp as Date.
    public var date: Date? {
        guard let ts = header.timestamp ?? body.captureTime else { return nil }
        return CrashReport.dateFormatter.date(from: ts)
            ?? CrashReport.fallbackFormatter.date(from: ts)
    }

    private static let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let fallbackFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
