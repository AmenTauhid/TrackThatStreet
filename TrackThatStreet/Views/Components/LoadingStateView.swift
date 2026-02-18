import SwiftUI

struct LoadingStateView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(message, systemImage: "exclamationmark.triangle")
        } description: {
            if retryAction != nil {
                Text("Pull to refresh or tap retry.")
            }
        } actions: {
            if let retryAction {
                Button("Retry", action: retryAction)
                    .buttonStyle(.bordered)
            }
        }
    }
}
