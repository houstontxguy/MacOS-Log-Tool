import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case browser = "Log Browser"
    case stream = "Live Stream"
    case stats = "Dashboard"
    case discover = "Subsystems"
    case crashes = "Crash Reports"
    case analysis = "AI Analysis"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .browser: return "doc.text.magnifyingglass"
        case .stream: return "waveform.path"
        case .stats: return "chart.bar"
        case .discover: return "list.bullet.indent"
        case .crashes: return "exclamationmark.triangle"
        case .analysis: return "brain"
        }
    }
}

struct Sidebar: View {
    @Binding var selection: SidebarItem?

    var body: some View {
        List(SidebarItem.allCases, selection: $selection) { item in
            Label(item.rawValue, systemImage: item.icon)
                .tag(item)
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
    }
}
