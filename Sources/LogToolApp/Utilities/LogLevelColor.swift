import SwiftUI
import LogToolCore

extension LogLevel {
    var color: Color {
        switch self {
        case .debug: return .gray
        case .info: return .blue
        case .default: return .primary
        case .error: return .orange
        case .fault: return .red
        }
    }
}
