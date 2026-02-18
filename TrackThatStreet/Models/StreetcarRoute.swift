import Foundation

nonisolated enum StreetcarRoute: String, CaseIterable, Identifiable, Sendable {
    case r501 = "501"
    case r503 = "503"
    case r504 = "504"
    case r505 = "505"
    case r506 = "506"
    case r509 = "509"
    case r510 = "510"
    case r511 = "511"
    case r512 = "512"

    var id: String { rawValue }
    var routeTag: String { rawValue }

    var displayName: String {
        switch self {
        case .r501: "501 Queen"
        case .r503: "503 Kingston Rd"
        case .r504: "504 King"
        case .r505: "505 Dundas"
        case .r506: "506 Carlton"
        case .r509: "509 Harbourfront"
        case .r510: "510 Spadina"
        case .r511: "511 Bathurst"
        case .r512: "512 St Clair"
        }
    }

    var expectedHeadwayMinutes: Double {
        switch self {
        case .r501: 5
        case .r503: 15
        case .r504: 5
        case .r505: 8
        case .r506: 8
        case .r509: 10
        case .r510: 6
        case .r511: 8
        case .r512: 6
        }
    }
}
