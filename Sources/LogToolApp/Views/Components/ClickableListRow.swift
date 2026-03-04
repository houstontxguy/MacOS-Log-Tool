import SwiftUI

struct ClickableListRow: View {
    let name: String
    let count: Int
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(name)
                    .font(.caption)
                    .lineLimit(1)
                Spacer()
                Text("\(count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 2)
            .background(isHovering ? Color.accentColor.opacity(0.08) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
