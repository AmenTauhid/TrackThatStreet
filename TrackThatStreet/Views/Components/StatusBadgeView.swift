import SwiftUI

struct StatusBadgeView: View {
    let status: ServiceStatus

    var body: some View {
        Text(status.label)
            .font(TTCFonts.badge)
            .foregroundStyle(status == .fair ? .black : .white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(status.color, in: Capsule())
            .accessibilityLabel("Service status: \(status.label)")
    }
}
