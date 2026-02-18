import Foundation

nonisolated final class RouteConfigXMLParser: NSObject, XMLParserDelegate {
    private var routeTag = ""
    private var routeTitle = ""
    private var routeColor = ""
    private var routeOppositeColor = ""
    private var stops: [Stop] = []
    private var directions: [Direction] = []
    private var paths: [[PathPoint]] = []

    private var currentDirectionTag = ""
    private var currentDirectionTitle = ""
    private var currentDirectionName = ""
    private var currentDirectionUseForUI = false
    private var currentDirectionStopTags: [String] = []
    private var inDirection = false

    private var currentPath: [PathPoint] = []
    private var inPath = false

    private var parseError: Error?

    func parse(data: Data) throws -> Route {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        if let error = parseError {
            throw TTCAPIError.parsingError(error.localizedDescription)
        }

        return Route(
            tag: routeTag,
            title: routeTitle,
            color: routeColor,
            oppositeColor: routeOppositeColor,
            stops: stops,
            directions: directions,
            paths: paths
        )
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String]
    ) {
        switch elementName {
        case "route":
            routeTag = attributes["tag"] ?? ""
            routeTitle = attributes["title"] ?? ""
            routeColor = attributes["color"] ?? ""
            routeOppositeColor = attributes["oppositeColor"] ?? ""

        case "stop":
            if inDirection {
                if let tag = attributes["tag"] {
                    currentDirectionStopTags.append(tag)
                }
            } else {
                guard let tag = attributes["tag"],
                      let title = attributes["title"],
                      let latStr = attributes["lat"], let lat = Double(latStr),
                      let lonStr = attributes["lon"], let lon = Double(lonStr)
                else { return }

                let stop = Stop(
                    tag: tag,
                    title: title,
                    lat: lat,
                    lon: lon,
                    stopId: attributes["stopId"]
                )
                stops.append(stop)
            }

        case "direction":
            inDirection = true
            currentDirectionTag = attributes["tag"] ?? ""
            currentDirectionTitle = attributes["title"] ?? ""
            currentDirectionName = attributes["name"] ?? ""
            currentDirectionUseForUI = attributes["useForUI"] == "true"
            currentDirectionStopTags = []

        case "path":
            inPath = true
            currentPath = []

        case "point":
            if inPath,
               let latStr = attributes["lat"], let lat = Double(latStr),
               let lonStr = attributes["lon"], let lon = Double(lonStr) {
                currentPath.append(PathPoint(lat: lat, lon: lon))
            }

        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        switch elementName {
        case "direction":
            let direction = Direction(
                tag: currentDirectionTag,
                title: currentDirectionTitle,
                name: currentDirectionName,
                useForUI: currentDirectionUseForUI,
                stopTags: currentDirectionStopTags
            )
            directions.append(direction)
            inDirection = false

        case "path":
            if !currentPath.isEmpty {
                paths.append(currentPath)
            }
            inPath = false

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }
}
