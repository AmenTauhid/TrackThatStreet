import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Routes", systemImage: "tram.fill") {
                RouteListView()
            }
            Tab("Map", systemImage: "map") {
                StreetcarMapView()
            }
            Tab("Near Me", systemImage: "location.fill") {
                NearbyView()
            }
        }
        .tint(.ttcRed)
    }
}

#Preview {
    ContentView()
}
