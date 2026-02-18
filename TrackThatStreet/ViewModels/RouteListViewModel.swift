import Foundation

@Observable
final class RouteListViewModel {
    var routeStatuses: [String: ServiceStatus] = [:]
    var vehicleCounts: [String: Int] = [:]
    var averageWaits: [String: Double] = [:]
    var isLoading = false
    var errorMessage: String?

    private let apiClient = TTCAPIClient.shared
    private let scheduler = RefreshScheduler()

    func startMonitoring() {
        Task { await fetchAllRoutes() }
        scheduler.start { [weak self] in
            await self?.fetchAllRoutes()
        }
    }

    func stopMonitoring() {
        scheduler.stop()
    }

    func fetchAllRoutes() async {
        if vehicleCounts.isEmpty {
            isLoading = true
        }
        errorMessage = nil

        await withTaskGroup(of: (StreetcarRoute, [Vehicle])?.self) { group in
            for route in StreetcarRoute.allCases {
                group.addTask {
                    do {
                        let result = try await self.apiClient.fetchVehicleLocations(routeTag: route.routeTag)
                        CacheService.cacheVehicles(result.vehicles, for: route.routeTag)
                        return (route, result.vehicles)
                    } catch {
                        if let cached = CacheService.loadCachedVehicles(for: route.routeTag) {
                            return (route, cached.vehicles)
                        }
                        return nil
                    }
                }
            }

            for await result in group {
                guard let (route, vehicles) = result else { continue }
                vehicleCounts[route.routeTag] = vehicles.count
                routeStatuses[route.routeTag] = ServiceAnalyzer.analyzeStatus(vehicles: vehicles, route: route)
                averageWaits[route.routeTag] = ServiceAnalyzer.estimateAverageWait(vehicleCount: vehicles.count, route: route)
            }
        }

        if vehicleCounts.isEmpty {
            errorMessage = "Unable to load streetcar data. Check your connection."
        }
        isLoading = false
    }
}
