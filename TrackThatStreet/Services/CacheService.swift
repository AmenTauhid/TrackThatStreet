import Foundation

nonisolated enum CacheService {
    private static let cacheDir: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TrackThatStreet", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    // MARK: - Route Config (long-lived cache)

    static func cacheRouteConfig(_ route: Route, for routeTag: String) {
        let url = cacheDir.appendingPathComponent("route_\(routeTag).json")
        guard let data = try? encoder.encode(route) else { return }
        try? data.write(to: url)
    }

    static func loadCachedRouteConfig(for routeTag: String) -> Route? {
        let url = cacheDir.appendingPathComponent("route_\(routeTag).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(Route.self, from: data)
    }

    // MARK: - Vehicles (stale after 5 min)

    private struct CachedVehicles: Codable {
        let vehicles: [Vehicle]
        let timestamp: Date
    }

    static func cacheVehicles(_ vehicles: [Vehicle], for routeTag: String) {
        let url = cacheDir.appendingPathComponent("vehicles_\(routeTag).json")
        let cached = CachedVehicles(vehicles: vehicles, timestamp: Date())
        guard let data = try? encoder.encode(cached) else { return }
        try? data.write(to: url)
    }

    static func loadCachedVehicles(for routeTag: String) -> (vehicles: [Vehicle], isStale: Bool)? {
        let url = cacheDir.appendingPathComponent("vehicles_\(routeTag).json")
        guard let data = try? Data(contentsOf: url),
              let cached = try? decoder.decode(CachedVehicles.self, from: data) else { return nil }
        let isStale = Date().timeIntervalSince(cached.timestamp) > 300
        return (cached.vehicles, isStale)
    }
}
