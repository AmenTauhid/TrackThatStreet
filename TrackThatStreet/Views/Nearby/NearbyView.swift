import SwiftUI
import MapKit

struct NearbyView: View {
    @State private var viewModel = NearbyViewModel()
    @State private var locationService = LocationService()

    var body: some View {
        NavigationStack {
            Group {
                switch locationService.authorizationStatus {
                case .notDetermined:
                    permissionPrompt
                case .denied, .restricted:
                    deniedView
                default:
                    nearbyContent
                }
            }
            .navigationTitle("Near Me")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var permissionPrompt: some View {
        ContentUnavailableView {
            Label("Location Access", systemImage: "location.fill")
        } description: {
            Text("Allow location access to find nearby streetcar stops.")
        } actions: {
            Button("Enable Location") {
                locationService.requestPermission()
            }
            .buttonStyle(.borderedProminent)
            .tint(.ttcRed)
        }
    }

    private var deniedView: some View {
        ContentUnavailableView {
            Label("Location Denied", systemImage: "location.slash.fill")
        } description: {
            Text("Location access is denied. Enable it in Settings to find nearby stops.")
        } actions: {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.ttcRed)
        }
    }

    private var nearbyContent: some View {
        VStack(spacing: 0) {
            nearbyMap
                .frame(height: 250)

            if viewModel.isLoading {
                ProgressView("Finding nearby stops...")
                    .padding()
            } else {
                List {
                    if let selected = viewModel.selectedStop {
                        Section("Predictions for \(selected.stop.title)") {
                            let predictions = viewModel.predictionGroups.flatMap { $0.predictions }
                                .sorted { $0.seconds < $1.seconds }
                                .prefix(5)
                            if predictions.isEmpty {
                                Text("No predictions available")
                                    .foregroundStyle(.secondary)
                                    .font(TTCFonts.caption)
                            } else {
                                ForEach(Array(predictions)) { prediction in
                                    PredictionRowView(prediction: prediction)
                                }
                            }
                        }
                    }

                    Section("Nearby Stops") {
                        ForEach(viewModel.nearbyStops) { nearby in
                            Button {
                                Task { await viewModel.selectStop(nearby) }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(nearby.stop.title)
                                            .font(TTCFonts.routeName)
                                            .foregroundStyle(.primary)
                                        Text(nearby.routeTitle)
                                            .font(TTCFonts.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(Int(nearby.distanceMeters))m")
                                            .font(TTCFonts.caption)
                                        Text("\(Int(nearby.walkingMinutes.rounded(.up))) min walk")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .listRowBackground(
                                viewModel.selectedStop?.id == nearby.id ? Color.ttcRed.opacity(0.1) : nil
                            )
                        }
                    }
                }
            }
        }
        .onAppear {
            locationService.startUpdating()
            Task { await viewModel.loadRouteConfigs() }
        }
        .onDisappear {
            locationService.stopUpdating()
        }
        .onChange(of: locationService.currentLocation) {
            if let location = locationService.currentLocation {
                viewModel.updateNearbyStops(location: location)
            }
        }
    }

    private var nearbyMap: some View {
        Map {
            UserAnnotation()
            ForEach(viewModel.nearbyStops) { nearby in
                Annotation(nearby.stop.title, coordinate: CLLocationCoordinate2D(
                    latitude: nearby.stop.lat, longitude: nearby.stop.lon
                )) {
                    Circle()
                        .fill(viewModel.selectedStop?.id == nearby.id ? Color.ttcRed : .white)
                        .stroke(Color.ttcRed, lineWidth: 2)
                        .frame(width: 12, height: 12)
                        .onTapGesture {
                            Task { await viewModel.selectStop(nearby) }
                        }
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
    }
}
