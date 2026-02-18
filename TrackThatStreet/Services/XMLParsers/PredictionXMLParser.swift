import Foundation

nonisolated final class PredictionXMLParser: NSObject, XMLParserDelegate {
    private var groups: [PredictionGroup] = []

    private var currentStopTitle = ""
    private var currentDirectionTitle = ""
    private var currentPredictions: [Prediction] = []
    private var inDirection = false
    private var inPredictions = false

    private var parseError: Error?

    func parse(data: Data) throws -> [PredictionGroup] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        if let error = parseError {
            throw TTCAPIError.parsingError(error.localizedDescription)
        }
        return groups
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String]
    ) {
        switch elementName {
        case "predictions":
            currentStopTitle = attributes["stopTitle"] ?? ""
            inPredictions = true

        case "direction":
            if inPredictions {
                currentDirectionTitle = attributes["title"] ?? ""
                currentPredictions = []
                inDirection = true
            }

        case "prediction":
            if inDirection {
                guard let epochStr = attributes["epochTime"], let epoch = Int64(epochStr),
                      let secsStr = attributes["seconds"], let secs = Int(secsStr),
                      let minsStr = attributes["minutes"], let mins = Int(minsStr),
                      let vehicle = attributes["vehicle"]
                else { return }

                let prediction = Prediction(
                    epochTime: epoch,
                    seconds: secs,
                    minutes: mins,
                    vehicle: vehicle,
                    dirTag: attributes["dirTag"],
                    branch: attributes["branch"]
                )
                currentPredictions.append(prediction)
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
            if inPredictions && inDirection {
                let group = PredictionGroup(
                    directionTitle: currentDirectionTitle,
                    stopTitle: currentStopTitle,
                    predictions: currentPredictions
                )
                groups.append(group)
                inDirection = false
            }

        case "predictions":
            inPredictions = false

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }
}
