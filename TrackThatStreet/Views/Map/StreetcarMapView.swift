import SwiftUI
import MapKit

struct StreetcarMapView: View {
    @State private var viewModel = MapViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $viewModel.cameraPosition) {
                    ForEach(viewModel.filteredVehicles) { vehicle in
                        Annotation(vehicle.id, coordinate: CLLocationCoordinate2D(
                            latitude: vehicle.lat, longitude: vehicle.lon
                        )) {
                            VehicleAnnotationView(
                                vehicle: vehicle,
                                routeTag: vehicle.routeTag,
                                isSelected: viewModel.selectedVehicle?.id == vehicle.id
                            )
                            .onTapGesture { viewModel.selectVehicle(vehicle) }
                        }
                    }
                }
                .mapStyle(.standard(pointsOfInterest: .excludingAll))
                .onTapGesture { viewModel.dismissVehicle() }

                routeFilterBar

                if let vehicle = viewModel.selectedVehicle {
                    VStack {
                        Spacer()
                        VehiclePopupView(vehicle: vehicle) {
                            viewModel.dismissVehicle()
                        }
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.snappy, value: viewModel.selectedVehicle?.id)
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if viewModel.isLoading && viewModel.vehicles.isEmpty {
                    ProgressView("Loading vehicles...")
                }
            }
        }
        .onAppear { viewModel.startMonitoring() }
        .onDisappear { viewModel.stopMonitoring() }
    }

    private var routeFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterButton(label: "All", isSelected: viewModel.selectedRouteTag == nil) {
                    viewModel.selectRoute(nil)
                }
                ForEach(StreetcarRoute.allCases) { route in
                    FilterButton(
                        label: route.routeTag,
                        isSelected: viewModel.selectedRouteTag == route.routeTag
                    ) {
                        viewModel.selectRoute(route.routeTag)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }
}

private struct FilterButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(TTCFonts.badge)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.ttcRed : Color.secondary.opacity(0.2), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .accessibilityLabel("Filter route \(label)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
