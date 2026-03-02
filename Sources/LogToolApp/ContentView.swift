import SwiftUI

struct ContentView: View {
    @State private var selection: SidebarItem? = .browser

    var body: some View {
        NavigationSplitView {
            Sidebar(selection: $selection)
        } detail: {
            Group {
                switch selection {
                case .browser:
                    LogBrowserView()
                case .stream:
                    StreamView()
                case .stats:
                    StatsView()
                case .discover:
                    DiscoverView()
                case .crashes:
                    CrashView()
                case .analysis:
                    AnalysisView()
                case nil:
                    Text("Select an item from the sidebar")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
