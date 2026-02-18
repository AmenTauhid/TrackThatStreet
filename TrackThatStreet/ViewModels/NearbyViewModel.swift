import Foundation
import CoreLocation

nonisolated struct NearbyStop: Identifiable, Sendable {
    let stop: Stop
    let routeTag: String
    let routeTitle: String
    let distanceMeters: Double
    let walkingMinutes: Double

    var id: String { "\(routeTag):\(stop.tag)" }
}

@Observable
final class NearbyViewModel {
    var nearbyStops: [NearbyStop] = []
    var selectedStop: NearbyStop?
    var predictionGroups: [PredictionGroup] = []
    var isLoading = false

    private let apiClient = TTCAPIClient.shared
    private var routeConfigs: [String: Route] = [:]

    func loadRouteConfigs() async {
        isLoading = true
        await withTaskGroup(of: (String, Route)?.self) { group in
            for route in StreetcarRoute.allCases {
                group.addTask {
                    if let cached = CacheService.loadCachedRouteConfig(for: route.routeTag) {
                        return (route.routeTag, cached)
                    }
                    do {
                        let config = try await self.apiClient.fetchRouteConfig(routeTag: route.routeTag)
                        CacheService.cacheRouteConfig(config, for: route.routeTag)
                        return (route.routeTag, config)
                    } catch {
                        return nil
                    }
                }
            }
            for await result in group {
                if let (tag, config) = result {
                    routeConfigs[tag] = config
                }
            }
        }
        isLoading = false
    }

    func updateNearbyStops(location: CLLocation) {
        let walkingSpeedMPerMin = 83.0
        var allStops: [NearbyStop] = []

        for (routeTag, config) in routeConfigs {
            let routeTitle = StreetcarRoute(rawValue: routeTag)?.displayName ?? routeTag
            for stop in config.stops {
                let dist = ServiceAnalyzer.haversineDistance(
                    lat1: location.coordinate.latitude, lon1: location.coordinate.longitude,
                    lat2: stop.lat, lon2: stop.lon
                )
                let walkMin = dist / walkingSpeedMPerMin
                allStops.append(NearbyStop(
                    stop: stop,
                    routeTag: routeTag,
                    routeTitle: routeTitle,
                    distanceMeters: dist,
                    walkingMinutes: walkMin
                ))
            }
        }

        // Deduplicate by stop location (within 50m) keeping closest
        var seen: [String: NearbyStop] = [:]
        for stop in allStops.sorted(by: { $0.distanceMeters < $1.distanceMeters }) {
            let key = stop.stop.tag
            if seen[key] == nil {
                seen[key] = stop
            }
        }

        nearbyStops = Array(seen.values)
            .sorted { $0.distanceMeters < $1.distanceMeters }
            .prefix(10)
            .map { $0 }
    }

    func selectStop(_ stop: NearbyStop) async {
        selectedStop = stop
        do {
            predictionGroups = try await apiClient.fetchPredictions(
                routeTag: stop.routeTag,
                stopTag: stop.stop.tag
            )
        } catch {
            predictionGroups = []
        }
    }
}
