import SwiftUI
import MapKit

struct RouteDetailView: View {
    let streetcarRoute: StreetcarRoute
    @State private var viewModel: RouteDetailViewModel

    init(streetcarRoute: StreetcarRoute) {
        self.streetcarRoute = streetcarRoute
        self._viewModel = State(initialValue: RouteDetailViewModel(streetcarRoute: streetcarRoute))
    }

    var body: some View {
        List {
            statusSection
            alertsSection
            directionsSection
            predictionsSection
            miniMapSection
        }
        .navigationTitle(streetcarRoute.displayName)
        .refreshable { await viewModel.refresh() }
        .overlay {
            if viewModel.isLoading && viewModel.vehicles.isEmpty {
                ProgressView("Loading...")
            }
        }
        .onAppear { viewModel.startMonitoring() }
        .onDisappear { viewModel.stopMonitoring() }
    }

    @ViewBuilder
    private var statusSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Status")
                            .font(TTCFonts.routeName)
                        StatusBadgeView(status: viewModel.status)
                    }
                    Text("\(viewModel.vehicles.count) vehicles active")
                        .font(TTCFonts.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var alertsSection: some View {
        if !viewModel.bunchingAlerts.isEmpty || !viewModel.gapAlerts.isEmpty {
            Section("Alerts") {
                AlertBannerView(
                    bunchingAlerts: viewModel.bunchingAlerts,
                    gapAlerts: viewModel.gapAlerts
                )
            }
        }
    }

    @ViewBuilder
    private var directionsSection: some View {
        if !viewModel.uiDirections.isEmpty {
            Section {
                DirectionPickerView(
                    directions: viewModel.uiDirections,
                    selectedTag: $viewModel.selectedDirectionTag
                )
            }
        }
    }

    @ViewBuilder
    private var predictionsSection: some View {
        let predictions = Array(viewModel.activePredictions.prefix(5))
        Section("Next Arrivals") {
            if predictions.isEmpty {
                Text("No predictions available")
                    .foregroundStyle(.secondary)
                    .font(TTCFonts.caption)
            } else {
                ForEach(predictions) { prediction in
                    PredictionRowView(prediction: prediction)
                }
            }
        }
    }

    @ViewBuilder
    private var miniMapSection: some View {
        if !viewModel.filteredVehicles.isEmpty {
            Section("Vehicles") {
                Map {
                    ForEach(viewModel.filteredVehicles) { vehicle in
                        Annotation(vehicle.id, coordinate: CLLocationCoordinate2D(
                            latitude: vehicle.lat, longitude: vehicle.lon
                        )) {
                            VehicleAnnotationView(vehicle: vehicle, routeTag: streetcarRoute.routeTag)
                        }
                    }
                }
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }
        }
    }
}
