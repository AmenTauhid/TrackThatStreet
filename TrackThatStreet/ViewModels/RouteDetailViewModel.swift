import Foundation

@Observable
final class RouteDetailViewModel {
    let streetcarRoute: StreetcarRoute

    var routeConfig: Route?
    var vehicles: [Vehicle] = []
    var predictionGroups: [PredictionGroup] = []
    var selectedDirectionTag: String?
    var status: ServiceStatus = .good
    var bunchingAlerts: [BunchingAlert] = []
    var gapAlerts: [GapAlert] = []
    var isLoading = false
    var errorMessage: String?

    private let apiClient = TTCAPIClient.shared
    private let scheduler = RefreshScheduler()

    var uiDirections: [Direction] {
        routeConfig?.directions.filter { $0.useForUI } ?? []
    }

    var filteredVehicles: [Vehicle] {
        guard let dirTag = selectedDirectionTag else { return vehicles }
        return vehicles.filter { $0.dirTag == dirTag }
    }

    var activePredictions: [Prediction] {
        let dirTitle = uiDirections.first(where: { $0.tag == selectedDirectionTag })?.title
        if let dirTitle {
            return predictionGroups
                .filter { $0.directionTitle == dirTitle }
                .flatMap { $0.predictions }
                .sorted { $0.seconds < $1.seconds }
        }
        return predictionGroups.flatMap { $0.predictions }.sorted { $0.seconds < $1.seconds }
    }

    init(streetcarRoute: StreetcarRoute) {
        self.streetcarRoute = streetcarRoute
    }

    func startMonitoring() {
        Task { await loadAll() }
        scheduler.start { [weak self] in
            await self?.refresh()
        }
    }

    func stopMonitoring() {
        scheduler.stop()
    }

    func loadAll() async {
        isLoading = true
        errorMessage = nil

        do {
            let config = try await apiClient.fetchRouteConfig(routeTag: streetcarRoute.routeTag)
            CacheService.cacheRouteConfig(config, for: streetcarRoute.routeTag)
            routeConfig = config

            if selectedDirectionTag == nil, let first = config.directions.first(where: { $0.useForUI }) {
                selectedDirectionTag = first.tag
            }
        } catch {
            if let cached = CacheService.loadCachedRouteConfig(for: streetcarRoute.routeTag) {
                routeConfig = cached
                if selectedDirectionTag == nil, let first = cached.directions.first(where: { $0.useForUI }) {
                    selectedDirectionTag = first.tag
                }
            }
        }

        await refresh()
        isLoading = false
    }

    func refresh() async {
        do {
            let result = try await apiClient.fetchVehicleLocations(routeTag: streetcarRoute.routeTag)
            vehicles = result.vehicles
            CacheService.cacheVehicles(result.vehicles, for: streetcarRoute.routeTag)
        } catch {
            if let cached = CacheService.loadCachedVehicles(for: streetcarRoute.routeTag) {
                vehicles = cached.vehicles
            }
        }

        status = ServiceAnalyzer.analyzeStatus(vehicles: vehicles, route: streetcarRoute)
        bunchingAlerts = ServiceAnalyzer.detectBunching(vehicles: vehicles)
        gapAlerts = ServiceAnalyzer.detectGaps(vehicles: vehicles, route: streetcarRoute)

        await fetchPredictions()
    }

    private func fetchPredictions() async {
        guard let config = routeConfig else { return }
        let stopTag = pickRepresentativeStop(config: config)
        guard let stopTag else { return }

        do {
            predictionGroups = try await apiClient.fetchPredictions(
                routeTag: streetcarRoute.routeTag,
                stopTag: stopTag
            )
        } catch {
            // Keep existing predictions on error
        }
    }

    private func pickRepresentativeStop(config: Route) -> String? {
        if let dirTag = selectedDirectionTag,
           let dir = config.directions.first(where: { $0.tag == dirTag }),
           !dir.stopTags.isEmpty {
            let midIndex = dir.stopTags.count / 2
            return dir.stopTags[midIndex]
        }
        return config.stops.first?.tag
    }
}
