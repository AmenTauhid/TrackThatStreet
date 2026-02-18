import Foundation

@Observable
final class RouteDetailViewModel {
    let streetcarRoute: StreetcarRoute

    var routeConfig: Route?
    var vehicles: [Vehicle] = []
    var predictionGroups: [PredictionGroup] = []
    var selectedDirectionTag: String? {
        didSet {
            if oldValue != selectedDirectionTag {
                selectedStopTag = nil
            }
        }
    }
    var selectedStopTag: String?
    var status: ServiceStatus = .good
    var bunchingAlerts: [BunchingAlert] = []
    var gapAlerts: [GapAlert] = []
    var serviceMessages: [ServiceMessage] = []
    var isLoading = false
    var errorMessage: String?

    let arrivalAlertService = ArrivalAlertService()
    let liveActivityService = LiveActivityService()

    private let apiClient = TTCAPIClient.shared
    private let scheduler = RefreshScheduler()

    var uiDirections: [Direction] {
        routeConfig?.directions.filter { $0.useForUI } ?? []
    }

    var filteredVehicles: [Vehicle] {
        guard let dirTag = selectedDirectionTag else { return vehicles }
        return vehicles.filter { $0.dirTag == dirTag }
    }

    var stopsForSelectedDirection: [Stop] {
        guard let config = routeConfig,
              let dirTag = selectedDirectionTag,
              let dir = config.directions.first(where: { $0.tag == dirTag }) else {
            return routeConfig?.stops ?? []
        }
        let stopsByTag = Dictionary(uniqueKeysWithValues: config.stops.map { ($0.tag, $0) })
        return dir.stopTags.compactMap { stopsByTag[$0] }
    }

    var selectedStop: Stop? {
        guard let tag = selectedStopTag else { return nil }
        return routeConfig?.stops.first { $0.tag == tag }
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
        liveActivityService.stopTracking()
    }

    func trackPrediction(_ prediction: Prediction) {
        let stopName = selectedStop?.title ?? "Stop"
        liveActivityService.startTracking(
            routeName: streetcarRoute.displayName,
            stopName: stopName,
            routeTag: streetcarRoute.routeTag,
            prediction: prediction
        )
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

        do {
            serviceMessages = try await apiClient.fetchMessages(routeTag: streetcarRoute.routeTag)
        } catch {
            // Non-critical, keep empty
        }

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

    func fetchPredictions() async {
        guard let config = routeConfig else { return }
        let stopTag = selectedStopTag ?? pickRepresentativeStop(config: config)
        guard let stopTag else { return }

        do {
            predictionGroups = try await apiClient.fetchPredictions(
                routeTag: streetcarRoute.routeTag,
                stopTag: stopTag
            )
            let allPredictions = predictionGroups.flatMap { $0.predictions }
            arrivalAlertService.checkAndAlert(predictions: allPredictions)

            if liveActivityService.isTracking, let first = allPredictions.sorted(by: { $0.seconds < $1.seconds }).first {
                liveActivityService.update(prediction: first)
            }
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
