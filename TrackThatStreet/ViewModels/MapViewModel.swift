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

    private let apiClient = TTCAPIClient.shared
    private let scheduler = RefreshScheduler()

    var filteredVehicles: [Vehicle] {
        guard let tag = selectedRouteTag else { return vehicles }
        return vehicles.filter { $0.routeTag == tag }
    }

    func startMonitoring() {
        Task { await fetchAllVehicles() }
        scheduler.start { [weak self] in
            await self?.fetchAllVehicles()
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

    func selectRoute(_ routeTag: String?) {
        selectedRouteTag = selectedRouteTag == routeTag ? nil : routeTag
    }
}
