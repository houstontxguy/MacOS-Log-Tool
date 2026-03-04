import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case browser = "Log Browser"
    case stream = "Live Stream"
    case stats = "Dashboard"
    case healthCheck = "Health Check"
    case discover = "Subsystems"
    case crashes = "Crash Reports"
    case captureAnalyze = "Capture & Analyze"
    case analysis = "AI Analysis"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .browser: return "doc.text.magnifyingglass"
        case .stream: return "waveform.path"
        case .stats: return "chart.bar"
        case .healthCheck: return "heart.text.square"
        case .discover: return "list.bullet.indent"
        case .crashes: return "exclamationmark.triangle"
        case .captureAnalyze: return "arrow.down.doc"
        case .analysis: return "brain"
        }
    }
}

enum SidebarSelection: Hashable {
    case view(SidebarItem)
    case diagnostic(String) // preset ID
}

struct Sidebar: View {
    @Binding var selection: SidebarSelection?

    var body: some View {
        List(selection: $selection) {
            Section("Views") {
                ForEach(SidebarItem.allCases) { item in
                    Label(item.rawValue, systemImage: item.icon)
                        .tag(SidebarSelection.view(item))
                }
            }

            Section("Quick Diagnostics") {
                ForEach(DiagnosticPreset.allPresets) { preset in
                    Label(preset.name, systemImage: preset.icon)
                        .tag(SidebarSelection.diagnostic(preset.id))
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 220)
    }
}
