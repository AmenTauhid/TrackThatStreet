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
        }
        .tint(.ttcRed)
    }
}

#Preview {
    ContentView()
}
