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
            serviceAdvisoriesSection
            directionsSection
            stopPickerSection
            predictionsSection
            miniMapSection
        }
        .navigationTitle(streetcarRoute.displayName)
        .refreshable { await viewModel.refresh() }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    FavoritesService.shared.toggleRoute(streetcarRoute.routeTag)
                } label: {
                    Image(systemName: FavoritesService.shared.isRouteFavorite(streetcarRoute.routeTag) ? "star.fill" : "star")
                }
                .accessibilityLabel("Toggle favorite")

                Button {
                    viewModel.arrivalAlertService.isEnabled.toggle()
                } label: {
                    Image(systemName: viewModel.arrivalAlertService.isEnabled ? "bell.fill" : "bell")
                }
                .accessibilityLabel("Toggle arrival alert")
            }
        }
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
    private var stopPickerSection: some View {
        let stops = viewModel.stopsForSelectedDirection
        if !stops.isEmpty {
            Section("Stops") {
                StopPickerView(stops: stops, selectedStopTag: $viewModel.selectedStopTag)
                    .onChange(of: viewModel.selectedStopTag) {
                        Task { await viewModel.fetchPredictions() }
                    }
            }
        }
    }

    @ViewBuilder
    private var serviceAdvisoriesSection: some View {
        if !viewModel.serviceMessages.isEmpty {
            Section("Service Advisories") {
                ForEach(viewModel.serviceMessages) { message in
                    ServiceAlertView(message: message)
                }
            }
        }
    }

    @ViewBuilder
    private var predictionsSection: some View {
        let predictions = Array(viewModel.activePredictions.prefix(5))
        Section(viewModel.selectedStop.map { "Arrivals at \($0.title)" } ?? "Next Arrivals") {
            if predictions.isEmpty {
                Text("No predictions available")
                    .foregroundStyle(.secondary)
                    .font(TTCFonts.caption)
            } else {
                ForEach(predictions) { prediction in
                    PredictionRowView(prediction: prediction) { pred in
                        viewModel.trackPrediction(pred)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var miniMapSection: some View {
        if !viewModel.filteredVehicles.isEmpty || viewModel.routeConfig != nil {
            Section("Vehicles") {
                Map {
                    if let config = viewModel.routeConfig {
                        ForEach(Array(config.paths.enumerated()), id: \.offset) { _, path in
                            MapPolyline(coordinates: path.map {
                                CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon)
                            })
                            .stroke(Color(hex: config.color), lineWidth: 3)
                        }
                    }
                    ForEach(viewModel.stopsForSelectedDirection) { stop in
                        Annotation("", coordinate: CLLocationCoordinate2D(
                            latitude: stop.lat, longitude: stop.lon
                        )) {
                            Circle()
                                .fill(viewModel.selectedStopTag == stop.tag ? Color.ttcRed : .white)
                                .stroke(Color.ttcRed, lineWidth: 2)
                                .frame(width: 10, height: 10)
                                .onTapGesture {
                                    viewModel.selectedStopTag = stop.tag
                                    Task { await viewModel.fetchPredictions() }
                                }
                        }
                    }
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
