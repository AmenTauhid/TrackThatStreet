import SwiftUI
import MapKit

@Observable
final class MapViewModel {
    var vehicles: [Vehicle] = []
    var selectedRouteTag: String?
    var isLoading = false
    var errorMessage: String?
    var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    ))
    var routeConfigs: [String: Route] = [:]
    var showHeatTrail = false

    private let apiClient = TTCAPIClient.shared
    private let scheduler = RefreshScheduler()

    var filteredVehicles: [Vehicle] {
        guard let tag = selectedRouteTag else { return vehicles }
        return vehicles.filter { $0.routeTag == tag }
    }

    var filteredRouteConfigs: [String: Route] {
        guard let tag = selectedRouteTag else { return routeConfigs }
        if let config = routeConfigs[tag] {
            return [tag: config]
        }
        return [:]
    }

    var heatTrailSegments: [ColoredSegment] {
        guard showHeatTrail,
              let tag = selectedRouteTag,
              let config = routeConfigs[tag] else { return [] }
        let routeVehicles = vehicles.filter { $0.routeTag == tag }
        return config.paths.flatMap { path in
            HeatTrailCalculator.coloredSegments(pathPoints: path, vehicles: routeVehicles)
        }
    }

    func startMonitoring() {
        Task {
            await fetchAllRouteConfigs()
            await fetchAllVehicles()
        }
        scheduler.start { [weak self] in
            await self?.fetchAllVehicles()
        }
    }

    func fetchAllRouteConfigs() async {
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
    }

    func stopMonitoring() {
        scheduler.stop()
    }

    func fetchAllVehicles() async {
        if vehicles.isEmpty {
            isLoading = true
        }
        errorMessage = nil

        var allVehicles: [Vehicle] = []
        await withTaskGroup(of: [Vehicle].self) { group in
            for route in StreetcarRoute.allCases {
                group.addTask {
                    do {
                        let result = try await self.apiClient.fetchVehicleLocations(routeTag: route.routeTag)
                        return result.vehicles
                    } catch {
                        return CacheService.loadCachedVehicles(for: route.routeTag)?.vehicles ?? []
                    }
                }
            }
            for await routeVehicles in group {
                allVehicles.append(contentsOf: routeVehicles)
            }
        }

        vehicles = allVehicles
        if vehicles.isEmpty {
            errorMessage = "Unable to load vehicle positions."
        }
        isLoading = false
    }

    var selectedVehicle: Vehicle?

    func selectRoute(_ routeTag: String?) {
        selectedRouteTag = selectedRouteTag == routeTag ? nil : routeTag
        selectedVehicle = nil
    }

    func selectVehicle(_ vehicle: Vehicle) {
        selectedVehicle = selectedVehicle?.id == vehicle.id ? nil : vehicle
    }

    func dismissVehicle() {
        selectedVehicle = nil
    }
}
