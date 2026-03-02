import SwiftUI
import LogToolCore

struct LevelBadge: View {
    let level: LogLevel

    var body: some View {
        Text(level.rawValue.uppercased())
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(level == .default ? Color.primary : Color.white)
            .background(level.color.opacity(level == .default ? 0.15 : 1.0), in: Capsule())
    }
}
