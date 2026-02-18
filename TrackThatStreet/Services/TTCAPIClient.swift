import Foundation

nonisolated enum TTCAPIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case parsingError(String)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid URL"
        case .networkError(let error): "Network error: \(error.localizedDescription)"
        case .parsingError(let detail): "Parsing error: \(detail)"
        case .noData: "No data received"
        }
    }
}

nonisolated struct VehicleLocationResult: Sendable {
    let vehicles: [Vehicle]
    let lastTime: Int64
}

final class TTCAPIClient: Sendable {
    static let shared = TTCAPIClient()

    private let baseURL = "https://retro.umoiq.com/service/publicXMLFeed"
    nonisolated private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    nonisolated func fetchVehicleLocations(routeTag: String, sinceTime: Int64 = 0) async throws -> VehicleLocationResult {
        let urlString = "\(baseURL)?command=vehicleLocations&a=ttc&r=\(routeTag)&t=\(sinceTime)"
        guard let url = URL(string: urlString) else { throw TTCAPIError.invalidURL }

        let data: Data
        do {
            (data, _) = try await session.data(from: url)
        } catch {
            throw TTCAPIError.networkError(error)
        }

        let parser = VehicleXMLParser()
        return try parser.parse(data: data)
    }

    nonisolated func fetchRouteConfig(routeTag: String) async throws -> Route {
        let urlString = "\(baseURL)?command=routeConfig&a=ttc&r=\(routeTag)"
        guard let url = URL(string: urlString) else { throw TTCAPIError.invalidURL }

        let data: Data
        do {
            (data, _) = try await session.data(from: url)
        } catch {
            throw TTCAPIError.networkError(error)
        }

        let parser = RouteConfigXMLParser()
        return try parser.parse(data: data)
    }

    nonisolated func fetchPredictions(routeTag: String, stopTag: String) async throws -> [PredictionGroup] {
        let urlString = "\(baseURL)?command=predictions&a=ttc&r=\(routeTag)&s=\(stopTag)"
        guard let url = URL(string: urlString) else { throw TTCAPIError.invalidURL }

        let data: Data
        do {
            (data, _) = try await session.data(from: url)
        } catch {
            throw TTCAPIError.networkError(error)
        }

        let parser = PredictionXMLParser()
        return try parser.parse(data: data)
    }

    nonisolated func fetchMessages(routeTag: String) async throws -> [ServiceMessage] {
        let urlString = "\(baseURL)?command=messages&a=ttc&r=\(routeTag)"
        guard let url = URL(string: urlString) else { throw TTCAPIError.invalidURL }

        let data: Data
        do {
            (data, _) = try await session.data(from: url)
        } catch {
            throw TTCAPIError.networkError(error)
        }

        let parser = MessageXMLParser()
        return try parser.parse(data: data)
    }
}
