import Foundation

nonisolated final class VehicleXMLParser: NSObject, XMLParserDelegate {
    private var vehicles: [Vehicle] = []
    private var lastTime: Int64 = 0
    private var parseError: Error?

    func parse(data: Data) throws -> VehicleLocationResult {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        if let error = parseError {
            throw TTCAPIError.parsingError(error.localizedDescription)
        }
        return VehicleLocationResult(vehicles: vehicles, lastTime: lastTime)
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String]
    ) {
        switch elementName {
        case "vehicle":
            guard let id = attributes["id"],
                  let routeTag = attributes["routeTag"],
                  let latStr = attributes["lat"], let lat = Double(latStr),
                  let lonStr = attributes["lon"], let lon = Double(lonStr),
                  let headingStr = attributes["heading"], let heading = Int(headingStr),
                  let speedStr = attributes["speedKmHr"], let speed = Int(speedStr),
                  let secsStr = attributes["secsSinceReport"], let secs = Int(secsStr)
            else { return }

            let vehicle = Vehicle(
                id: id,
                routeTag: routeTag,
                dirTag: attributes["dirTag"],
                lat: lat,
                lon: lon,
                heading: heading,
                speedKmHr: speed,
                secsSinceReport: secs,
                predictable: attributes["predictable"] == "true"
            )
            vehicles.append(vehicle)

        case "lastTime":
            if let timeStr = attributes["time"], let time = Int64(timeStr) {
                lastTime = time
            }

        case "Error":
            break

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }
}
