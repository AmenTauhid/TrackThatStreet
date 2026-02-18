import SwiftUI

struct RouteListView: View {
    @State private var viewModel = RouteListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.vehicleCounts.isEmpty {
                    ProgressView("Loading streetcars...")
                } else if let error = viewModel.errorMessage, viewModel.vehicleCounts.isEmpty {
                    LoadingStateView(message: error) {
                        Task { await viewModel.fetchAllRoutes() }
                    }
                } else {
                    List(StreetcarRoute.allCases) { route in
                        NavigationLink(value: route) {
                            RouteRowView(
                                route: route,
                                status: viewModel.routeStatuses[route.routeTag],
                                vehicleCount: viewModel.vehicleCounts[route.routeTag],
                                averageWait: viewModel.averageWaits[route.routeTag]
                            )
                        }
                    }
                    .refreshable {
                        await viewModel.fetchAllRoutes()
                    }
                }
            }
            .navigationTitle("Streetcars")
            .navigationDestination(for: StreetcarRoute.self) { route in
                RouteDetailView(streetcarRoute: route)
            }
        }
        .onAppear { viewModel.startMonitoring() }
        .onDisappear { viewModel.stopMonitoring() }
    }
}
