import SwiftUI

struct ContentView: View {
    @State private var selection: SidebarSelection? = .view(.browser)
    @State private var poller = ActiveSubsystemPoller()

    var body: some View {
        NavigationSplitView {
            Sidebar(selection: $selection)
        } detail: {
            Group {
                switch selection {
                case .view(let item):
                    switch item {
                    case .browser:
                        LogBrowserView()
                    case .stream:
                        StreamView()
                    case .stats:
                        StatsView()
                    case .healthCheck:
                        HealthCheckView()
                    case .discover:
                        DiscoverView()
                    case .crashes:
                        CrashView()
                    case .captureAnalyze:
                        CaptureAnalyzeView()
                    case .analysis:
                        AnalysisView()
                    }
                case .diagnostic(let presetID):
                    if let preset = DiagnosticPreset.allPresets.first(where: { $0.id == presetID }) {
                        DiagnosticResultView(preset: preset)
                    } else {
                        Text("Unknown diagnostic preset")
                            .foregroundStyle(.secondary)
                    }
                case nil:
                    Text("Select an item from the sidebar")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .environment(poller)
        .task {
            poller.start()
        }
    }
}
