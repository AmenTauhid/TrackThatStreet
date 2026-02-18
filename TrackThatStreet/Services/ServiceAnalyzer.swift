import Foundation

nonisolated enum ServiceAnalyzer {
    static func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371000.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
            sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }

    static func detectBunching(vehicles: [Vehicle]) -> [BunchingAlert] {
        let grouped = Dictionary(grouping: vehicles.filter { $0.dirTag != nil }, by: { $0.dirTag! })
        var alerts: [BunchingAlert] = []

        for (_, dirVehicles) in grouped {
            for i in 0..<dirVehicles.count {
                for j in (i + 1)..<dirVehicles.count {
                    let dist = haversineDistance(
                        lat1: dirVehicles[i].lat, lon1: dirVehicles[i].lon,
                        lat2: dirVehicles[j].lat, lon2: dirVehicles[j].lon
                    )
                    if dist < 500 {
                        alerts.append(BunchingAlert(
                            vehicleA: dirVehicles[i],
                            vehicleB: dirVehicles[j],
                            distanceMeters: dist
                        ))
                    }
                }
            }
        }
        return alerts
    }

    static func detectGaps(vehicles: [Vehicle], route: StreetcarRoute) -> [GapAlert] {
        let grouped = Dictionary(grouping: vehicles.filter { $0.dirTag != nil }, by: { $0.dirTag! })
        var alerts: [GapAlert] = []

        for (dirTag, dirVehicles) in grouped {
            guard dirVehicles.count >= 2 else {
                if dirVehicles.count <= 1 {
                    alerts.append(GapAlert(
                        directionTitle: dirTag,
                        estimatedGapMinutes: route.expectedHeadwayMinutes * 3
                    ))
                }
                continue
            }

            let sorted = dirVehicles.sorted { $0.lat != $1.lat ? $0.lat < $1.lat : $0.lon < $1.lon }
            for i in 0..<(sorted.count - 1) {
                let dist = haversineDistance(
                    lat1: sorted[i].lat, lon1: sorted[i].lon,
                    lat2: sorted[i + 1].lat, lon2: sorted[i + 1].lon
                )
                let speed = max(Double(sorted[i].speedKmHr), 15.0) * 1000.0 / 60.0
                let gapMinutes = dist / speed
                if gapMinutes > 15 {
                    alerts.append(GapAlert(
                        directionTitle: dirTag,
                        estimatedGapMinutes: gapMinutes
                    ))
                }
            }
        }
        return alerts
    }

    static func analyzeStatus(vehicles: [Vehicle], route: StreetcarRoute) -> ServiceStatus {
        if vehicles.isEmpty {
            return .poor
        }

        let gaps = detectGaps(vehicles: vehicles, route: route)
        let bunching = detectBunching(vehicles: vehicles)

        if !gaps.isEmpty {
            return .poor
        } else if !bunching.isEmpty {
            return .fair
        }
        return .good
    }

    static func estimateAverageWait(vehicleCount: Int, route: StreetcarRoute) -> Double {
        guard vehicleCount > 0 else { return route.expectedHeadwayMinutes * 2 }
        let expectedCount = max(60.0 / route.expectedHeadwayMinutes, 1)
        return route.expectedHeadwayMinutes * (expectedCount / Double(vehicleCount))
    }
}
