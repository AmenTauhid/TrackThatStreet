import ActivityKit
import Foundation

@Observable
final class LiveActivityService {
    private var currentActivity: Activity<StreetcarArrivalAttributes>?
    var isTracking: Bool { currentActivity != nil }

    func startTracking(routeName: String, stopName: String, routeTag: String, prediction: Prediction) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = StreetcarArrivalAttributes(
            routeName: routeName,
            stopName: stopName,
            routeTag: routeTag
        )
        let state = StreetcarArrivalAttributes.ContentState(
            minutes: prediction.minutes,
            vehicleId: prediction.vehicle,
            updatedAt: Date()
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil)
            )
            currentActivity = activity
        } catch {
            // Live Activity not available
        }
    }

    func update(prediction: Prediction) {
        guard let activity = currentActivity else { return }
        let state = StreetcarArrivalAttributes.ContentState(
            minutes: prediction.minutes,
            vehicleId: prediction.vehicle,
            updatedAt: Date()
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    func stopTracking() {
        guard let activity = currentActivity else { return }
        let finalState = StreetcarArrivalAttributes.ContentState(
            minutes: 0,
            vehicleId: "",
            updatedAt: Date()
        )
        Task {
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }
}
