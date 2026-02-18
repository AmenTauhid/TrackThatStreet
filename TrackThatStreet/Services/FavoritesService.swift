import Foundation

@Observable
final class FavoritesService {
    static let shared = FavoritesService()

    var favoriteRouteTags: Set<String> {
        didSet { save() }
    }

    var favoriteStopKeys: Set<String> {
        didSet { save() }
    }

    private let routeKey = "favoriteRouteTags"
    private let stopKey = "favoriteStopKeys"

    private init() {
        let routes = UserDefaults.standard.stringArray(forKey: routeKey) ?? []
        favoriteRouteTags = Set(routes)
        let stops = UserDefaults.standard.stringArray(forKey: stopKey) ?? []
        favoriteStopKeys = Set(stops)
    }

    func isRouteFavorite(_ routeTag: String) -> Bool {
        favoriteRouteTags.contains(routeTag)
    }

    func toggleRoute(_ routeTag: String) {
        if favoriteRouteTags.contains(routeTag) {
            favoriteRouteTags.remove(routeTag)
        } else {
            favoriteRouteTags.insert(routeTag)
        }
    }

    func stopKey(routeTag: String, stopTag: String) -> String {
        "\(routeTag):\(stopTag)"
    }

    func isStopFavorite(routeTag: String, stopTag: String) -> Bool {
        favoriteStopKeys.contains(self.stopKey(routeTag: routeTag, stopTag: stopTag))
    }

    func toggleStop(routeTag: String, stopTag: String) {
        let key = self.stopKey(routeTag: routeTag, stopTag: stopTag)
        if favoriteStopKeys.contains(key) {
            favoriteStopKeys.remove(key)
        } else {
            favoriteStopKeys.insert(key)
        }
    }

    private func save() {
        UserDefaults.standard.set(Array(favoriteRouteTags), forKey: routeKey)
        UserDefaults.standard.set(Array(favoriteStopKeys), forKey: stopKey)
    }
}
