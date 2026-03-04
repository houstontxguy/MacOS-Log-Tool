import Foundation
import LogToolCore

struct DiagnosticPreset: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let subsystems: [String]
    let processes: [String]
    let keywords: [String]
    let defaultLevel: LogLevel?

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: DiagnosticPreset, rhs: DiagnosticPreset) -> Bool { lhs.id == rhs.id }

    func buildFilter(lastMinutes: Int = 15) -> LogFilter {
        var predicateParts: [String] = []
        for s in subsystems {
            predicateParts.append("subsystem == \"\(s)\"")
        }
        for p in processes {
            predicateParts.append("process == \"\(p)\"")
        }
        for kw in keywords {
            predicateParts.append("eventMessage CONTAINS \"\(kw)\"")
        }

        let predicate = predicateParts.isEmpty ? nil : predicateParts.joined(separator: " OR ")
        return LogFilter(
            level: defaultLevel,
            lastInterval: TimeInterval(lastMinutes * 60),
            predicate: predicate
        )
    }

    // MARK: - All Presets

    static let allPresets: [DiagnosticPreset] = [
        wifi, bluetooth, sleepWake, loginAuth, diskStorage,
        network, windowServer, timeMachine, spotlight,
        softwareUpdate, security, kernelSystem,
    ]

    static let wifi = DiagnosticPreset(
        id: "wifi", name: "Wi-Fi Issues", icon: "wifi.exclamationmark",
        subsystems: ["com.apple.WiFiManager", "com.apple.wifi"],
        processes: ["airportd"], keywords: [], defaultLevel: nil
    )

    static let bluetooth = DiagnosticPreset(
        id: "bluetooth", name: "Bluetooth", icon: "wave.3.right",
        subsystems: ["com.apple.bluetooth"],
        processes: ["blued", "bluetoothd"], keywords: [], defaultLevel: nil
    )

    static let sleepWake = DiagnosticPreset(
        id: "sleep_wake", name: "Sleep / Wake", icon: "moon.zzz",
        subsystems: [],
        processes: ["powerd", "kernel"], keywords: ["Wake reason"], defaultLevel: nil
    )

    static let loginAuth = DiagnosticPreset(
        id: "login_auth", name: "Login / Auth", icon: "person.badge.key",
        subsystems: ["com.apple.login", "com.apple.loginwindow.logging"],
        processes: ["loginwindow", "opendirectoryd", "authd", "tccd"],
        keywords: [], defaultLevel: nil
    )

    static let diskStorage = DiagnosticPreset(
        id: "disk_storage", name: "Disk / Storage", icon: "externaldrive",
        subsystems: ["com.apple.StorageKit"],
        processes: ["fsck_apfs", "diskutil"], keywords: [], defaultLevel: nil
    )

    static let network = DiagnosticPreset(
        id: "network", name: "Network", icon: "network",
        subsystems: ["com.apple.network"],
        processes: ["mDNSResponder"], keywords: [], defaultLevel: nil
    )

    static let windowServer = DiagnosticPreset(
        id: "window_server", name: "WindowServer / Display", icon: "display",
        subsystems: [],
        processes: ["WindowServer"], keywords: [], defaultLevel: nil
    )

    static let timeMachine = DiagnosticPreset(
        id: "time_machine", name: "Time Machine", icon: "clock.arrow.circlepath",
        subsystems: ["com.apple.TimeMachine"],
        processes: [], keywords: [], defaultLevel: nil
    )

    static let spotlight = DiagnosticPreset(
        id: "spotlight", name: "Spotlight", icon: "magnifyingglass",
        subsystems: [],
        processes: ["mds", "mds_stores", "mdworker_shared"],
        keywords: [], defaultLevel: nil
    )

    static let softwareUpdate = DiagnosticPreset(
        id: "software_update", name: "Software Update", icon: "arrow.down.app",
        subsystems: ["com.apple.SoftwareUpdate"],
        processes: ["softwareupdated"], keywords: [], defaultLevel: nil
    )

    static let security = DiagnosticPreset(
        id: "security", name: "Security", icon: "lock.shield",
        subsystems: ["com.apple.securityd"],
        processes: ["sshd", "tccd", "screensharingd"],
        keywords: [], defaultLevel: nil
    )

    static let kernelSystem = DiagnosticPreset(
        id: "kernel_system", name: "Kernel / System", icon: "cpu",
        subsystems: [],
        processes: ["kernel_task", "launchd"],
        keywords: [], defaultLevel: .fault
    )

    // MARK: - Curated Suggestions

    static let commonSubsystems: [String] = [
        "com.apple.WiFiManager",
        "com.apple.wifi",
        "com.apple.bluetooth",
        "com.apple.login",
        "com.apple.loginwindow.logging",
        "com.apple.StorageKit",
        "com.apple.network",
        "com.apple.TimeMachine",
        "com.apple.SoftwareUpdate",
        "com.apple.securityd",
        "com.apple.SystemConfiguration",
        "com.apple.coredata",
        "com.apple.defaults",
        "com.apple.xpc",
    ]

    static let commonProcesses: [String] = [
        "airportd",
        "blued",
        "bluetoothd",
        "powerd",
        "kernel",
        "loginwindow",
        "opendirectoryd",
        "authd",
        "tccd",
        "fsck_apfs",
        "diskutil",
        "mDNSResponder",
        "WindowServer",
        "mds",
        "mds_stores",
        "softwareupdated",
        "sshd",
        "kernel_task",
        "launchd",
        "Finder",
        "Safari",
    ]
}
