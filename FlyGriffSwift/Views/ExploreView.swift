import SwiftUI

private enum MapKeys {
    static let fromLat = ["from_lat", "from_latitude", "from_airport_latitude", "from_airport_lat", "origin_lat", "origin_latitude", "departure_lat", "departure_latitude"]
    static let fromLon = ["from_lon", "from_lng", "from_long", "from_longitude", "from_airport_longitude", "from_airport_lon", "origin_lon", "origin_lng", "origin_longitude", "departure_lon", "departure_lng", "departure_longitude"]
    static let toLat = ["to_lat", "to_latitude", "to_airport_latitude", "to_airport_lat", "dest_lat", "destination_lat", "arrival_lat", "arrival_latitude"]
    static let toLon = ["to_lon", "to_lng", "to_long", "to_longitude", "to_airport_longitude", "to_airport_lon", "dest_lon", "dest_lng", "dest_longitude", "destination_lon", "destination_lng", "destination_longitude", "arrival_lon", "arrival_lng", "arrival_longitude"]
}

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("This is a scrollview of flights since James met Kalani.")
                }

                Section("Flight map") {
                    FlightMapView(flights: viewModel.flights)
                        .frame(height: 220)
                    HStack(spacing: 12) {
                        Label("Departure", systemImage: "circle.fill")
                            .foregroundStyle(.green)
                        Label("Arrival", systemImage: "circle.fill")
                            .foregroundStyle(.red)
                    }
                    .font(.caption)
                }

                if !viewModel.errorMessage.isEmpty {
                    Section {
                        Text("Error: \(viewModel.errorMessage)")
                            .foregroundStyle(.red)
                    }
                }

                Section("Flights") {
                    ForEach(viewModel.flights) { flight in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(flight.stringValue(for: ["from_city"]) ?? "") \(flight.stringValue(for: ["from_airport_name"]) ?? "") to \(flight.stringValue(for: ["to_city"]) ?? "") \(flight.stringValue(for: ["to_airport_name"]) ?? "")")
                                .font(.headline)
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Aircraft: \(flight.stringValue(for: ["aircraft"]) ?? "")")
                                    Text("Class: \(flight.stringValue(for: ["cabin"]) ?? "")")
                                    Text("Seat: \(flight.stringValue(for: ["seat"]) ?? "")")
                                }
                                Spacer()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Distance: \(flight.stringValue(for: ["distance_mi"]) ?? "") miles")
                                    Text("Duration: \(flight.stringValue(for: ["duration_hhmm"]) ?? "")")
                                    Text("Purpose: \(flight.stringValue(for: ["trip_type"]) ?? "")")
                                }
                            }
                            .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Loading flights...")
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationTitle("Explore")
            .task {
                await viewModel.loadFlights()
            }
            .refreshable {
                await viewModel.loadFlights()
            }
        }
    }
}

private struct FlightMapView: View {
    let flights: [Flight]
    private let mapURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/World_map_-_low_resolution.svg/1024px-World_map_-_low_resolution.svg.png")

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let segments = routeSegments(in: size)
            let points = plottedPoints(in: size)

            ZStack {
                AsyncImage(url: mapURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(.gray.opacity(0.2))
                }

                Canvas { context, _ in
                    for segment in segments {
                        var path = Path()
                        path.move(to: segment.start)
                        path.addLine(to: segment.end)
                        context.stroke(path, with: .color(.blue.opacity(0.6)), lineWidth: 2)
                    }

                    for point in points {
                        let rect = CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)
                        context.fill(Path(ellipseIn: rect), with: .color(point.type == .from ? .green : .red))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func plottedPoints(in size: CGSize) -> [(x: CGFloat, y: CGFloat, type: PointType)] {
        var points: [(x: CGFloat, y: CGFloat, type: PointType)] = []
        for flight in flights {
            if let fromLat = flight.doubleValue(for: MapKeys.fromLat),
               let fromLon = flight.doubleValue(for: MapKeys.fromLon) {
                let projected = project(lat: fromLat, lon: fromLon, width: size.width, height: size.height)
                points.append((projected.x, projected.y, .from))
            }
            if let toLat = flight.doubleValue(for: MapKeys.toLat),
               let toLon = flight.doubleValue(for: MapKeys.toLon) {
                let projected = project(lat: toLat, lon: toLon, width: size.width, height: size.height)
                points.append((projected.x, projected.y, .to))
            }
        }
        return points
    }

    private func routeSegments(in size: CGSize) -> [(start: CGPoint, end: CGPoint)] {
        var segments: [(start: CGPoint, end: CGPoint)] = []
        for flight in flights {
            guard let fromLat = flight.doubleValue(for: MapKeys.fromLat),
                  let fromLon = flight.doubleValue(for: MapKeys.fromLon),
                  let toLat = flight.doubleValue(for: MapKeys.toLat),
                  let toLon = flight.doubleValue(for: MapKeys.toLon) else {
                continue
            }

            let arcPoints = greatCirclePoints(lat1: fromLat, lon1: fromLon, lat2: toLat, lon2: toLon)
            for index in 0..<(arcPoints.count - 1) {
                let a = project(lat: arcPoints[index].lat, lon: arcPoints[index].lon, width: size.width, height: size.height)
                let b = project(lat: arcPoints[index + 1].lat, lon: arcPoints[index + 1].lon, width: size.width, height: size.height)
                if abs(b.x - a.x) > size.width / 2 { continue }
                segments.append((CGPoint(x: a.x, y: a.y), CGPoint(x: b.x, y: b.y)))
            }
        }
        return segments
    }

    private func project(lat: Double, lon: Double, width: CGFloat, height: CGFloat) -> (x: CGFloat, y: CGFloat) {
        let clampedLat = max(-85.0, min(85.0, lat))
        let clampedLon = max(-180.0, min(180.0, lon))
        let x = ((clampedLon + 180.0) / 360.0) * width
        let y = ((90.0 - clampedLat) / 180.0) * height
        return (x, y)
    }

    private func greatCirclePoints(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> [(lat: Double, lon: Double)] {
        let phi1 = lat1.radians
        let lambda1 = lon1.radians
        let phi2 = lat2.radians
        let lambda2 = lon2.radians

        let x1 = cos(phi1) * cos(lambda1)
        let y1 = cos(phi1) * sin(lambda1)
        let z1 = sin(phi1)

        let x2 = cos(phi2) * cos(lambda2)
        let y2 = cos(phi2) * sin(lambda2)
        let z2 = sin(phi2)

        let dot = max(-1.0, min(1.0, x1 * x2 + y1 * y2 + z1 * z2))
        let omega = acos(dot)
        if omega < 0.000001 {
            return [(lat1, lon1), (lat2, lon2)]
        }

        let steps = max(12, min(64, Int(round((omega / .pi) * 64))))
        let sinOmega = sin(omega)
        var points: [(lat: Double, lon: Double)] = []

        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let scaleA = sin((1.0 - t) * omega) / sinOmega
            let scaleB = sin(t * omega) / sinOmega
            let x = scaleA * x1 + scaleB * x2
            let y = scaleA * y1 + scaleB * y2
            let z = scaleA * z1 + scaleB * z2
            let lat = atan2(z, sqrt(x * x + y * y)).degrees
            let lon = atan2(y, x).degrees
            points.append((lat, lon))
        }

        return points
    }

    private enum PointType {
        case from
        case to
    }
}

private extension Double {
    var radians: Double { self * .pi / 180.0 }
    var degrees: Double { self * 180.0 / .pi }
}

#Preview {
    ExploreView()
}