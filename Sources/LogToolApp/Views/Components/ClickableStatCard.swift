import SwiftUI

struct ClickableStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            GroupBox {
                VStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                    Text(value)
                        .font(.title.monospacedDigit().bold())
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(isHovering ? 0.5 : 0), lineWidth: 2)
            )
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
