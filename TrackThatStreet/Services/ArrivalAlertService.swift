import UIKit

@Observable
final class ArrivalAlertService {
    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "arrivalAlertEnabled") }
    }

    private var alertedVehicles: Set<String> = []

    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "arrivalAlertEnabled")
    }

    func checkAndAlert(predictions: [Prediction]) {
        guard isEnabled else { return }

        for prediction in predictions {
            guard prediction.minutes <= 2, prediction.minutes >= 0 else { continue }
            let key = prediction.vehicle
            guard !alertedVehicles.contains(key) else { continue }

            alertedVehicles.insert(key)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }

        // Clear alerts for vehicles no longer in predictions
        let currentVehicles = Set(predictions.map { $0.vehicle })
        alertedVehicles = alertedVehicles.intersection(currentVehicles)
    }
}
