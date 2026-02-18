import SwiftUI

struct ServiceAlertView: View {
    let message: ServiceMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.blue)
            Text(message.text)
                .font(TTCFonts.caption)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel("Service advisory: \(message.text)")
    }
}
