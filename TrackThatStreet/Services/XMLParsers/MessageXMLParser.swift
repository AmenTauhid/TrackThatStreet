import Foundation

nonisolated final class MessageXMLParser: NSObject, XMLParserDelegate {
    private var messages: [ServiceMessage] = []
    private var currentRouteTag = ""
    private var currentMessageId = ""
    private var currentPriority = ""
    private var currentText = ""
    private var inMessage = false
    private var inText = false

    private var parseError: Error?

    func parse(data: Data) throws -> [ServiceMessage] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        if let error = parseError {
            throw TTCAPIError.parsingError(error.localizedDescription)
        }
        return messages
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
            currentRouteTag = attributes["tag"] ?? ""

        case "message":
            currentMessageId = attributes["id"] ?? UUID().uuidString
            currentPriority = attributes["priority"] ?? "Normal"
            inMessage = true

        case "text":
            if inMessage {
                inText = true
                currentText = ""
            }

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inText {
            currentText += string
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        switch elementName {
        case "text":
            inText = false

        case "message":
            if inMessage {
                let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    let message = ServiceMessage(
                        id: currentMessageId,
                        text: trimmed,
                        priority: currentPriority,
                        routeTag: currentRouteTag
                    )
                    messages.append(message)
                }
                inMessage = false
            }

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }
}
