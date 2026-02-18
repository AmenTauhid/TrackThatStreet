import Foundation

@Observable
final class RefreshScheduler {
    private var timer: Timer?
    private(set) var isRunning = false

    func start(interval: TimeInterval = 10, action: @escaping @Sendable () async -> Void) {
        stop()
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { await action() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
}
